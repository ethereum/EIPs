// Based on PQClean https://github.com/PQClean/PQClean/tree/master/crypto_sign/falcon-512/clean
/*
 * Floating-point operations.
 *
 * ==========================(LICENSE BEGIN)============================
 *
 * Copyright (c) 2017-2019  Falcon Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ===========================(LICENSE END)=============================
 *
 * @author   Thomas Pornin <thomas.pornin@nccgroup.com>
 */

/* ====================================================================== */
/*
 * Custom floating-point implementation with integer arithmetics. We
 * use IEEE-754 "binary64" format, with some simplifications:
 *
 *   - Top bit is s = 1 for negative, 0 for positive.
 *
 *   - Exponent e uses the next 11 bits (bits 52 to 62, inclusive).
 *
 *   - Mantissa m uses the 52 low bits.
 *
 * Encoded value is, in general: (-1)^s * 2^(e-1023) * (1 + m*2^(-52))
 * i.e. the mantissa really is a 53-bit number (less than 2.0, but not
 * less than 1.0), but the top bit (equal to 1 by definition) is omitted
 * in the encoding.
 *
 * In IEEE-754, there are some special values:
 *
 *   - If e = 2047, then the value is either an infinite (m = 0) or
 *     a NaN (m != 0).
 *
 *   - If e = 0, then the value is either a zero (m = 0) or a subnormal,
 *     aka "denormalized number" (m != 0).
 *
 * Of these, we only need the zeros. The caller is responsible for not
 * providing operands that would lead to infinites, NaNs or subnormals.
 * If inputs are such that values go out of range, then indeterminate
 * values are returned (it would still be deterministic, but no specific
 * value may be relied upon).
 *
 * At the C level, the three parts are stored in a 64-bit unsigned
 * word.
 *
 * One may note that a property of the IEEE-754 format is that order
 * is preserved for positive values: if two positive floating-point
 * values x and y are such that x < y, then their respective encodings
 * as _signed_ 64-bit integers i64(x) and i64(y) will be such that
 * i64(x) < i64(y). For negative values, order is reversed: if x < 0,
 * y < 0, and x < y, then ia64(x) > ia64(y).
 *
 * IMPORTANT ASSUMPTIONS:
 * ======================
 *
 * For proper computations, and constant-time behaviour, we assume the
 * following:
 *
 *   - 32x32->64 multiplication (unsigned) has an execution time that
 *     is independent of its operands. This is true of most modern
 *     x86 and ARM cores. Notable exceptions are the ARM Cortex M0, M0+
 *     and M3 (in the M0 and M0+, this is done in software, so it depends
 *     on that routine), and the PowerPC cores from the G3/G4 lines.
 *     For more info, see: https://www.bearssl.org/ctmul.html
 *
 *   - Left-shifts and right-shifts of 32-bit values have an execution
 *     time which does not depend on the shifted value nor on the
 *     shift count. An historical exception is the Pentium IV, but most
 *     modern CPU have barrel shifters. Some small microcontrollers
 *     might have varying-time shifts (not the ARM Cortex M*, though).
 *
 *   - Right-shift of a signed negative value performs a sign extension.
 *     As per the C standard, this operation returns an
 *     implementation-defined result (this is NOT an "undefined
 *     behaviour"). On most/all systems, an arithmetic shift is
 *     performed, because this is what makes most sense.
 */

/*
 * Normally we should declare the 'fpr' type to be a struct or union
 * around the internal 64-bit value; however, we want to use the
 * direct 64-bit integer type to enable a lighter call convention on
 * ARM platforms. This means that direct (invalid) use of operators
 * such as '*' or '+' will not be caught by the compiler. We rely on
 * the "normal" (non-emulated) code to detect such instances.
 */
typedef uint64_t fpr;

/*
 * For computations, we split values into an integral mantissa in the
 * 2^54..2^55 range, and an (adjusted) exponent. The lowest bit is
 * "sticky" (it is set to 1 if any of the bits below it is 1); when
 * re-encoding, the low two bits are dropped, but may induce an
 * increment in the value for proper rounding.
 */

/*
 * Right-shift a 64-bit unsigned value by a possibly secret shift count.
 * We assumed that the underlying architecture had a barrel shifter for
 * 32-bit shifts, but for 64-bit shifts on a 32-bit system, this will
 * typically invoke a software routine that is not necessarily
 * constant-time; hence the function below.
 *
 * Shift count n MUST be in the 0..63 range.
 */
