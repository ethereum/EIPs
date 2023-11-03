// arithmetic based on https://github.com/JuliaMath/Decimals.jl

package vm

// Decimal struct and constructors

// c * 10^q
type Decimal struct {
	c int256 // coefficient, interpreted as int256
	q int256 // exponent, interpreted as int256
}

func copyDecimal(d *Decimal, gas *uint64) *Decimal {
	return createDecimal(&d.c, &d.q, gas)
}
func createDecimal(_c, _q *int256, gas *uint64) *Decimal {
	var c, q int256
	Set(_c, &c, gas)
	Set(_q, &q, gas)
	return &Decimal{c, q}
}

// CONSTANTS
var GLOBAL_GAS uint64 // not needed, only once per node start, just as an argument into New and createDecimal

var MINUS_ONE_INT256 = new(int256).Neg(ONE_INT256)
var ZERO_INT256 = New(0, &GLOBAL_GAS)
var ONE_INT256 = New(1, &GLOBAL_GAS)
var TWO_INT256 = New(2, &GLOBAL_GAS)
var FIVE_INT256 = New(5, &GLOBAL_GAS)
var TEN_INT256 = New(10, &GLOBAL_GAS)

var MINUS_ONE_DECIMAL = createDecimal(MINUS_ONE_INT256, ZERO_INT256, &GLOBAL_GAS)
var HALF_DECIMAL = createDecimal(FIVE_INT256, MINUS_ONE_INT256, &GLOBAL_GAS)
var ZERO_DECIMAL = createDecimal(ZERO_INT256, ONE_INT256, &GLOBAL_GAS)
var ONE_DECIMAL = createDecimal(ONE_INT256, ZERO_INT256, &GLOBAL_GAS)
var TWO_DECIMAL = createDecimal(TWO_INT256, ZERO_INT256, &GLOBAL_GAS)
var TEN_DECIMAL = createDecimal(TEN_INT256, ZERO_INT256, &GLOBAL_GAS)

// OPCODE functions

// a + b
func (out *Decimal) Add(a, b *Decimal, precision *int256, gas *uint64) *Decimal {
	// ok even if out == a || out == b

	ca := add_helper(a, b, gas)
	cb := add_helper(b, a, gas)
	Add(&ca, &cb, &out.c, gas)

	q := signedMin(&a.q, &b.q, gas)
	Set(q, &out.q, gas)

	out.normalize(out, precision, false, gas)

	return out
}

// -a
func (out *Decimal) Neg(a *Decimal, gas *uint64) *Decimal {
	// ok even if out == a
	Neg(&a.c, &out.c, gas)
	Set(&a.q, &out.q, gas)
	// no need to normalize
	return out
}

// a * b
func (out *Decimal) Mul(a, b *Decimal, precision *int256, gas *uint64) *Decimal {
	// ok even if out == a || out == b
	Mul(&a.c, &b.c, &out.c, gas)
	Add(&a.q, &b.q, &out.q, gas)
	out.normalize(out, precision, false, gas)
	return out
}

// 1 / a
func (out *Decimal) Inv(a *Decimal, precision *int256, gas *uint64) *Decimal {
	// ok even if out == a

	var precision_m_aq int256
	Sub(precision, &a.q, &precision_m_aq, gas)
	if signedCmp(&precision_m_aq, ZERO_INT256, gas) == -1 {
		panic("precision_m_aq NEGATIVE")
	}

	Exp(TEN_INT256, &precision_m_aq, &precision_m_aq, gas) // save space: precision_m_aq not needed after
	signedDiv(&precision_m_aq, &a.c, &out.c, gas)
	Neg(precision, &out.q, gas)

	out.normalize(out, precision, false, gas)

	return out
}

// e^a
func (out *Decimal) Exp(_a *Decimal, precision, steps *int256, gas *uint64) *Decimal {
	a := copyDecimal(_a, gas) // in case out == _a

	// out = 1
	Set(ONE_INT256, &out.c, gas)
	Set(ZERO_INT256, &out.q, gas)

	if a.isZero(gas) {
		return out
	}

	var factorial_inv Decimal
	a_power := copyDecimal(ONE_DECIMAL, gas)
	factorial := copyDecimal(ONE_DECIMAL, gas)
	factorial_next := copyDecimal(ZERO_DECIMAL, gas)

	for i := New(1, gas); Cmp(steps, i, gas) == -1; Add(i, ONE_INT256, i, gas) { // step 0 skipped as out set to 1
		a_power.Mul(a_power, a, precision, gas)                         // a^i
		factorial_next.Add(factorial_next, ONE_DECIMAL, precision, gas) // i++
		factorial.Mul(factorial, factorial_next, precision, gas)        // i!
		factorial_inv.Inv(factorial, precision, gas)                    // 1/i!
		factorial_inv.Mul(&factorial_inv, a_power, precision, gas)      // store a^i/i! in factorial_inv as not needed anymore
		out.Add(out, &factorial_inv, precision, gas)                    // out += a^i/i!
	}

	return out
}

