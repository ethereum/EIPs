// Copyright 2017 The go-ethereum Authors
// This file is part of the go-ethereum library.
//
// The go-ethereum library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-ethereum library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

package vm

import (
	"fmt"
	"testing"

	"github.com/ethereum/go-ethereum/params"
	"github.com/holiman/uint256"
)

var PRECISION = uint256.NewInt(10)

func (d *Decimal) String() string {
	c := new(uint256.Int).Set(&d.c)
	q := new(uint256.Int).Set(&d.q)
	cs := ""
	if c.Sign() == -1 {
		cs = "-"
		c.Neg(c)
	}
	qs := ""
	if q.Sign() == -1 {
		qs = "-"
		q.Neg(q)
	}
	return fmt.Sprintf("%v%v*10^%v%v", cs, c.Dec(), qs, q.Dec())
}

func BenchmarkOpAdd(b *testing.B) {
	intArgs := []*uint256.Int{uint256.NewInt(987349875), uint256.NewInt(987349875), uint256.NewInt(987349875), uint256.NewInt(987349875)}
	benchmarkOpDec(b, intArgs, opAdd)
}

func BenchmarkOpDecAdd(b *testing.B) {
	intArgs := []*uint256.Int{PRECISION, uint256.NewInt(987349875), uint256.NewInt(987349875), uint256.NewInt(987349875), uint256.NewInt(987349875)}
	benchmarkOpDec(b, intArgs, opDecAdd)
}

func BenchmarkOpDecNeg(b *testing.B) {
	intArgs := []*uint256.Int{uint256.NewInt(987349875), uint256.NewInt(987349875)}
	benchmarkOpDec(b, intArgs, opDecNeg)
}

func BenchmarkOpDecMul(b *testing.B) {
	intArgs := []*uint256.Int{PRECISION, uint256.NewInt(987349875), uint256.NewInt(987349875), uint256.NewInt(987349875), uint256.NewInt(987349875)}
	benchmarkOpDec(b, intArgs, opDecMul)
}

func BenchmarkOpDecInv(b *testing.B) {
	// opDecInv benchmark does not depend on precision
	intArgs := []*uint256.Int{PRECISION, MINUS_ONE_INT256, uint256.NewInt(1)}
	benchmarkOpDec(b, intArgs, opDecInv)
}

func BenchmarkOpDecExp(b *testing.B) {
	// opDecExp benchmark depends on steps
	steps := uint256.NewInt(10)
	intArgs := []*uint256.Int{steps, PRECISION, uint256.NewInt(0), uint256.NewInt(1)}
	fmt.Println("BenchmarkOpDecExp steps=", steps)
	benchmarkOpDec(b, intArgs, opDecExp)
}

func BenchmarkOpDecLn(b *testing.B) {
	// opDecExp benchmark depends on steps
	steps := uint256.NewInt(10)
	intArgs := []*uint256.Int{steps, PRECISION, uint256.NewInt(0), uint256.NewInt(2)}
	fmt.Println("BenchmarkOpDecLn steps=", steps)
	benchmarkOpDec(b, intArgs, opDecLn)
}

func BenchmarkOpDecSin(b *testing.B) {
	// opDecExp benchmark depends on precision
	steps := uint256.NewInt(10)
	intArgs := []*uint256.Int{steps, PRECISION, uint256.NewInt(0), uint256.NewInt(1)}
	fmt.Println("BenchmarkOpDecSin steps=", steps)
	benchmarkOpDec(b, intArgs, opDecSin)
}

func benchmarkOpDec(b *testing.B, intArgs []*uint256.Int, op executionFunc) {
	var (
		env            = NewEVM(BlockContext{}, TxContext{}, nil, params.TestChainConfig, Config{})
		stack          = newstack()
		scope          = &ScopeContext{nil, stack, nil}
		evmInterpreter = NewEVMInterpreter(env)
	)

	env.interpreter = evmInterpreter

	pc := uint64(0)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		for _, arg := range intArgs {
			stack.push(arg)
		}
		op(&pc, evmInterpreter, scope)
		stack.pop()
		stack.pop()
	}
	b.StopTimer()
}

func TestSignedCmp(t *testing.T) {
	var gas uint64

	a := new(uint256.Int).Neg(uint256.NewInt(14))
	b := new(uint256.Int).Neg(uint256.NewInt(15))
	c := signedCmp(a, b, &gas)
	fmt.Println(c)
}

