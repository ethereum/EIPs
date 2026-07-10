package vm

import (
	"github.com/holiman/uint256"
	"github.com/ethereum/go-ethereum/params"
)

type int256 = uint256.Int

func New(a uint64, gas *uint64) *int256 {
	return uint256.NewInt(a)
}

func Add(a, b, out *int256, gas *uint64) *int256 {
	out.Add(a, b)
	*gas += GasFastestStep
	return out
}

func Set(a, out *int256, gas *uint64) *int256 {
	out.Set(a)
	return out
}

func Sub(a, b, out *int256, gas *uint64) *int256 {
	out.Sub(a, b)
	*gas += GasFastestStep
	return out
}

func Mod(a, b, out *int256, gas *uint64) *int256 {
	out.Mod(a, b)
	*gas += GasFastStep
	return out
}

func Sign(a *int256, gas *uint64) int {
	return a.Sign()
}

func Cmp(a, b *int256, gas *uint64) int {
	*gas += GasFastStep
	return b.Cmp(a)
}

func Exp(a, b, out *int256, gas *uint64) *int256 {
	out.Exp(a, b)

	expByteLen := uint64((b.BitLen() + 7) / 8)
	*gas += expByteLen * params.ExpByteEIP158

	return out
}

func Mul(a, b, out *int256, gas *uint64) *int256 {
	out.Mul(a, b)
	*gas += GasFastStep
	return out
}

func Div(a, b, out *int256, gas *uint64) *int256 {
	out.Div(a, b)
	*gas += GasFastStep
	return out
}

func Neg(a, out *int256, gas *uint64) *int256 {
	out.Neg(a) // also has new, maybe more gas?
	*gas += GasFastestStep
	return out
}

func IsZero(a *int256, gas *uint64) bool {
	return a.IsZero()
}

func Lsh(a *int256, n uint, out *int256, gas *uint64) *int256 {
	out.Lsh(a, n)
	*gas += GasFastestStep // ?
	return out
}