static inline uint64_t
fpr_ursh(uint64_t x, int n) {
    x ^= (x ^ (x >> 32)) & -(uint64_t)(n >> 5);
    return x >> (n & 31);
}

/*
 * Right-shift a 64-bit signed value by a possibly secret shift count
 * (see fpr_ursh() for the rationale).
 *
 * Shift count n MUST be in the 0..63 range.
 */
static inline int64_t
fpr_irsh(int64_t x, int n) {
    x ^= (x ^ (x >> 32)) & -(int64_t)(n >> 5);
    return x >> (n & 31);
}

/*
 * Left-shift a 64-bit unsigned value by a possibly secret shift count
 * (see fpr_ursh() for the rationale).
 *
 * Shift count n MUST be in the 0..63 range.
 */
static inline uint64_t
fpr_ulsh(uint64_t x, int n) {
    x ^= (x ^ (x << 32)) & -(uint64_t)(n >> 5);
    return x << (n & 31);
}

/*
 * Expectations:
 *   s = 0 or 1
 *   exponent e is "arbitrary" and unbiased
 *   2^54 <= m < 2^55
 * Numerical value is (-1)^2 * m * 2^e
 *
 * Exponents which are too low lead to value zero. If the exponent is
 * too large, the returned value is indeterminate.
 *
 * If m = 0, then a zero is returned (using the provided sign).
 * If e < -1076, then a zero is returned (regardless of the value of m).
 * If e >= -1076 and e != 0, m must be within the expected range
 * (2^54 to 2^55-1).
 */
static inline fpr
FPR(int s, int e, uint64_t m) {
    fpr x;
    uint32_t t;
    unsigned f;

    /*
     * If e >= -1076, then the value is "normal"; otherwise, it
     * should be a subnormal, which we clamp down to zero.
     */
    e += 1076;
    t = (uint32_t)e >> 31;
    m &= (uint64_t)t - 1;

    /*
     * If m = 0 then we want a zero; make e = 0 too, but conserve
     * the sign.
     */
    t = (uint32_t)(m >> 54);
    e &= -(int)t;

    /*
     * The 52 mantissa bits come from m. Value m has its top bit set
     * (unless it is a zero); we leave it "as is": the top bit will
     * increment the exponent by 1, except when m = 0, which is
     * exactly what we want.
     */
    x = (((uint64_t)s << 63) | (m >> 2)) + ((uint64_t)(uint32_t)e << 52);

    /*
     * Rounding: if the low three bits of m are 011, 110 or 111,
     * then the value should be incremented to get the next
     * representable value. This implements the usual
     * round-to-nearest rule (with preference to even values in case
     * of a tie). Note that the increment may make a carry spill
     * into the exponent field, which is again exactly what we want
     * in that case.
     */
    f = (unsigned)m & 7U;
    x += (0xC8U >> f) & 1;
    return x;
}

#define fpr_scaled   PQCLEAN_FALCON512_CLEAN_fpr_scaled
fpr fpr_scaled(int64_t i, int sc);

static inline fpr
fpr_of(int64_t i) {
    return fpr_scaled(i, 0);
}

static const fpr fpr_q = 4667981563525332992;
static const fpr fpr_inverse_of_q = 4545632735260551042;
static const fpr fpr_inv_2sqrsigma0 = 4594603506513722306;
static const fpr fpr_inv_sigma[] = {
    0,  /* unused */
    4574611497772390042,
    4574501679055810265,
    4574396282908341804,
    4574245855758572086,
    4574103865040221165,
    4573969550563515544,
    4573842244705920822,
    4573721358406441454,
    4573606369665796042,
    4573496814039276259
};
static const fpr fpr_sigma_min[] = {
    0,  /* unused */
    4607707126469777035,
    4607777455861499430,
    4607846828256951418,
    4607949175006100261,
    4608049571757433526,
    4608148125896792003,
    4608244935301382692,
    4608340089478362016,
    4608433670533905013,
    4608525754002622308
};
static const fpr fpr_log2 = 4604418534313441775;
static const fpr fpr_inv_log2 = 4609176140021203710;
static const fpr fpr_bnorm_max = 4670353323383631276;
static const fpr fpr_zero = 0;
static const fpr fpr_one = 4607182418800017408;
static const fpr fpr_two = 4611686018427387904;
static const fpr fpr_onehalf = 4602678819172646912;
static const fpr fpr_invsqrt2 = 4604544271217802189;
static const fpr fpr_invsqrt8 = 4600040671590431693;
static const fpr fpr_ptwo31 = 4746794007248502784;
static const fpr fpr_ptwo31m1 = 4746794007244308480;
static const fpr fpr_mtwo31m1 = 13970166044099084288U;
static const fpr fpr_ptwo63m1 = 4890909195324358656;
static const fpr fpr_mtwo63m1 = 14114281232179134464U;
static const fpr fpr_ptwo63 = 4890909195324358656;