func TestDecAdd(t *testing.T) {
	var gas uint64

	tests := []struct {
		a Decimal
		b Decimal
		c Decimal
	}{
		{*createDecimal(uint256.NewInt(5), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(121), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(171), MINUS_ONE_INT256, &gas)},
		{*createDecimal(uint256.NewInt(5), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(121), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(126), ZERO_INT256, &gas)},
		{*createDecimal(new(uint256.Int).Neg(TWO_INT256), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(8), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(6), MINUS_ONE_INT256, &gas)},
		{*createDecimal(uint256.NewInt(5), MINUS_ONE_INT256, &gas), *createDecimal(new(uint256.Int).Neg(TWO_INT256), ZERO_INT256, &gas), *createDecimal(new(uint256.Int).Neg(uint256.NewInt(15)), MINUS_ONE_INT256, &gas)},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.Add(&tt.a, &tt.b, PRECISION, &gas)

		if !out.eq(&tt.c, PRECISION, &gas) {
			t.Fatal(tt.a, tt.b, out, tt.c)
		}
	}
}

func TestDecNeg(t *testing.T) {
	var gas uint64

	tests := []struct {
		a Decimal
		b Decimal
	}{
		{*createDecimal(uint256.NewInt(2), ZERO_INT256, &gas), *createDecimal(new(uint256.Int).Neg(TWO_INT256), ZERO_INT256, &gas)},
		{*createDecimal(uint256.NewInt(5), MINUS_ONE_INT256, &gas), *createDecimal(new(uint256.Int).Neg(FIVE_INT256), MINUS_ONE_INT256, &gas)},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.Neg(&tt.a, &gas)

		if !out.eq(&tt.b, PRECISION, &gas) {
			t.Fatal(tt.a, tt.b, out)
		}
	}
}

func TestDecMul(t *testing.T) {
	var gas uint64

	tests := []struct {
		a Decimal
		b Decimal
		c Decimal
	}{
		{*createDecimal(uint256.NewInt(2), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(2), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(4), ZERO_INT256, &gas)},
		{*createDecimal(uint256.NewInt(2), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(5), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(1), ZERO_INT256, &gas)},
		{*createDecimal(new(uint256.Int).Neg(TWO_INT256), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(5), MINUS_ONE_INT256, &gas), *createDecimal(MINUS_ONE_INT256, ZERO_INT256, &gas)},
		{*createDecimal(new(uint256.Int).Neg(TWO_INT256), ZERO_INT256, &gas), *createDecimal(new(uint256.Int).Neg(FIVE_INT256), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(1), ZERO_INT256, &gas)},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.Mul(&tt.a, &tt.b, PRECISION, &gas)

		if !out.eq(&tt.c, PRECISION, &gas) {
			t.Fatal(tt.a, tt.b, out, tt.c)
		}
	}
}

func TestDecInv(t *testing.T) {
	var gas uint64

	tests := []struct {
		a Decimal
		b Decimal
	}{
		{*copyDecimal(ONE_DECIMAL, &gas), *copyDecimal(ONE_DECIMAL, &gas)},
		{*createDecimal(uint256.NewInt(2), ZERO_INT256, &gas), *createDecimal(uint256.NewInt(5), MINUS_ONE_INT256, &gas)},
		{*createDecimal(new(uint256.Int).Neg(uint256.NewInt(20)), MINUS_ONE_INT256, &gas), *createDecimal(new(uint256.Int).Neg(FIVE_INT256), MINUS_ONE_INT256, &gas)},
		{*createDecimal(uint256.NewInt(2), ONE_INT256, &gas), *createDecimal(uint256.NewInt(5), new(uint256.Int).Neg(TWO_INT256), &gas)},
		{*createDecimal(uint256.NewInt(2), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(5), ZERO_INT256, &gas)},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.Inv(&tt.a, PRECISION, &gas)

		if !out.eq(&tt.b, PRECISION, &gas) {
			t.Fatal(tt.a, out, tt.b)
		}
	}
}