// 0 < _a
func (out *Decimal) Ln(_a *Decimal, precision, steps *int256, gas *uint64) *Decimal {
	a := copyDecimal(_a, gas)

	if a.isNegative(gas) {
		panic("Ln: need 0 < x")
	}

	// ln(1) = 0
	if a.isOne(gas) {
		Set(ZERO_INT256, &out.c, gas)
		Set(ONE_INT256, &out.q, gas)
		return out
	}

	// adjust x
	// divide x by 10 until x in [0,2]
	adjust := New(0, gas)
	for {
		if a.lessThan(TWO_DECIMAL, precision, gas) {
			break
		}

		// x /= 10
		Add(&a.q, MINUS_ONE_INT256, &a.q, gas)
		Add(adjust, ONE_INT256, adjust, gas)
	}

	// ln works with 1+x
	a.Add(a, MINUS_ONE_DECIMAL, precision, gas)

	// main
	out.ln(a, precision, steps, gas)

	// readjust back: ln(a*10^n) = ln(a)+n*ln(10)
	var LN10 Decimal
	LN10.ln10(precision, steps, gas)
	adjustDec := createDecimal(adjust, ZERO_INT256, gas)
	LN10.Mul(adjustDec, &LN10, precision, gas)
	out.Add(out, &LN10, precision, gas)

	return out
}

// sin(a)
func (out *Decimal) Sin(_a *Decimal, precision, steps *int256, gas *uint64) *Decimal {
	a := copyDecimal(_a, gas) // in case out == _a

	// out = a
	Set(&a.c, &out.c, gas)
	Set(&a.q, &out.q, gas)

	if a.isZero(gas) || Cmp(ONE_INT256, precision, gas) == 0 {
		return out
	}

	var a_squared, factorial_inv Decimal
	a_squared.Mul(a, a, precision, gas)
	a_power := copyDecimal(ONE_DECIMAL, gas)
	factorial := copyDecimal(ONE_DECIMAL, gas)
	factorial_next := copyDecimal(ONE_DECIMAL, gas)
	negate := true

	for i := New(1, gas); Cmp(steps, i, gas) == -1; Add(i, ONE_INT256, i, gas) { // step 0 skipped as out set to a
		a_power.Mul(a_power, &a_squared, precision, gas) // a^(2i+1)

		factorial_next.Add(factorial_next, ONE_DECIMAL, precision, gas) // i++
		factorial.Mul(factorial, factorial_next, precision, gas)        // i!*2i
		factorial_next.Add(factorial_next, ONE_DECIMAL, precision, gas) // i++
		factorial.Mul(factorial, factorial_next, precision, gas)        // (2i+1)!

		factorial_inv.Inv(factorial, precision, gas)               // 1/(2i+1)!
		factorial_inv.Mul(&factorial_inv, a_power, precision, gas) // store a^(2i+1)/(2i+1)! in factorial_inv as not needed anymore
		if negate {
			factorial_inv.Neg(&factorial_inv, gas) // (-1)^i*a^(2i+1)/(2i+1)!
		}
		negate = !negate

		out.Add(out, &factorial_inv, precision, gas) // out += (-1)^i*a^(2i+1)/(2i+1)!
	}

	return out
}

// convenience methods

func DecAdd(ac, aq, bc, bq, precision *int256, gas *uint64) (cc, cq *int256) {
	a := createDecimal(ac, aq, gas)
	b := createDecimal(bc, bq, gas)
	a.Add(a, b, precision, gas)
	cc = &a.c
	cq = &a.q
	return
}
func DecNeg(ac, aq *int256, gas *uint64) (bc, bq *int256) {
	a := createDecimal(ac, aq, gas)
	a.Neg(a, gas)
	bc = &a.c
	bq = &a.q
	return
}
func DecMul(ac, aq, bc, bq, precision *int256, gas *uint64) (cc, cq *int256) {
	a := createDecimal(ac, aq, gas)
	b := createDecimal(bc, bq, gas)
	a.Mul(a, b, precision, gas)
	cc = &a.c
	cq = &a.q
	return
}
func DecInv(ac, aq, precision *int256, gas *uint64) (bc, bq *int256) {
	a := createDecimal(ac, aq, gas)
	a.Inv(a, precision, gas)
	bc = &a.c
	bq = &a.q
	return
}
func DecExp(ac, aq, precision, steps *int256, gas *uint64) (bc, bq *int256) {
	a := createDecimal(ac, aq, gas)
	a.Exp(a, precision, steps, gas)
	bc = &a.c
	bq = &a.q
	return
}
func DecLn(ac, aq, precision, steps *int256, gas *uint64) (bc, bq *int256) {
	a := createDecimal(ac, aq, gas)
	a.Ln(a, precision, steps, gas)
	bc = &a.c
	bq = &a.q
	return
}
func DecSin(ac, aq, precision, steps *int256, gas *uint64) (bc, bq *int256) {
	a := createDecimal(ac, aq, gas)
	a.Sin(a, precision, steps, gas)
	bc = &a.c
	bq = &a.q
	return
}