static inline int64_t
fpr_rint(fpr x) {
    uint64_t m, d;
    int e;
    uint32_t s, dd, f;

    /*
     * We assume that the value fits in -(2^63-1)..+(2^63-1). We can
     * thus extract the mantissa as a 63-bit integer, then right-shift
     * it as needed.
     */
    m = ((x << 10) | ((uint64_t)1 << 62)) & (((uint64_t)1 << 63) - 1);
    e = 1085 - ((int)(x >> 52) & 0x7FF);

    /*
     * If a shift of more than 63 bits is needed, then simply set m
     * to zero. This also covers the case of an input operand equal
     * to zero.
     */
    m &= -(uint64_t)((uint32_t)(e - 64) >> 31);
    e &= 63;

    /*
     * Right-shift m as needed. Shift count is e. Proper rounding
     * mandates that:
     *   - If the highest dropped bit is zero, then round low.
     *   - If the highest dropped bit is one, and at least one of the
     *     other dropped bits is one, then round up.
     *   - If the highest dropped bit is one, and all other dropped
     *     bits are zero, then round up if the lowest kept bit is 1,
     *     or low otherwise (i.e. ties are broken by "rounding to even").
     *
     * We thus first extract a word consisting of all the dropped bit
     * AND the lowest kept bit; then we shrink it down to three bits,
     * the lowest being "sticky".
     */
    d = fpr_ulsh(m, 63 - e);
    dd = (uint32_t)d | ((uint32_t)(d >> 32) & 0x1FFFFFFF);
    f = (uint32_t)(d >> 61) | ((dd | -dd) >> 31);
    m = fpr_ursh(m, e) + (uint64_t)((0xC8U >> f) & 1U);

    /*
     * Apply the sign bit.
     */
    s = (uint32_t)(x >> 63);
    return ((int64_t)m ^ -(int64_t)s) + (int64_t)s;
}

static inline int64_t
fpr_floor(fpr x) {
    uint64_t t;
    int64_t xi;
    int e, cc;

    /*
     * We extract the integer as a _signed_ 64-bit integer with
     * a scaling factor. Since we assume that the value fits
     * in the -(2^63-1)..+(2^63-1) range, we can left-shift the
     * absolute value to make it in the 2^62..2^63-1 range: we
     * will only need a right-shift afterwards.
     */
    e = (int)(x >> 52) & 0x7FF;
    t = x >> 63;
    xi = (int64_t)(((x << 10) | ((uint64_t)1 << 62))
                   & (((uint64_t)1 << 63) - 1));
    xi = (xi ^ -(int64_t)t) + (int64_t)t;
    cc = 1085 - e;

    /*
     * We perform an arithmetic right-shift on the value. This
     * applies floor() semantics on both positive and negative values
     * (rounding toward minus infinity).
     */
    xi = fpr_irsh(xi, cc & 63);

    /*
     * If the true shift count was 64 or more, then we should instead
     * replace xi with 0 (if nonnegative) or -1 (if negative). Edge
     * case: -0 will be floored to -1, not 0 (whether this is correct
     * is debatable; in any case, the other functions normalize zero
     * to +0).
     *
     * For an input of zero, the non-shifted xi was incorrect (we used
     * a top implicit bit of value 1, not 0), but this does not matter
     * since this operation will clamp it down.
     */
    xi ^= (xi ^ -(int64_t)t) & -(int64_t)((uint32_t)(63 - cc) >> 31);
    return xi;
}