func TestDecNormalize(t *testing.T) {
	var gas uint64

	LARGE_TEN := uint256.NewInt(10)
	LARGE_TEN.Exp(LARGE_TEN, uint256.NewInt(75))

	TEN_TEN := uint256.NewInt(10)
	TEN_TEN.Exp(TEN_TEN, uint256.NewInt(10))

	NEG_45 := new(uint256.Int).Neg(uint256.NewInt(45))
	NEG_55 := new(uint256.Int).Neg(uint256.NewInt(55))
	NEG_75 := new(uint256.Int).Neg(uint256.NewInt(75))

	var TEN_48, FIVE_48, MINUS_FIVE_48 uint256.Int
	TEN_48.Exp(uint256.NewInt(10), uint256.NewInt(48))
	FIVE_48.Mul(uint256.NewInt(5), &TEN_48)
	MINUS_FIVE_48.Neg(&FIVE_48)
	MINUS_49 := new(uint256.Int).Neg(uint256.NewInt(49))
	MINUS_5 := new(uint256.Int).Neg(FIVE_INT256)

	tests := []struct {
		a       Decimal
		b       Decimal
		rounded bool
	}{
		{*createDecimal(uint256.NewInt(15), MINUS_ONE_INT256, &gas), *createDecimal(uint256.NewInt(15), MINUS_ONE_INT256, &gas), false},
		{*copyDecimal(ONE_DECIMAL, &gas), *copyDecimal(ONE_DECIMAL, &gas), false},
		{*createDecimal(uint256.NewInt(100), new(uint256.Int).Neg(TWO_INT256), &gas), *copyDecimal(ONE_DECIMAL, &gas), false},
		{*createDecimal(LARGE_TEN, NEG_75, &gas), *copyDecimal(ONE_DECIMAL, &gas), false},
		{*createDecimal(TEN_TEN, NEG_55, &gas), *createDecimal(ONE_INT256, NEG_45, &gas), true},
		{*createDecimal(&MINUS_FIVE_48, MINUS_49, &gas), *createDecimal(MINUS_5, MINUS_ONE_INT256, &gas), false},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.normalize(&tt.a, PRECISION, tt.rounded, &gas)

		if !out.eq(&tt.b, PRECISION, &gas) {
			t.Fatal(tt.a, out, tt.b)
		}
	}
}

func TestDecExp(t *testing.T) {
	var gas uint64

	tests := []struct {
		a     Decimal
		steps uint256.Int
		b     Decimal
	}{
		{*copyDecimal(ONE_DECIMAL, &gas), *uint256.NewInt(10), *createDecimal(uint256.NewInt(27182815251), new(uint256.Int).Neg(TEN_INT256), &gas)},
		{*createDecimal(MINUS_ONE_INT256, uint256.NewInt(0), &gas), *uint256.NewInt(10), *createDecimal(uint256.NewInt(3678791887), new(uint256.Int).Neg(TEN_INT256), &gas)},
	}
	for _, tt := range tests {

		var out Decimal
		gas = 0
		out.Exp(&tt.a, PRECISION, &tt.steps, &gas)

		if !out.eq(&tt.b, PRECISION, &gas) {
			t.Fatal(tt.a, out, tt.b)
		}
	}
}

func TestDecLn(t *testing.T) {
	var gas uint64

	tests := []struct {
		a     Decimal
		steps uint256.Int
		b     Decimal
	}{
		{*ONE_DECIMAL, *uint256.NewInt(10), *createDecimal(uint256.NewInt(5849609375), new(uint256.Int).Neg(TEN_INT256), &gas)},
		{*createDecimal(uint256.NewInt(5), MINUS_ONE_INT256, &gas), *uint256.NewInt(10), *createDecimal(uint256.NewInt(5849609375), new(uint256.Int).Neg(TEN_INT256), &gas)},
		{*createDecimal(uint256.NewInt(11), ZERO_INT256, &gas), *uint256.NewInt(5), *createDecimal(uint256.NewInt(5849609375), new(uint256.Int).Neg(TEN_INT256), &gas)},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.Ln(&tt.a, PRECISION, &tt.steps, &gas)

		if !out.eq(&tt.b, PRECISION) {
			t.Fatal(tt.a, out, tt.b)
		}
	}
}

func TestDecSin(t *testing.T) {
	var gas uint64

	tests := []struct {
		a     Decimal
		steps uint256.Int
		b     Decimal
	}{
		{*copyDecimal(ONE_DECIMAL, &gas), *uint256.NewInt(10), *createDecimal(uint256.NewInt(8414709849), new(uint256.Int).Neg(TEN_INT256), &gas)},
	}
	for _, tt := range tests {
		var out Decimal
		gas = 0
		out.Sin(&tt.a, PRECISION, &tt.steps, &gas)

		if !out.eq(&tt.b, PRECISION, &gas) {
			t.Fatal(tt.a, out, tt.b)
		}
	}
}