// helpers

// -1 if a <  b
//
// 0 if a == b
// 1 if b <  a
func signedCmp(a, b *int256, gas *uint64) int {
	c := a.Cmp(b)

	if c == 0 { // a == b
		return 0
	}

	as := a.Sign()
	bs := b.Sign()

	if as == 0 {
		return -bs
	}
	if bs == 0 {
		return as
	}

	if c == -1 { // a < b
		if a.Sign() == b.Sign() {
			return -1 // a < b
		} else {
			return 1 // b < a
		}
	}

	// c == 1 <=> b < a
	if a.Sign() == b.Sign() {
		return 1 // b < a
	} else {
		return -1 // a < b
	}
}

// signedMin(a, b)
func signedMin(a, b *int256, gas *uint64) (c *int256) {
	if signedCmp(a, b, gas) == -1 {
		return a
	} else {
		return b
	}
}

// a == 0
func (a *Decimal) isZero(gas *uint64) bool {
	return IsZero(&a.c, gas)
}

// a should be normalized
// a == 1 ?
func (a *Decimal) isOne(gas *uint64) bool {
	return Cmp(ONE_INT256, &a.c, gas) == 0 && IsZero(&a.q, gas) // Cmp ok vs SignedCmp when comparing to zero
}

// a < 0 ?
func (a *Decimal) isNegative(gas *uint64) bool {
	return Sign(&a.c, gas) == -1
}

func (d2 *Decimal) eq(d1 *Decimal, precision *int256, gas *uint64) bool {
	d1_zero := d1.isZero(gas)
	d2_zero := d2.isZero(gas)
	if d1_zero || d2_zero {
		return d1_zero == d2_zero
	}

	d1.normalize(d1, precision, false, gas)
	d2.normalize(d2, precision, false, gas)
	return Cmp(&d2.c, &d1.c, gas) == 0 && Cmp(&d2.q, &d1.q, gas) == 0 // Cmp ok vs SignedCmp when comparing to zero
}

// a < b
func (a *Decimal) lessThan(b *Decimal, precision *int256, gas *uint64) bool {
	var diff Decimal
	diff.Add(a, diff.Neg(b, gas), precision, gas)
	return Sign(&diff.c, gas) == -1
}

func signedDiv(numerator, denominator, out *int256, gas *uint64) *int256 {
	sn := Sign(numerator, gas)
	sd := Sign(denominator, gas)
	if sn == 0 && sd == 0 { // TODO correct? xor just sd == 0 ?
		out = nil
		return nil
	}
	if sn == 0 {
		out = New(0, gas)
		return out
	}

	n := *numerator
	if sn == -1 {
		Neg(numerator, &n, gas)
	}

	d := *denominator
	if sd == -1 {
		Neg(denominator, &d, gas)
	}

	Div(&n, &d, out, gas)

	if (sn == -1) != (sd == -1) {
		Neg(out, out, gas)
	}

	return out
}

// out = {c: d1.c, q: 10^max(d1.q - d2.q, 0)}
func add_helper(d1, d2 *Decimal, gas *uint64) (out int256) {
	var exponent_diff int256
	Sub(&d1.q, &d2.q, &exponent_diff, gas)
	if Sign(&exponent_diff, gas) == -1 {
		exponent_diff = *ZERO_INT256 // shallow copy ok
	}

	Exp(TEN_INT256, &exponent_diff, &out, gas)
	Mul(&d1.c, &out, &out, gas)

	return out
}

// remove trailing zeros from coefficient
func find_num_trailing_zeros_signed_DECIMAL256(a *int256, gas *uint64) (p, ten_power *int256) {
	var b int256
	Set(a, &b, gas)
	if Sign(&b, gas) == -1 {
		Neg(&b, &b, gas)
	}

	p = New(0, gas)
	ten_power = New(10, gas)
	if Cmp(ZERO_INT256, &b, gas) != 0 { // if b != 0  // Cmp ok vs SignedCmp when comparing to zero
		for {
			var m int256
			Mod(&b, ten_power, &m, gas)
			if Cmp(ZERO_INT256, &m, gas) != 0 { // if b % 10^(p+1) != 0  // Cmp ok vs SignedCmp when comparing to zero
				break
			}
			Add(p, ONE_INT256, p, gas)
			Mul(ten_power, TEN_INT256, ten_power, gas) // 10^(p+1)
		}
	}
	Div(ten_power, TEN_INT256, ten_power, gas) // all positive

	return p, ten_power
}