static inline int64_t
fpr_trunc(fpr x) {
    uint64_t t, xu;
    int e, cc;

    /*
     * Extract the absolute value. Since we assume that the value
     * fits in the -(2^63-1)..+(2^63-1) range, we can left-shift
     * the absolute value into the 2^62..2^63-1 range, and then
     * do a right shift afterwards.
     */
    e = (int)(x >> 52) & 0x7FF;
    xu = ((x << 10) | ((uint64_t)1 << 62)) & (((uint64_t)1 << 63) - 1);
    cc = 1085 - e;
    xu = fpr_ursh(xu, cc & 63);

    /*
     * If the exponent is too low (cc > 63), then the shift was wrong
     * and we must clamp the value to 0. This also covers the case
     * of an input equal to zero.
     */
    xu &= -(uint64_t)((uint32_t)(cc - 64) >> 31);

    /*
     * Apply back the sign, if the source value is negative.
     */
    t = x >> 63;
    xu = (xu ^ -t) + t;
    return *(int64_t *)&xu;
}

#define fpr_add   PQCLEAN_FALCON512_CLEAN_fpr_add
fpr fpr_add(fpr x, fpr y);

static inline fpr
fpr_sub(fpr x, fpr y) {
    y ^= (uint64_t)1 << 63;
    return fpr_add(x, y);
}

static inline fpr
fpr_neg(fpr x) {
    x ^= (uint64_t)1 << 63;
    return x;
}

static inline fpr
fpr_half(fpr x) {
    /*
     * To divide a value by 2, we just have to subtract 1 from its
     * exponent, but we have to take care of zero.
     */
    uint32_t t;

    x -= (uint64_t)1 << 52;
    t = (((uint32_t)(x >> 52) & 0x7FF) + 1) >> 11;
    x &= (uint64_t)t - 1;
    return x;
}

static inline fpr
fpr_double(fpr x) {
    /*
     * To double a value, we just increment by one the exponent. We
     * don't care about infinites or NaNs; however, 0 is a
     * special case.
     */
    x += (uint64_t)((((unsigned)(x >> 52) & 0x7FFU) + 0x7FFU) >> 11) << 52;
    return x;
}

#define fpr_mul   PQCLEAN_FALCON512_CLEAN_fpr_mul
fpr fpr_mul(fpr x, fpr y);

static inline fpr
fpr_sqr(fpr x) {
    return fpr_mul(x, x);
}

#define fpr_div   PQCLEAN_FALCON512_CLEAN_fpr_div
fpr fpr_div(fpr x, fpr y);

static inline fpr
fpr_inv(fpr x) {
    return fpr_div(4607182418800017408u, x);
}

#define fpr_sqrt   PQCLEAN_FALCON512_CLEAN_fpr_sqrt
fpr fpr_sqrt(fpr x);

static inline int
fpr_lt(fpr x, fpr y) {
    /*
     * If both x and y are positive, then a signed comparison yields
     * the proper result:
     *   - For positive values, the order is preserved.
     *   - The sign bit is at the same place as in integers, so
     *     sign is preserved.
     * Moreover, we can compute [x < y] as sgn(x-y) and the computation
     * of x-y will not overflow.
     *
     * If the signs differ, then sgn(x) gives the proper result.
     *
     * If both x and y are negative, then the order is reversed.
     * Hence [x < y] = sgn(y-x). We must compute this separately from
     * sgn(x-y); simply inverting sgn(x-y) would not handle the edge
     * case x = y properly.
     */
    int cc0, cc1;
    int64_t sx;
    int64_t sy;

    sx = *(int64_t *)&x;
    sy = *(int64_t *)&y;
    sy &= ~((sx ^ sy) >> 63); /* set sy=0 if signs differ */

    cc0 = (int)((sx - sy) >> 63) & 1; /* Neither subtraction overflows when */
    cc1 = (int)((sy - sx) >> 63) & 1; /* the signs are the same. */

    return cc0 ^ ((cc0 ^ cc1) & (int)((x & y) >> 63));
}

/*
 * Compute exp(x) for x such that |x| <= ln 2. We want a precision of 50
 * bits or so.
 */
#define fpr_expm_p63   PQCLEAN_FALCON512_CLEAN_fpr_expm_p63
uint64_t fpr_expm_p63(fpr x, fpr ccs);

#define fpr_gm_tab   PQCLEAN_FALCON512_CLEAN_fpr_gm_tab
extern const fpr fpr_gm_tab[];

#define fpr_p2_tab   PQCLEAN_FALCON512_CLEAN_fpr_p2_tab
extern const fpr fpr_p2_tab[];

/* ====================================================================== */