// remove trailing zeros in coefficient
func (out *Decimal) normalize(a *Decimal, precision *int256, rounded bool, gas *uint64) *Decimal {
	// ok even if out == a

	p, ten_power := find_num_trailing_zeros_signed_DECIMAL256(&a.c, gas)
	signedDiv(&a.c, ten_power, &out.c, gas) // does not change polarity [in case out == a]

	a_neg := a.isNegative(gas)
	if Cmp(ZERO_INT256, &out.c, gas) != 0 || a_neg { // Cmp ok vs SignedCmp when comparing to zero
		Add(&a.q, p, &out.q, gas)
	} else {
		Set(ZERO_INT256, &out.q, gas)
	}

	if rounded {
		return out
	}

	out.round(out, precision, true, gas)
	return out
}

func (out *Decimal) round(a *Decimal, precision *int256, normal bool, gas *uint64) *Decimal {
	// ok if out == a

	var shift, ten_power int256
	Add(precision, &a.q, &shift, gas)

	if signedCmp(&shift, ZERO_INT256, gas) == 1 || signedCmp(&shift, &a.q, gas) == -1 {
		if normal {
			Set(&a.c, &out.c, gas)
			Set(&a.q, &out.q, gas)
			return out
		}
		out.normalize(a, precision, true, gas)
		return out
	}

	Neg(&shift, &shift, gas)
	Exp(TEN_INT256, &shift, &ten_power, gas)
	signedDiv(&a.c, &ten_power, &out.c, gas)
	Add(&a.q, &shift, &out.q, gas)
	if normal {
		return out
	}
	out.normalize(out, precision, true, gas)
	return out
}

// ln helpers

// https://en.wikipedia.org/wiki/Natural_logarithm#Continued_fractions
// using CF (continued fractions) for ln(1+x/y). we set y=1
// ln(1+a), a in [-1,1]
func (out *Decimal) ln(a *Decimal, precision, steps *int256, gas *uint64) *Decimal {
	var two_y_plus_x Decimal
	two_y_plus_x.Add(a, TWO_DECIMAL, precision, gas)

	step := New(1, gas)

	// recursion of continued fraction
	out2 := ln_recur(a, &two_y_plus_x, precision, steps, step, gas)
	Set(&out2.c, &out.c, gas)
	Set(&out2.q, &out.q, gas)
	out.Inv(out, precision, gas)

	// 2x / out
	var two_x Decimal
	two_x.Mul(a, TWO_DECIMAL, precision, gas)
	out.Mul(out, &two_x, precision, gas)

	return out
}

// ln10 needed for scaling
func (out *Decimal) ln10(precision, steps *int256, gas *uint64) *Decimal {
	THREE_INT256 := New(3, gas)
	THREE_DECIMAL256 := createDecimal(THREE_INT256, ZERO_INT256, gas)
	ONE_OVER_FOUR := createDecimal(New(25, gas), new(int256).Neg(TWO_INT256), gas)
	THREE_OVER_125 := createDecimal(New(24, gas), new(int256).Neg(THREE_INT256), gas)
	var a, b Decimal
	a.ln(ONE_OVER_FOUR, precision, steps, gas)
	b.ln(THREE_OVER_125, precision, steps, gas)
	a.Mul(&a, TEN_DECIMAL, precision, gas)
	b.Mul(&b, THREE_DECIMAL256, precision, gas)
	out.Add(&a, &b, precision, gas)
	return out
}

// out !== a
func ln_recur(a, two_y_plus_x *Decimal, precision, max_steps, step *int256, gas *uint64) *Decimal {
	var out Decimal

	// (2*step-1)*(2+x)
	stepDec := createDecimal(step, ZERO_INT256, gas)
	stepDec.Mul(stepDec, TWO_DECIMAL, precision, gas)
	stepDec.Add(stepDec, MINUS_ONE_DECIMAL, precision, gas)
	out.Mul(stepDec, two_y_plus_x, precision, gas)

	// end recursion?
	if Cmp(max_steps, step, gas) == 0 {
		return &out
	}

	// recursion
	Add(step, ONE_INT256, step, gas)
	r := ln_recur(a, two_y_plus_x, precision, max_steps, step, gas)
	Sub(step, ONE_INT256, step, gas)
	r.Inv(r, precision, gas)

	// (step*x)^2
	stepDec2 := createDecimal(step, ZERO_INT256, gas)
	stepDec2.Mul(stepDec2, a, precision, gas)
	stepDec2.Mul(stepDec2, stepDec2, precision, gas)

	r.Mul(stepDec2, r, precision, gas)
	r.Neg(r, gas)

	out.Add(&out, r, precision, gas)

	return &out
}
