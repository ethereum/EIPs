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
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/params"
)

// precompiledTest defines the input/output pairs for precompiled contract tests.
type precompiledTest struct {
	Input, Expected string
	Gas             uint64
	Name            string
	NoBenchmark     bool // Benchmark primarily the worst-cases
}

// precompiledFailureTest defines the input/error pairs for precompiled
// contract failure tests.
type precompiledFailureTest struct {
	Input         string
	ExpectedError string
	Name          string
}

// allPrecompiles does not map to the actual set of precompiles, as it also contains
// repriced versions of precompiles at certain slots
var allPrecompiles = map[common.Address]PrecompiledContract{
	common.BytesToAddress([]byte{1}):    &ecrecover{},
	common.BytesToAddress([]byte{2}):    &sha256hash{},
	common.BytesToAddress([]byte{3}):    &ripemd160hash{},
	common.BytesToAddress([]byte{4}):    &dataCopy{},
	common.BytesToAddress([]byte{5}):    &bigModExp{eip2565: false, eip7883: false},
	common.BytesToAddress([]byte{0xf5}): &bigModExp{eip2565: true, eip7883: false},
	common.BytesToAddress([]byte{0xf6}): &bigModExp{eip2565: true, eip7883: true},
	common.BytesToAddress([]byte{6}):    &bn256AddIstanbul{},
	common.BytesToAddress([]byte{7}):    &bn256ScalarMulIstanbul{},
	common.BytesToAddress([]byte{8}):    &bn256PairingGranite{},
	common.BytesToAddress([]byte{9}):    &blake2F{},
	common.BytesToAddress([]byte{0x0a}): &kzgPointEvaluation{},

	common.BytesToAddress([]byte{0x0f, 0x0a}): &bls12381G1Add{},
	common.BytesToAddress([]byte{0x0f, 0x0b}): &bls12381G1MultiExp{},
	common.BytesToAddress([]byte{0x1f, 0x0b}): &bls12381G1MultiExpIsthmus{},
	common.BytesToAddress([]byte{0x0f, 0x0c}): &bls12381G2Add{},
	common.BytesToAddress([]byte{0x0f, 0x0d}): &bls12381G2MultiExp{},
	common.BytesToAddress([]byte{0x1f, 0x0d}): &bls12381G2MultiExpIsthmus{},
	common.BytesToAddress([]byte{0x0f, 0x0e}): &bls12381Pairing{},
	common.BytesToAddress([]byte{0x1f, 0x0e}): &bls12381PairingIsthmus{},
	common.BytesToAddress([]byte{0x0f, 0x0f}): &bls12381MapG1{},
	common.BytesToAddress([]byte{0x0f, 0x10}): &bls12381MapG2{},

	common.BytesToAddress([]byte{0x0b}): &p256Verify{},
	common.BytesToAddress([]byte{0x12}): &NTT{},
	common.BytesToAddress([]byte{0x13}): &nttVecMulMod{},
	common.BytesToAddress([]byte{0x14}): &nttVecAddMod{},

	common.BytesToAddress([]byte{0x01, 0x00}): &p256VerifyFjord{},
}

// EIP-152 test vectors
var blake2FMalformedInputTests = []precompiledFailureTest{
	{
		Input:         "",
		ExpectedError: errBlake2FInvalidInputLength.Error(),
		Name:          "vector 0: empty input",
	},
	{
		Input:         "00000c48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b61626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000001",
		ExpectedError: errBlake2FInvalidInputLength.Error(),
		Name:          "vector 1: less than 213 bytes input",
	},
	{
		Input:         "000000000c48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b61626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000001",
		ExpectedError: errBlake2FInvalidInputLength.Error(),
		Name:          "vector 2: more than 213 bytes input",
	},
	{
		Input:         "0000000c48c9bdf267e6096a3ba7ca8485ae67bb2bf894fe72f36e3cf1361d5f3af54fa5d182e6ad7f520e511f6c3e2b8c68059b6bbd41fbabd9831f79217e1319cde05b61626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000002",
		ExpectedError: errBlake2FInvalidFinalFlag.Error(),
		Name:          "vector 3: malformed final block indicator flag",
	},
}

func testPrecompiled(addr string, test precompiledTest, t *testing.T) {
	p := allPrecompiles[common.HexToAddress(addr)]
	in := common.Hex2Bytes(test.Input)
	gas := p.RequiredGas(in)
	t.Run(fmt.Sprintf("%s-Gas=%d", test.Name, gas), func(t *testing.T) {
		if res, _, err := RunPrecompiledContract(p, in, gas, nil); err != nil {
			t.Error(err)
		} else if common.Bytes2Hex(res) != test.Expected {
			t.Errorf("Expected %v, got %v", test.Expected, common.Bytes2Hex(res))
		}
		if expGas := test.Gas; expGas != gas {
			t.Errorf("%v: gas wrong, expected %d, got %d", test.Name, expGas, gas)
		}
		// Verify that the precompile did not touch the input buffer
		exp := common.Hex2Bytes(test.Input)
		if !bytes.Equal(in, exp) {
			t.Errorf("Precompiled %v modified input data", addr)
		}
	})
}

func testPrecompiledOOG(addr string, test precompiledTest, t *testing.T) {
	p := allPrecompiles[common.HexToAddress(addr)]
	in := common.Hex2Bytes(test.Input)
	gas := p.RequiredGas(in) - 1

	t.Run(fmt.Sprintf("%s-Gas=%d", test.Name, gas), func(t *testing.T) {
		_, _, err := RunPrecompiledContract(p, in, gas, nil)
		if err.Error() != "out of gas" {
			t.Errorf("Expected error [out of gas], got [%v]", err)
		}
		// Verify that the precompile did not touch the input buffer
		exp := common.Hex2Bytes(test.Input)
		if !bytes.Equal(in, exp) {
			t.Errorf("Precompiled %v modified input data", addr)
		}
	})
}

func testPrecompiledFailure(addr string, test precompiledFailureTest, t *testing.T) {
	p := allPrecompiles[common.HexToAddress(addr)]
	in := common.Hex2Bytes(test.Input)
	gas := p.RequiredGas(in)
	t.Run(test.Name, func(t *testing.T) {
		_, _, err := RunPrecompiledContract(p, in, gas, nil)
		if err.Error() != test.ExpectedError {
			t.Errorf("Expected error [%v], got [%v]", test.ExpectedError, err)
		}
		// Verify that the precompile did not touch the input buffer
		exp := common.Hex2Bytes(test.Input)
		if !bytes.Equal(in, exp) {
			t.Errorf("Precompiled %v modified input data", addr)
		}
	})
}

func benchmarkPrecompiled(addr string, test precompiledTest, bench *testing.B) {
	if test.NoBenchmark {
		return
	}
	p := allPrecompiles[common.HexToAddress(addr)]
	in := common.Hex2Bytes(test.Input)
	reqGas := p.RequiredGas(in)

	var (
		res  []byte
		err  error
		data = make([]byte, len(in))
	)

	bench.Run(fmt.Sprintf("%s-Gas=%d", test.Name, reqGas), func(bench *testing.B) {
		bench.ReportAllocs()
		start := time.Now()
		bench.ResetTimer()
		for i := 0; i < bench.N; i++ {
			copy(data, in)
			res, _, err = RunPrecompiledContract(p, data, reqGas, nil)
		}
		bench.StopTimer()
		elapsed := uint64(time.Since(start))
		if elapsed < 1 {
			elapsed = 1
		}
		gasUsed := reqGas * uint64(bench.N)
		bench.ReportMetric(float64(reqGas), "gas/op")
		// Keep it as uint64, multiply 100 to get two digit float later
		mgasps := (100 * 1000 * gasUsed) / elapsed
		bench.ReportMetric(float64(mgasps)/100, "mgas/s")
		//Check if it is correct
		if err != nil {
			bench.Error(err)
			return
		}
		if common.Bytes2Hex(res) != test.Expected {
			bench.Errorf("Expected %v, got %v", test.Expected, common.Bytes2Hex(res))
			return
		}
	})
}

// Benchmarks the sample inputs from the ECRECOVER precompile.
func BenchmarkPrecompiledEcrecover(bench *testing.B) {
	t := precompiledTest{
		Input:    "38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e000000000000000000000000000000000000000000000000000000000000001b38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02",
		Expected: "000000000000000000000000ceaccac640adf55b2028469bd36ba501f28b699d",
		Name:     "",
	}
	benchmarkPrecompiled("01", t, bench)
}

// Benchmarks the sample inputs from the SHA256 precompile.
func BenchmarkPrecompiledSha256(bench *testing.B) {
	t := precompiledTest{
		Input:    "38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e000000000000000000000000000000000000000000000000000000000000001b38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02",
		Expected: "811c7003375852fabd0d362e40e68607a12bdabae61a7d068fe5fdd1dbbf2a5d",
		Name:     "128",
	}
	benchmarkPrecompiled("02", t, bench)
}

// Benchmarks the sample inputs from the RIPEMD precompile.
func BenchmarkPrecompiledRipeMD(bench *testing.B) {
	t := precompiledTest{
		Input:    "38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e000000000000000000000000000000000000000000000000000000000000001b38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02",
		Expected: "0000000000000000000000009215b8d9882ff46f0dfde6684d78e831467f65e6",
		Name:     "128",
	}
	benchmarkPrecompiled("03", t, bench)
}

// Benchmarks the sample inputs from the identity precompile.
func BenchmarkPrecompiledIdentity(bench *testing.B) {
	t := precompiledTest{
		Input:    "38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e000000000000000000000000000000000000000000000000000000000000001b38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02",
		Expected: "38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e000000000000000000000000000000000000000000000000000000000000001b38d18acb67d25c8bb9942764b62f18e17054f66a817bd4295423adf9ed98873e789d1dd423d25f0772d2748d60f7e4b81bb14d086eba8e8e8efb6dcff8a4ae02",
		Name:     "128",
	}
	benchmarkPrecompiled("04", t, bench)
}

// Tests the sample inputs from the ModExp EIP 198.
func TestPrecompiledModExp(t *testing.T)      { testJson("modexp", "05", t) }
func BenchmarkPrecompiledModExp(b *testing.B) { benchJson("modexp", "05", b) }

func TestPrecompiledModExpEip2565(t *testing.T)      { testJson("modexp_eip2565", "f5", t) }
func BenchmarkPrecompiledModExpEip2565(b *testing.B) { benchJson("modexp_eip2565", "f5", b) }

func TestPrecompiledModExpEip7883(t *testing.T)      { testJson("modexp_eip7883", "f6", t) }
func BenchmarkPrecompiledModExpEip7883(b *testing.B) { benchJson("modexp_eip7883", "f6", b) }

// Tests the sample inputs from the elliptic curve addition EIP 213.
func TestPrecompiledBn256Add(t *testing.T)      { testJson("bn256Add", "06", t) }
func BenchmarkPrecompiledBn256Add(b *testing.B) { benchJson("bn256Add", "06", b) }

// Tests OOG
func TestPrecompiledModExpOOG(t *testing.T) {
	modexpTests, err := loadJson("modexp")
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range modexpTests {
		testPrecompiledOOG("05", test, t)
	}
}

// Tests the sample inputs from the elliptic curve scalar multiplication EIP 213.
func TestPrecompiledBn256ScalarMul(t *testing.T)      { testJson("bn256ScalarMul", "07", t) }
func BenchmarkPrecompiledBn256ScalarMul(b *testing.B) { benchJson("bn256ScalarMul", "07", b) }

// Tests the sample inputs from the elliptic curve pairing check EIP 197.
func TestPrecompiledBn256Pairing(t *testing.T)      { testJson("bn256Pairing", "08", t) }
func BenchmarkPrecompiledBn256Pairing(b *testing.B) { benchJson("bn256Pairing", "08", b) }

func TestPrecompiledBlake2F(t *testing.T)      { testJson("blake2F", "09", t) }
func BenchmarkPrecompiledBlake2F(b *testing.B) { benchJson("blake2F", "09", b) }

func TestPrecompileBlake2FMalformedInput(t *testing.T) {
	for _, test := range blake2FMalformedInputTests {
		testPrecompiledFailure("09", test, t)
	}
}

func TestPrecompileBn256PairingTooLargeInput(t *testing.T) {
	big := make([]byte, params.Bn256PairingMaxInputSizeGranite+1)
	testPrecompiledFailure("08", precompiledFailureTest{
		Input:         common.Bytes2Hex(big),
		ExpectedError: "bad elliptic curve pairing input size",
		Name:          "bn256Pairing_input_too_big",
	}, t)
}

func TestPrecompileBlsInputSize(t *testing.T) {
	big := make([]byte, params.Bls12381G1MulMaxInputSizeIsthmus+1)
	testPrecompiledFailure("1f0b", precompiledFailureTest{
		Input:         common.Bytes2Hex(big),
		ExpectedError: "g1 msm input size exceeds maximum",
		Name:          "bls12381G1MSM_input_too_big",
	}, t)

	big = make([]byte, params.Bls12381G2MulMaxInputSizeIsthmus+1)
	testPrecompiledFailure("1f0d", precompiledFailureTest{
		Input:         common.Bytes2Hex(big),
		ExpectedError: "g2 msm input size exceeds maximum",
		Name:          "bls12381G2MSM_input_too_big",
	}, t)

	big = make([]byte, params.Bls12381PairingMaxInputSizeIsthmus+1)
	testPrecompiledFailure("1f0e", precompiledFailureTest{
		Input:         common.Bytes2Hex(big),
		ExpectedError: "pairing input size exceeds maximum",
		Name:          "bls12381Pairing_input_too_big",
	}, t)
}

func TestPrecompiledEcrecover(t *testing.T) { testJson("ecRecover", "01", t) }

func testJson(name, addr string, t *testing.T) {
	tests, err := loadJson(name)
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range tests {
		testPrecompiled(addr, test, t)
	}
}

func testJsonFail(name, addr string, t *testing.T) {
	tests, err := loadJsonFail(name)
	if err != nil {
		t.Fatal(err)
	}
	for _, test := range tests {
		testPrecompiledFailure(addr, test, t)
	}
}

func benchJson(name, addr string, b *testing.B) {
	tests, err := loadJson(name)
	if err != nil {
		b.Fatal(err)
	}
	for _, test := range tests {
		benchmarkPrecompiled(addr, test, b)
	}
}

func TestPrecompiledBLS12381G1Add(t *testing.T)      { testJson("blsG1Add", "f0a", t) }
func TestPrecompiledBLS12381G1Mul(t *testing.T)      { testJson("blsG1Mul", "f0b", t) }
func TestPrecompiledBLS12381G1MultiExp(t *testing.T) { testJson("blsG1MultiExp", "f0b", t) }
func TestPrecompiledBLS12381G2Add(t *testing.T)      { testJson("blsG2Add", "f0c", t) }
func TestPrecompiledBLS12381G2Mul(t *testing.T)      { testJson("blsG2Mul", "f0d", t) }
func TestPrecompiledBLS12381G2MultiExp(t *testing.T) { testJson("blsG2MultiExp", "f0d", t) }
func TestPrecompiledBLS12381Pairing(t *testing.T)    { testJson("blsPairing", "f0e", t) }
func TestPrecompiledBLS12381MapG1(t *testing.T)      { testJson("blsMapG1", "f0f", t) }
func TestPrecompiledBLS12381MapG2(t *testing.T)      { testJson("blsMapG2", "f10", t) }

func TestPrecompiledPointEvaluation(t *testing.T) { testJson("pointEvaluation", "0a", t) }

func BenchmarkPrecompiledPointEvaluation(b *testing.B) { benchJson("pointEvaluation", "0a", b) }

func BenchmarkPrecompiledBLS12381G1Add(b *testing.B)      { benchJson("blsG1Add", "f0a", b) }
func BenchmarkPrecompiledBLS12381G1MultiExp(b *testing.B) { benchJson("blsG1MultiExp", "f0b", b) }
func BenchmarkPrecompiledBLS12381G2Add(b *testing.B)      { benchJson("blsG2Add", "f0c", b) }
func BenchmarkPrecompiledBLS12381G2MultiExp(b *testing.B) { benchJson("blsG2MultiExp", "f0d", b) }
func BenchmarkPrecompiledBLS12381Pairing(b *testing.B)    { benchJson("blsPairing", "f0e", b) }
func BenchmarkPrecompiledBLS12381MapG1(b *testing.B)      { benchJson("blsMapG1", "f0f", b) }
func BenchmarkPrecompiledBLS12381MapG2(b *testing.B)      { benchJson("blsMapG2", "f10", b) }

// Failure tests
func TestPrecompiledBLS12381G1AddFail(t *testing.T)      { testJsonFail("blsG1Add", "f0a", t) }
func TestPrecompiledBLS12381G1MulFail(t *testing.T)      { testJsonFail("blsG1Mul", "f0b", t) }
func TestPrecompiledBLS12381G1MultiExpFail(t *testing.T) { testJsonFail("blsG1MultiExp", "f0b", t) }
func TestPrecompiledBLS12381G2AddFail(t *testing.T)      { testJsonFail("blsG2Add", "f0c", t) }
func TestPrecompiledBLS12381G2MulFail(t *testing.T)      { testJsonFail("blsG2Mul", "f0d", t) }
func TestPrecompiledBLS12381G2MultiExpFail(t *testing.T) { testJsonFail("blsG2MultiExp", "f0d", t) }
func TestPrecompiledBLS12381PairingFail(t *testing.T)    { testJsonFail("blsPairing", "f0e", t) }
func TestPrecompiledBLS12381MapG1Fail(t *testing.T)      { testJsonFail("blsMapG1", "f0f", t) }
func TestPrecompiledBLS12381MapG2Fail(t *testing.T)      { testJsonFail("blsMapG2", "f10", t) }

func loadJson(name string) ([]precompiledTest, error) {
	data, err := os.ReadFile(fmt.Sprintf("testdata/precompiles/%v.json", name))
	if err != nil {
		return nil, err
	}
	var testcases []precompiledTest
	err = json.Unmarshal(data, &testcases)
	return testcases, err
}

func loadJsonFail(name string) ([]precompiledFailureTest, error) {
	data, err := os.ReadFile(fmt.Sprintf("testdata/precompiles/fail-%v.json", name))
	if err != nil {
		return nil, err
	}
	var testcases []precompiledFailureTest
	err = json.Unmarshal(data, &testcases)
	return testcases, err
}

// BenchmarkPrecompiledBLS12381G1MultiExpWorstCase benchmarks the worst case we could find that still fits a gaslimit of 10MGas.
func BenchmarkPrecompiledBLS12381G1MultiExpWorstCase(b *testing.B) {
	task := "0000000000000000000000000000000008d8c4a16fb9d8800cce987c0eadbb6b3b005c213d44ecb5adeed713bae79d606041406df26169c35df63cf972c94be1" +
		"0000000000000000000000000000000011bc8afe71676e6730702a46ef817060249cd06cd82e6981085012ff6d013aa4470ba3a2c71e13ef653e1e223d1ccfe9" +
		"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
	input := task
	for i := 0; i < 4787; i++ {
		input = input + task
	}
	testcase := precompiledTest{
		Input:       input,
		Expected:    "0000000000000000000000000000000005a6310ea6f2a598023ae48819afc292b4dfcb40aabad24a0c2cb6c19769465691859eeb2a764342a810c5038d700f18000000000000000000000000000000001268ac944437d15923dc0aec00daa9250252e43e4b35ec7a19d01f0d6cd27f6e139d80dae16ba1c79cc7f57055a93ff5",
		Name:        "WorstCaseG1",
		NoBenchmark: false,
	}
	benchmarkPrecompiled("f0b", testcase, b)
}

// BenchmarkPrecompiledBLS12381G2MultiExpWorstCase benchmarks the worst case we could find that still fits a gaslimit of 10MGas.
func BenchmarkPrecompiledBLS12381G2MultiExpWorstCase(b *testing.B) {
	task := "000000000000000000000000000000000d4f09acd5f362e0a516d4c13c5e2f504d9bd49fdfb6d8b7a7ab35a02c391c8112b03270d5d9eefe9b659dd27601d18f" +
		"000000000000000000000000000000000fd489cb75945f3b5ebb1c0e326d59602934c8f78fe9294a8877e7aeb95de5addde0cb7ab53674df8b2cfbb036b30b99" +
		"00000000000000000000000000000000055dbc4eca768714e098bbe9c71cf54b40f51c26e95808ee79225a87fb6fa1415178db47f02d856fea56a752d185f86b" +
		"000000000000000000000000000000001239b7640f416eb6e921fe47f7501d504fadc190d9cf4e89ae2b717276739a2f4ee9f637c35e23c480df029fd8d247c7" +
		"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
	input := task
	for i := 0; i < 1040; i++ {
		input = input + task
	}

	testcase := precompiledTest{
		Input:       input,
		Expected:    "0000000000000000000000000000000018f5ea0c8b086095cfe23f6bb1d90d45de929292006dba8cdedd6d3203af3c6bbfd592e93ecb2b2c81004961fdcbb46c00000000000000000000000000000000076873199175664f1b6493a43c02234f49dc66f077d3007823e0343ad92e30bd7dc209013435ca9f197aca44d88e9dac000000000000000000000000000000000e6f07f4b23b511eac1e2682a0fc224c15d80e122a3e222d00a41fab15eba645a700b9ae84f331ae4ed873678e2e6c9b000000000000000000000000000000000bcb4849e460612aaed79617255fd30c03f51cf03d2ed4163ca810c13e1954b1e8663157b957a601829bb272a4e6c7b8",
		Name:        "WorstCaseG2",
		NoBenchmark: false,
	}
	benchmarkPrecompiled("f0d", testcase, b)
}

// Benchmarks the sample inputs from the P256VERIFY precompile.
func BenchmarkPrecompiledP256VerifyFjord(bench *testing.B) {
	t := precompiledTest{
		Input:    "4cee90eb86eaa050036147a12d49004b6b9c72bd725d39d4785011fe190f0b4da73bd4903f0ce3b639bbbf6e8e80d16931ff4bcf5993d58468e8fb19086e8cac36dbcd03009df8c59286b162af3bd7fcc0450c9aa81be5d10d312af6c66b1d604aebd3099c618202fcfe16ae7770b0c49ab5eadf74b754204a3bb6060e44eff37618b065f9832de4ca6ca971a7a1adc826d0f7c00181a5fb2ddf79ae00b4e10e",
		Expected: "0000000000000000000000000000000000000000000000000000000000000001",
		Name:     "p256VerifyFjord",
	}
	benchmarkPrecompiled("100", t, bench)
}

func TestPrecompiledP256VerifyFjord(t *testing.T) { testJson("p256VerifyFjord", "100", t) }

// Benchmarks the sample inputs from the P256VERIFY precompile.
func BenchmarkPrecompiledP256Verify(bench *testing.B) {
	t := precompiledTest{
		Input:    "4cee90eb86eaa050036147a12d49004b6b9c72bd725d39d4785011fe190f0b4da73bd4903f0ce3b639bbbf6e8e80d16931ff4bcf5993d58468e8fb19086e8cac36dbcd03009df8c59286b162af3bd7fcc0450c9aa81be5d10d312af6c66b1d604aebd3099c618202fcfe16ae7770b0c49ab5eadf74b754204a3bb6060e44eff37618b065f9832de4ca6ca971a7a1adc826d0f7c00181a5fb2ddf79ae00b4e10e",
		Expected: "0000000000000000000000000000000000000000000000000000000000000001",
		Name:     "p256Verify",
	}
	benchmarkPrecompiled("0b", t, bench)
}

func TestPrecompiledP256Verify(t *testing.T) { testJson("p256Verify", "0b", t) }

// Test NTT precompile with malformed inputs
func TestPrecompileNTTMalformedInput(t *testing.T) {
	// NTT malformed input test vectors
	var nttMalformedInputTests = []precompiledFailureTest{
		{
			Input:         "",
			ExpectedError: "input too short",
			Name:          "empty input",
		},
		{
			Input:         "00",
			ExpectedError: "input too short",
			Name:          "too short input",
		},
		{
			Input:         "02000000100000000000000011",
			ExpectedError: "invalid operation: must be 0 (forward) or 1 (inverse)",
			Name:          "invalid operation",
		},
		{
			Input:         "00000000080000000000000011",
			ExpectedError: "invalid ring degree: must be power of 2 >= 16",
			Name:          "invalid ring degree (too small)",
		},
		{
			Input:         "0000000011000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
			ExpectedError: "invalid ring degree: must be power of 2 >= 16",
			Name:          "invalid ring degree (not power of 2)",
		},
		{
			Input:         "00000000100000000000000000",
			ExpectedError: "modulus cannot be zero",
			Name:          "zero modulus",
		},
		{
			Input:         "000000001000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
			ExpectedError: "modulus must be congruent to 1 mod 2*ringDegree",
			Name:          "non NTT-friendly modulus",
		},
		{
			Input:         "00000000100000000000000021000000000000000100000000000000020000000000000003000000000000000400000000000000050000000000000006000000000000000700000000000000080000000000000009000000000000000a000000000000000b000000000000000c000000000000000d000000000000000e000000000000000f0000000000000022",
			ExpectedError: "coefficient 15 exceeds modulus",
			Name:          "coefficient exceeds modulus",
		},
	}
	for _, test := range nttMalformedInputTests {
		testPrecompiledFailure("12", test, t)
	}
}

// Test NTT precompile with valid inputs
func TestPrecompiledNTT(t *testing.T) {
	// Test forward NTT with ring degree 16
	forwardTest := precompiledTest{
		Input:    "00000000100000000000000061000000000000000100000000000000020000000000000003000000000000000400000000000000050000000000000006000000000000000700000000000000080000000000000009000000000000000a000000000000000b000000000000000c000000000000000d000000000000000e000000000000000f0000000000000010",
		Expected: "00000000000000450000000000000028000000000000001d000000000000004c000000000000004c0000000000000001000000000000001600000000000000120000000000000045000000000000004a000000000000002b000000000000003800000000000000200000000000000004000000000000001e0000000000000038",
		Name:     "forward NTT ring degree 16",
		Gas:      70000,
	}
	testPrecompiled("12", forwardTest, t)

	// Test inverse NTT with ring degree 16
	inverseTest := precompiledTest{
		Input:    "0100000010000000000000006100000000000000450000000000000028000000000000001d000000000000004c000000000000004c0000000000000001000000000000001600000000000000120000000000000045000000000000004a000000000000002b000000000000003800000000000000200000000000000004000000000000001e0000000000000038",
		Expected: "000000000000000100000000000000020000000000000003000000000000000400000000000000050000000000000006000000000000000700000000000000080000000000000009000000000000000a000000000000000b000000000000000c000000000000000d000000000000000e000000000000000f0000000000000010",
		Name:     "inverse NTT ring degree 16",
		Gas:      70000,
	}
	testPrecompiled("12", inverseTest, t)
}

// Benchmarks the NTT precompile
func BenchmarkPrecompiledNTT(bench *testing.B) {
	// Basic ring degree 16 benchmark
	nttTest := precompiledTest{
		Input:    "00000000100000000000000061000000000000000100000000000000020000000000000003000000000000000400000000000000050000000000000006000000000000000700000000000000080000000000000009000000000000000a000000000000000b000000000000000c000000000000000d000000000000000e000000000000000f0000000000000010",
		Expected: "00000000000000450000000000000028000000000000001d000000000000004c000000000000004c0000000000000001000000000000001600000000000000120000000000000045000000000000004a000000000000002b000000000000003800000000000000200000000000000004000000000000001e0000000000000038",
		Name:     "NTT-ring16",
		Gas:      70000,
	}
	benchmarkPrecompiled("12", nttTest, bench)
}

// Test NTT_VECMULMOD and NTT_VECADDMOD precompiles with malformed inputs
func TestPrecompileNTTVecOpsMalformedInput(t *testing.T) {
	// Both VECMULMOD and VECADDMOD share the same input validation logic
	malformedInputTests := []precompiledFailureTest{
		{
			Input:         "",
			ExpectedError: "input too short",
			Name:          "empty input",
		},
		{
			Input:         "0000001000000000",
			ExpectedError: "input too short",
			Name:          "too short input",
		},
		{
			Input:         "000000080000000000000061",
			ExpectedError: "invalid ring degree: must be power of 2 >= 16",
			Name:          "invalid ring degree (too small)",
		},
		{
			Input:         "000000110000000000000061",
			ExpectedError: "invalid ring degree: must be power of 2 >= 16",
			Name:          "invalid ring degree (not power of 2)",
		},
		{
			Input:         "000000100000000000000000",
			ExpectedError: "modulus cannot be zero",
			Name:          "zero modulus",
		},
		{
			Input:         "000000100000000000000002" + strings.Repeat("0000000000000000", 32),
			ExpectedError: "modulus must be congruent to 1 mod 2*ringDegree",
			Name:          "non NTT-friendly modulus",
		},
		{
			Input:         "00000010000000000000006100000000000000010000000000000002",
			ExpectedError: "input length mismatch: expected 268, got 28",
			Name:          "input length mismatch",
		},
	}

	// Test VECMULMOD (address 13)
	for _, test := range malformedInputTests {
		testPrecompiledFailure("13", test, t)
	}

	// Test VECADDMOD (address 14)
	for _, test := range malformedInputTests {
		testPrecompiledFailure("14", test, t)
	}
}

// Test NTT_VECMULMOD and NTT_VECADDMOD with valid inputs
func TestPrecompiledNTTVecOps(t *testing.T) {
	// Test VECMULMOD with ring degree 16, modulus 97
	// Vector A: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
	// Vector B: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
	// Expected: [(1*2)%97=2, (2*3)%97=6, (3*4)%97=12, ..., (16*17)%97=78]
	vecMulTest := precompiledTest{
		Input: func() string {
			// ring_degree(4) + modulus(8) + vectorA(16*8) + vectorB(16*8)
			input := fmt.Sprintf("%08x", 16)              // ring degree
			input += fmt.Sprintf("%016x", 97)             // modulus
			for i := 1; i <= 16; i++ {                    // vector A
				input += fmt.Sprintf("%016x", i)
			}
			for i := 2; i <= 17; i++ {                    // vector B
				input += fmt.Sprintf("%016x", i)
			}
			return input
		}(),
		Expected: func() string {
			result := ""
			for i := 1; i <= 16; i++ {
				mul := (i * (i + 1)) % 97
				result += fmt.Sprintf("%016x", mul)
			}
			return result
		}(),
		Name: "vecmul ring degree 16",
		Gas:  72112,
	}
	testPrecompiled("13", vecMulTest, t)

	// Test VECADDMOD with ring degree 16, modulus 97
	// Vector A: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
	// Vector B: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
	// Expected: [(1+2)%97=3, (2+3)%97=5, (3+4)%97=7, ..., (16+17)%97=33]
	vecAddTest := precompiledTest{
		Input: func() string {
			// ring_degree(4) + modulus(8) + vectorA(16*8) + vectorB(16*8)
			input := fmt.Sprintf("%08x", 16)              // ring degree
			input += fmt.Sprintf("%016x", 97)             // modulus
			for i := 1; i <= 16; i++ {                    // vector A
				input += fmt.Sprintf("%016x", i)
			}
			for i := 2; i <= 17; i++ {                    // vector B
				input += fmt.Sprintf("%016x", i)
			}
			return input
		}(),
		Expected: func() string {
			result := ""
			for i := 1; i <= 16; i++ {
				add := (i + (i + 1)) % 97
				result += fmt.Sprintf("%016x", add)
			}
			return result
		}(),
		Name: "vecadd ring degree 16",
		Gas:  72080,
	}
	testPrecompiled("14", vecAddTest, t)
}

// Benchmark NTT precompile with crypto standards
func BenchmarkPrecompiledNTTCryptoStandards(bench *testing.B) {
	// Pre-computed test cases with actual NTT results
	testCases := []precompiledTest{
		{
			Name: "NTT-Falcon-512",
			Gas:  70000,
			Input: func() string {
				operation := "00"
				ringDegree := fmt.Sprintf("%08x", 512)
				modulus := fmt.Sprintf("%016x", 12289)
				coeffs := ""
				for i := 1; i <= 512; i++ {
					coeffs += fmt.Sprintf("%016x", uint64(i)%12289)
				}
				return operation + ringDegree + modulus + coeffs
			}(),
			Expected: "00000000000018ce000000000000025300000000000025f3000000000000039000000000000028020000000000002391000000000000209f000000000000077a00000000000015b1000000000000048d0000000000002d190000000000000b210000000000001dd70000000000000fe600000000000001de000000000000031700000000000018f9000000000000095f0000000000000b050000000000002fb6000000000000154b00000000000029e0000000000000149d0000000000002a990000000000001c070000000000000896000000000000007a00000000000028e900000000000028570000000000000bbf00000000000027cf000000000000143e00000000000018a500000000000005460000000000002a94000000000000213a0000000000002e030000000000000b390000000000001922000000000000162c000000000000019100000000000003ff0000000000000b6a0000000000002d6100000000000027f00000000000002f7d00000000000003ab0000000000001df40000000000000565000000000000144500000000000018f700000000000029b400000000000008b1000000000000043e0000000000000e3e0000000000001be60000000000000bab000000000000034d000000000000245800000000000017b80000000000001dbf0000000000002aae00000000000001440000000000002fbd00000000000007c4000000000000151c00000000000014f500000000000018d00000000000000947000000000000071e000000000000039d000000000000060c0000000000001700000000000000182800000000000022ff0000000000000384000000000000257d00000000000013070000000000000c760000000000000d3700000000000009c90000000000000bdc00000000000019500000000000000d400000000000001e8800000000000000fe000000000000257100000000000022dd0000000000001c0c000000000000023d000000000000065e0000000000002c940000000000001bd400000000000023340000000000002cdf00000000000013c300000000000011410000000000002d83000000000000083e000000000000149c0000000000002a7700000000000029d100000000000020c40000000000002aa800000000000010510000000000001f0900000000000016a70000000000002d1800000000000026d1000000000000239e00000000000024660000000000001efe0000000000001d4e000000000000190500000000000019f7000000000000021100000000000011fd000000000000093700000000000028b100000000000021c30000000000002a97000000000000293200000000000006950000000000000de30000000000000e0d000000000000044b0000000000001c160000000000000bdd0000000000002e4c00000000000012400000000000000236000000000000103800000000000002700000000000000cb60000000000002459000000000000014000000000000017860000000000000b7c0000000000000a16000000000000193000000000000025ec00000000000001e90000000000000a6b0000000000000a38000000000000220700000000000016230000000000002f160000000000002335000000000000062c00000000000019950000000000000bf4000000000000230c00000000000024ec0000000000002e720000000000000b9800000000000002a40000000000002cf100000000000021a9000000000000189d00000000000024b60000000000000da600000000000016660000000000000c2900000000000019a000000000000011ab0000000000000e6300000000000001010000000000002b8a000000000000072700000000000021e40000000000002849000000000000177a00000000000008b70000000000002c79000000000000024700000000000015bc0000000000000ff10000000000000a4c000000000000130f000000000000086a0000000000000375000000000000026a000000000000022a0000000000001c2b0000000000000db70000000000000e6c000000000000096a0000000000001bd8000000000000299100000000000019bc0000000000000a4a0000000000000dd30000000000000d330000000000001c400000000000000aae0000000000001aba0000000000001edd0000000000001cd200000000000008910000000000001a100000000000000a7500000000000028970000000000002a4400000000000012840000000000001ba900000000000003cc00000000000028230000000000000b010000000000002dfd00000000000003da000000000000267c00000000000027f60000000000001cc20000000000001208000000000000227500000000000026880000000000000c480000000000002b8b000000000000089b000000000000095400000000000012be0000000000001b470000000000000cae0000000000000c520000000000001d3c0000000000001e080000000000002a4b000000000000088600000000000016a000000000000015f900000000000006790000000000002b5d0000000000000f090000000000000ee200000000000026c30000000000000eb50000000000000d2d000000000000149f0000000000000ac3000000000000117a0000000000002e2200000000000019cc000000000000015d00000000000010130000000000000c5e00000000000027510000000000001c740000000000000aee00000000000024a900000000000028740000000000002e6a000000000000280e00000000000012f500000000000026fd0000000000002c7f0000000000002f770000000000001a2c0000000000001de40000000000002b060000000000001f10000000000000113500000000000002b70000000000002e4e00000000000023e0000000000000099d0000000000001fcd00000000000020cb0000000000002f8200000000000015310000000000000be600000000000018f600000000000003a000000000000021dd0000000000001877000000000000009800000000000010d50000000000001b260000000000002cd4000000000000104700000000000019dc000000000000071600000000000029d6000000000000280800000000000024fb00000000000027dc000000000000255f00000000000027960000000000000aef0000000000000e0f0000000000000cf30000000000002b660000000000000aa70000000000000007000000000000138b0000000000000cd0000000000000263300000000000010430000000000002aa10000000000000f7800000000000017f7000000000000205500000000000013fd0000000000000e310000000000002029000000000000232c0000000000000640000000000000235a00000000000002790000000000000a1500000000000020290000000000001dff000000000000123800000000000004810000000000000edc0000000000000bd1000000000000173a00000000000015b4000000000000098100000000000009c30000000000001b36000000000000025600000000000023e400000000000025e0000000000000019e00000000000012ca0000000000000dfb00000000000029810000000000002c3f000000000000104b000000000000110c000000000000222a0000000000002de500000000000014c40000000000001fe5000000000000203f0000000000000bc900000000000025e100000000000007bb0000000000001344000000000000022e0000000000002b6d00000000000026340000000000002ffd00000000000014fe00000000000001010000000000001e680000000000001fdb00000000000002500000000000001c0100000000000029ae0000000000000c5100000000000029be00000000000005380000000000000a780000000000000d0a00000000000011e000000000000029a200000000000020f400000000000024a700000000000015050000000000001f7a00000000000022c60000000000001103000000000000025500000000000003e1000000000000000e00000000000029ad000000000000211500000000000014b80000000000000abb00000000000009890000000000002980000000000000123a0000000000000d5500000000000006ca000000000000063600000000000010fe0000000000002b770000000000002ce50000000000000f630000000000002138000000000000244a0000000000002662000000000000244a0000000000000e050000000000002e4e0000000000002dd1000000000000297f000000000000012900000000000009af000000000000067300000000000006260000000000000c5400000000000004010000000000000faf0000000000002810000000000000296c0000000000001336000000000000092000000000000000530000000000000f5500000000000002690000000000000d750000000000001ee00000000000001aab000000000000056b0000000000001c910000000000001c5b00000000000004070000000000000dea0000000000001b8600000000000019a70000000000002f04000000000000282e000000000000232000000000000014550000000000001d75000000000000297f000000000000119b0000000000002f9f0000000000002e0f00000000000010d1000000000000073800000000000022eb000000000000169c00000000000022d90000000000000a0400000000000004b600000000000023670000000000002d08000000000000226b0000000000002f760000000000000fdf000000000000135800000000000011690000000000002d330000000000000e940000000000000a1200000000000012f800000000000028e000000000000015700000000000000b230000000000001874000000000000279a00000000000002160000000000002a7f00000000000008d8000000000000274c00000000000007e60000000000001742000000000000131a0000000000001aa600000000000011560000000000000cae000000000000136900000000000011bd000000000000101d000000000000191a000000000000231d0000000000001a3b00000000000029eb0000000000002c9a00000000000010040000000000000f1200000000000025e10000000000002d6a00000000000019cf0000000000000a770000000000001efd0000000000001d2b000000000000266b000000000000249d00000000000004d3000000000000083600000000000007600000000000000feb0000000000002290000000000000264c0000000000000a530000000000001f4f000000000000124c000000000000077800000000000004840000000000001f400000000000001ea70000000000002f8a0000000000001618000000000000205a000000000000105e0000000000000dd70000000000002e6300000000000011a80000000000000acb0000000000000a19000000000000245200000000000001c000000000000007ca0000000000002b6300000000000015a90000000000000ea00000000000002d720000000000002f7d0000000000000b620000000000001b710000000000001997000000000000249a00000000000029060000000000001d7100000000000023a800000000000019f200000000000002fb0000000000001dce",
		},
		{
			Name: "NTT-Kyber-128",
			Gas:  70000,
			Input: func() string {
				operation := "00"
				ringDegree := fmt.Sprintf("%08x", 128)
				modulus := fmt.Sprintf("%016x", 3329)
				coeffs := ""
				for i := 1; i <= 128; i++ {
					coeffs += fmt.Sprintf("%016x", uint64(i)%3329)
				}
				return operation + ringDegree + modulus + coeffs
			}(),
			Expected: "00000000000001100000000000000ae4000000000000099300000000000003da0000000000000a0e00000000000002f3000000000000062300000000000002e20000000000000c87000000000000085800000000000007790000000000000667000000000000065700000000000004e800000000000007c3000000000000044800000000000001c9000000000000001b0000000000000cd500000000000007d60000000000000bdd0000000000000948000000000000082300000000000002a400000000000002ec00000000000003e00000000000000079000000000000031300000000000008900000000000000a3300000000000003e200000000000004bc00000000000007ec0000000000000bae00000000000004990000000000000652000000000000045e00000000000006c50000000000000c1b00000000000005ca00000000000008c70000000000000cdf0000000000000be800000000000008280000000000000a3c0000000000000b9a000000000000033c00000000000005aa0000000000000668000000000000058d000000000000046d0000000000000921000000000000005200000000000003fd00000000000009f000000000000009c800000000000002b80000000000000750000000000000024600000000000000e600000000000007ff000000000000050a00000000000008130000000000000ab3000000000000034800000000000001070000000000000cd50000000000000ad5000000000000000f000000000000054b000000000000065f0000000000000b14000000000000067500000000000002150000000000000be500000000000004f400000000000007770000000000000c6400000000000003900000000000000a360000000000000bc40000000000000a85000000000000020b0000000000000cef000000000000071000000000000001740000000000000a310000000000000373000000000000013e0000000000000c680000000000000b5f0000000000000cf20000000000000b9c000000000000053900000000000001f4000000000000052e00000000000004b20000000000000a490000000000000b690000000000000c8d00000000000005020000000000000be7000000000000081e000000000000033f000000000000024f0000000000000820000000000000074500000000000003c80000000000000182000000000000089e00000000000008350000000000000399000000000000005d00000000000002b10000000000000ca0000000000000097400000000000003040000000000000a8800000000000007140000000000000475000000000000016700000000000006d2000000000000032800000000000009d40000000000000c1500000000000009cc000000000000016b0000000000000b17",
		},
		{
			Name: "NTT-Dilithium-256",
			Gas:  70000,
			Input: func() string {
				operation := "00"
				ringDegree := fmt.Sprintf("%08x", 256)
				modulus := fmt.Sprintf("%016x", 8380417)
				coeffs := ""
				for i := 1; i <= 256; i++ {
					coeffs += fmt.Sprintf("%016x", uint64(i)%8380417)
				}
				return operation + ringDegree + modulus + coeffs
			}(),
			Expected: "00000000004768f700000000006fd627000000000031579a0000000000401b0f000000000024b42400000000003eaa8e00000000002549f4000000000005811d0000000000307ec700000000002d6ba30000000000141b4400000000006c48b50000000000086cc100000000001336a700000000003f7f25000000000023edb100000000000307a10000000000298239000000000013becb0000000000229cca000000000062c96f0000000000255b2a000000000007feec0000000000187a800000000000148b6e000000000038fb8d00000000007881c300000000005188a6000000000073dc96000000000046207c00000000000c2ae6000000000060c3040000000000175427000000000064337700000000005db8cf0000000000200253000000000028312f000000000002e11500000000000d940c00000000000b740600000000005bdd17000000000058d4000000000000722e3c00000000006a8bf500000000002377200000000000413b6c00000000003aa12a00000000006a08a500000000006fb00c00000000006c62b20000000000026eb200000000003faf68000000000074b6750000000000775d810000000000698e31000000000074aed300000000002be95e000000000039d44600000000006ca4120000000000388aa800000000000a926000000000006691eb00000000007e964d00000000001b0fd3000000000050387c00000000005ee9c2000000000011b97600000000001e9e47000000000039a7dc00000000005415b2000000000056ce8c0000000000194f81000000000010953500000000003d760b00000000005de3f300000000001907c1000000000005c979000000000018f6720000000000763772000000000039e72d00000000003866f800000000005065b800000000004c03a700000000000867d5000000000023244700000000002d1289000000000068780800000000007ba48900000000004edaa00000000000514091000000000040c5f600000000004cd7a8000000000067f6a500000000002a48e900000000007383cd000000000066feb60000000000302e47000000000074f85d0000000000483ba500000000004334ea000000000014c6bb00000000006f7ca600000000002cb6f400000000000d83e600000000003b446000000000001d4eb8000000000023ba61000000000034eb38000000000058296300000000006c1331000000000041022c00000000002445980000000000122b96000000000071796600000000004eba3d00000000006964270000000000589a89000000000056707800000000006db015000000000059c60200000000007306120000000000096dca00000000001ae6bf000000000029e9dc00000000006269b800000000000a06a900000000002e890d00000000001d9f150000000000096b7a00000000000d2bcc000000000027f0d600000000002395f90000000000151f9e00000000001a01a100000000006dd6e300000000004b78c4000000000002622a000000000047d9c6000000000008b21700000000006501ec000000000054d160000000000017ce1e000000000053bd0d00000000006fb9c2000000000009f16600000000006d181600000000006490880000000000332365000000000077cee000000000004cf7f100000000005525fd000000000059054300000000005077ac00000000005ba878000000000019b65b000000000036a5130000000000676022000000000064c65f00000000007fccbf0000000000013932000000000042e576000000000053c84c00000000002e71ac00000000003bdafa000000000079e6c900000000006bb1b6000000000011b60d000000000003951e000000000041ae7c000000000024820a00000000007eb5a80000000000677b5000000000000775de00000000003c76090000000000311ff2000000000028952600000000005cfeef00000000000ee455000000000052606900000000006be427000000000042edfe000000000019c3ae00000000005a72a1000000000043b45f00000000006d20920000000000384bde000000000036989b000000000069759a00000000004364eb000000000018486e00000000001ce2bf00000000001dc2d500000000001427ec0000000000298065000000000004b6da000000000016ff05000000000004658f000000000069a0b00000000000196fe1000000000074617b00000000004fa6310000000000427a42000000000060ffe500000000003886f20000000000620a1d00000000005ca46600000000007023fe000000000015d6b3000000000015584100000000001b189f0000000000561e1800000000005009e700000000007b885e00000000002204bb00000000000b35bf0000000000463b19000000000022ada00000000000736c6d0000000000741d66000000000063820100000000001f52c7000000000038b54800000000007ef440000000000051b0f000000000002bc546000000000059367400000000005015fd000000000067895f0000000000620801000000000012ae2b000000000021f1d3000000000074823b0000000000287797000000000067d58400000000007a9c1f00000000004e8de700000000005371200000000000648ce000000000007e11a500000000007cbcee00000000007a127b000000000044f6b4000000000033661e000000000067464e000000000034e443000000000077d81300000000007f90a400000000002b72f100000000000bb9ee00000000002dc3aa000000000041adb600000000007c15970000000000582204000000000042d9c400000000002d90fe00000000005c796b",
		},
	}

	for _, test := range testCases {
		benchmarkPrecompiled("12", test, bench)
	}
}

// Benchmark NTT vectorized operations with crypto standards
func BenchmarkPrecompiledNTTVecOpsCryptoStandards(bench *testing.B) {
	testCases := []precompiledTest{
		{
			Name: "VECMULMOD-Falcon-512",
			Input: func() string {
				ringDegree := fmt.Sprintf("%08x", 512)
				modulus := fmt.Sprintf("%016x", 12289)
				vectorA := ""
				vectorB := ""
				for i := 1; i <= 512; i++ {
					vectorA += fmt.Sprintf("%016x", uint64(i)%12289)
					vectorB += fmt.Sprintf("%016x", uint64(i+1)%12289)
				}
				return ringDegree + modulus + vectorA + vectorB
			}(),
			Expected: "00000000000000020000000000000006000000000000000c0000000000000014000000000000001e000000000000002a00000000000000380000000000000048000000000000005a000000000000006e0000000000000084000000000000009c00000000000000b600000000000000d200000000000000f0000000000000011000000000000001320000000000000156000000000000017c00000000000001a400000000000001ce00000000000001fa00000000000002280000000000000258000000000000028a00000000000002be00000000000002f4000000000000032c000000000000036600000000000003a200000000000003e00000000000000420000000000000046200000000000004a600000000000004ec0000000000000534000000000000057e00000000000005ca0000000000000618000000000000066800000000000006ba000000000000070e000000000000076400000000000007bc0000000000000816000000000000087200000000000008d00000000000000930000000000000099200000000000009f60000000000000a5c0000000000000ac40000000000000b2e0000000000000b9a0000000000000c080000000000000c780000000000000cea0000000000000d5e0000000000000dd40000000000000e4c0000000000000ec60000000000000f420000000000000fc0000000000000104000000000000010c2000000000000114600000000000011cc000000000000125400000000000012de000000000000136a00000000000013f80000000000001488000000000000151a00000000000015ae000000000000164400000000000016dc0000000000001776000000000000181200000000000018b0000000000000195000000000000019f20000000000001a960000000000001b3c0000000000001be40000000000001c8e0000000000001d3a0000000000001de80000000000001e980000000000001f4a0000000000001ffe00000000000020b4000000000000216c000000000000222600000000000022e200000000000023a00000000000002460000000000000252200000000000025e600000000000026ac0000000000002774000000000000283e000000000000290a00000000000029d80000000000002aa80000000000002b7a0000000000002c4e0000000000002d240000000000002dfc0000000000002ed60000000000002fb2000000000000008f000000000000016f00000000000002510000000000000335000000000000041b000000000000050300000000000005ed00000000000006d900000000000007c700000000000008b700000000000009a90000000000000a9d0000000000000b930000000000000c8b0000000000000d850000000000000e810000000000000f7f000000000000107f00000000000011810000000000001285000000000000138b0000000000001493000000000000159d00000000000016a900000000000017b700000000000018c700000000000019d90000000000001aed0000000000001c030000000000001d1b0000000000001e350000000000001f51000000000000206f000000000000218f00000000000022b100000000000023d500000000000024fb0000000000002623000000000000274d000000000000287900000000000029a70000000000002ad70000000000002c090000000000002d3d0000000000002e730000000000002fab00000000000000e40000000000000220000000000000035e000000000000049e00000000000005e00000000000000724000000000000086a00000000000009b20000000000000afc0000000000000c480000000000000d960000000000000ee60000000000001038000000000000118c00000000000012e2000000000000143a000000000000159400000000000016f0000000000000184e00000000000019ae0000000000001b100000000000001c740000000000001dda0000000000001f4200000000000020ac0000000000002218000000000000238600000000000024f6000000000000266800000000000027dc00000000000029520000000000002aca0000000000002c440000000000002dc00000000000002f3e00000000000000bd000000000000023f00000000000003c3000000000000054900000000000006d1000000000000085b00000000000009e70000000000000b750000000000000d050000000000000e97000000000000102b00000000000011c1000000000000135900000000000014f3000000000000168f000000000000182d00000000000019cd0000000000001b6f0000000000001d130000000000001eb90000000000002061000000000000220b00000000000023b70000000000002565000000000000271500000000000028c70000000000002a7b0000000000002c310000000000002de90000000000002fa3000000000000015e000000000000031c00000000000004dc000000000000069e00000000000008620000000000000a280000000000000bf00000000000000dba0000000000000f860000000000001154000000000000132400000000000014f600000000000016ca00000000000018a00000000000001a780000000000001c520000000000001e2e000000000000200c00000000000021ec00000000000023ce00000000000025b2000000000000279800000000000029800000000000002b6a0000000000002d560000000000002f44000000000000013300000000000003250000000000000519000000000000070f00000000000009070000000000000b010000000000000cfd0000000000000efb00000000000010fb00000000000012fd00000000000015010000000000001707000000000000190f0000000000001b190000000000001d250000000000001f33000000000000214300000000000023550000000000002569000000000000277f00000000000029970000000000002bb10000000000002dcd0000000000002feb000000000000020a000000000000042c000000000000065000000000000008760000000000000a9e0000000000000cc80000000000000ef400000000000011220000000000001352000000000000158400000000000017b800000000000019ee0000000000001c260000000000001e60000000000000209c00000000000022da000000000000251a000000000000275c00000000000029a00000000000002be60000000000002e2e000000000000007700000000000002c30000000000000511000000000000076100000000000009b30000000000000c070000000000000e5d00000000000010b5000000000000130f000000000000156b00000000000017c90000000000001a290000000000001c8b0000000000001eef000000000000215500000000000023bd000000000000262700000000000028930000000000002b010000000000002d710000000000002fe3000000000000025600000000000004cc000000000000074400000000000009be0000000000000c3a0000000000000eb8000000000000113800000000000013ba000000000000163e00000000000018c40000000000001b4c0000000000001dd6000000000000206200000000000022f0000000000000258000000000000028120000000000002aa60000000000002d3c0000000000002fd4000000000000026d000000000000050900000000000007a70000000000000a470000000000000ce90000000000000f8d000000000000123300000000000014db00000000000017850000000000001a310000000000001cdf0000000000001f8f000000000000224100000000000024f500000000000027ab0000000000002a630000000000002d1d0000000000002fd90000000000000296000000000000055600000000000008180000000000000adc0000000000000da2000000000000106a0000000000001334000000000000160000000000000018ce0000000000001b9e0000000000001e700000000000002144000000000000241a00000000000026f200000000000029cc0000000000002ca80000000000002f8600000000000002650000000000000547000000000000082b0000000000000b110000000000000df900000000000010e300000000000013cf00000000000016bd00000000000019ad0000000000001c9f0000000000001f9300000000000022890000000000002581000000000000287b0000000000002b770000000000002e7500000000000001740000000000000476000000000000077a0000000000000a800000000000000d880000000000001092000000000000139e00000000000016ac00000000000019bc0000000000001cce0000000000001fe200000000000022f80000000000002610000000000000292a0000000000002c460000000000002f64000000000000028300000000000005a500000000000008c90000000000000bef0000000000000f170000000000001241000000000000156d000000000000189b0000000000001bcb0000000000001efd00000000000022310000000000002567000000000000289f0000000000002bd90000000000002f150000000000000252000000000000059200000000000008d40000000000000c180000000000000f5e00000000000012a600000000000015f0000000000000193c0000000000001c8a0000000000001fda000000000000232c000000000000268000000000000029d60000000000002d2e000000000000008700000000000003e300000000000007410000000000000aa10000000000000e03000000000000116700000000000014cd00000000000018350000000000001b9f0000000000001f0b000000000000227900000000000025e9000000000000295b0000000000002ccf000000000000004400000000000003bc00000000000007360000000000000ab20000000000000e3000000000000011b0000000000000153200000000000018b60000000000001c3c0000000000001fc4000000000000234e00000000000026da0000000000002a680000000000002df80000000000000189000000000000051d00000000000008b30000000000000c4b0000000000000fe50000000000001381000000000000171f0000000000001abf0000000000001e61000000000000220500000000000025ab00000000000029530000000000002cfd00000000000000a8000000000000045600000000000008060000000000000bb80000000000000f6c000000000000132200000000000016da0000000000001a940000000000001e50000000000000220e00000000000025ce00000000000029900000000000002d54000000000000011900000000000004e100000000000008ab0000000000000c770000000000001045000000000000141500000000000017e70000000000001bbb0000000000001f91000000000000236900000000000027430000000000002b1f0000000000002efd00000000000002dc00000000000006be0000000000000aa20000000000000e880000000000001270000000000000165a0000000000001a460000000000001e34000000000000222400000000000026160000000000002a0a0000000000002e0000000000000001f700000000000005f100000000000009ed0000000000000deb00000000000011eb",
		},
		{
			Name: "VECADDMOD-Falcon-512",
			Input: func() string {
				ringDegree := fmt.Sprintf("%08x", 512)
				modulus := fmt.Sprintf("%016x", 12289)
				vectorA := ""
				vectorB := ""
				for i := 1; i <= 512; i++ {
					vectorA += fmt.Sprintf("%016x", uint64(i)%12289)
					vectorB += fmt.Sprintf("%016x", uint64(i+1)%12289)
				}
				return ringDegree + modulus + vectorA + vectorB
			}(),
			Expected: "0000000000000003000000000000000500000000000000070000000000000009000000000000000b000000000000000d000000000000000f00000000000000110000000000000013000000000000001500000000000000170000000000000019000000000000001b000000000000001d000000000000001f00000000000000210000000000000023000000000000002500000000000000270000000000000029000000000000002b000000000000002d000000000000002f00000000000000310000000000000033000000000000003500000000000000370000000000000039000000000000003b000000000000003d000000000000003f00000000000000410000000000000043000000000000004500000000000000470000000000000049000000000000004b000000000000004d000000000000004f00000000000000510000000000000053000000000000005500000000000000570000000000000059000000000000005b000000000000005d000000000000005f00000000000000610000000000000063000000000000006500000000000000670000000000000069000000000000006b000000000000006d000000000000006f00000000000000710000000000000073000000000000007500000000000000770000000000000079000000000000007b000000000000007d000000000000007f00000000000000810000000000000083000000000000008500000000000000870000000000000089000000000000008b000000000000008d000000000000008f00000000000000910000000000000093000000000000009500000000000000970000000000000099000000000000009b000000000000009d000000000000009f00000000000000a100000000000000a300000000000000a500000000000000a700000000000000a900000000000000ab00000000000000ad00000000000000af00000000000000b100000000000000b300000000000000b500000000000000b700000000000000b900000000000000bb00000000000000bd00000000000000bf00000000000000c100000000000000c300000000000000c500000000000000c700000000000000c900000000000000cb00000000000000cd00000000000000cf00000000000000d100000000000000d300000000000000d500000000000000d700000000000000d900000000000000db00000000000000dd00000000000000df00000000000000e100000000000000e300000000000000e500000000000000e700000000000000e900000000000000eb00000000000000ed00000000000000ef00000000000000f100000000000000f300000000000000f500000000000000f700000000000000f900000000000000fb00000000000000fd00000000000000ff00000000000001010000000000000103000000000000010500000000000001070000000000000109000000000000010b000000000000010d000000000000010f00000000000001110000000000000113000000000000011500000000000001170000000000000119000000000000011b000000000000011d000000000000011f00000000000001210000000000000123000000000000012500000000000001270000000000000129000000000000012b000000000000012d000000000000012f00000000000001310000000000000133000000000000013500000000000001370000000000000139000000000000013b000000000000013d000000000000013f00000000000001410000000000000143000000000000014500000000000001470000000000000149000000000000014b000000000000014d000000000000014f00000000000001510000000000000153000000000000015500000000000001570000000000000159000000000000015b000000000000015d000000000000015f00000000000001610000000000000163000000000000016500000000000001670000000000000169000000000000016b000000000000016d000000000000016f00000000000001710000000000000173000000000000017500000000000001770000000000000179000000000000017b000000000000017d000000000000017f00000000000001810000000000000183000000000000018500000000000001870000000000000189000000000000018b000000000000018d000000000000018f00000000000001910000000000000193000000000000019500000000000001970000000000000199000000000000019b000000000000019d000000000000019f00000000000001a100000000000001a300000000000001a500000000000001a700000000000001a900000000000001ab00000000000001ad00000000000001af00000000000001b100000000000001b300000000000001b500000000000001b700000000000001b900000000000001bb00000000000001bd00000000000001bf00000000000001c100000000000001c300000000000001c500000000000001c700000000000001c900000000000001cb00000000000001cd00000000000001cf00000000000001d100000000000001d300000000000001d500000000000001d700000000000001d900000000000001db00000000000001dd00000000000001df00000000000001e100000000000001e300000000000001e500000000000001e700000000000001e900000000000001eb00000000000001ed00000000000001ef00000000000001f100000000000001f300000000000001f500000000000001f700000000000001f900000000000001fb00000000000001fd00000000000001ff00000000000002010000000000000203000000000000020500000000000002070000000000000209000000000000020b000000000000020d000000000000020f00000000000002110000000000000213000000000000021500000000000002170000000000000219000000000000021b000000000000021d000000000000021f00000000000002210000000000000223000000000000022500000000000002270000000000000229000000000000022b000000000000022d000000000000022f00000000000002310000000000000233000000000000023500000000000002370000000000000239000000000000023b000000000000023d000000000000023f00000000000002410000000000000243000000000000024500000000000002470000000000000249000000000000024b000000000000024d000000000000024f00000000000002510000000000000253000000000000025500000000000002570000000000000259000000000000025b000000000000025d000000000000025f00000000000002610000000000000263000000000000026500000000000002670000000000000269000000000000026b000000000000026d000000000000026f00000000000002710000000000000273000000000000027500000000000002770000000000000279000000000000027b000000000000027d000000000000027f00000000000002810000000000000283000000000000028500000000000002870000000000000289000000000000028b000000000000028d000000000000028f00000000000002910000000000000293000000000000029500000000000002970000000000000299000000000000029b000000000000029d000000000000029f00000000000002a100000000000002a300000000000002a500000000000002a700000000000002a900000000000002ab00000000000002ad00000000000002af00000000000002b100000000000002b300000000000002b500000000000002b700000000000002b900000000000002bb00000000000002bd00000000000002bf00000000000002c100000000000002c300000000000002c500000000000002c700000000000002c900000000000002cb00000000000002cd00000000000002cf00000000000002d100000000000002d300000000000002d500000000000002d700000000000002d900000000000002db00000000000002dd00000000000002df00000000000002e100000000000002e300000000000002e500000000000002e700000000000002e900000000000002eb00000000000002ed00000000000002ef00000000000002f100000000000002f300000000000002f500000000000002f700000000000002f900000000000002fb00000000000002fd00000000000002ff00000000000003010000000000000303000000000000030500000000000003070000000000000309000000000000030b000000000000030d000000000000030f00000000000003110000000000000313000000000000031500000000000003170000000000000319000000000000031b000000000000031d000000000000031f00000000000003210000000000000323000000000000032500000000000003270000000000000329000000000000032b000000000000032d000000000000032f00000000000003310000000000000333000000000000033500000000000003370000000000000339000000000000033b000000000000033d000000000000033f00000000000003410000000000000343000000000000034500000000000003470000000000000349000000000000034b000000000000034d000000000000034f00000000000003510000000000000353000000000000035500000000000003570000000000000359000000000000035b000000000000035d000000000000035f00000000000003610000000000000363000000000000036500000000000003670000000000000369000000000000036b000000000000036d000000000000036f00000000000003710000000000000373000000000000037500000000000003770000000000000379000000000000037b000000000000037d000000000000037f00000000000003810000000000000383000000000000038500000000000003870000000000000389000000000000038b000000000000038d000000000000038f00000000000003910000000000000393000000000000039500000000000003970000000000000399000000000000039b000000000000039d000000000000039f00000000000003a100000000000003a300000000000003a500000000000003a700000000000003a900000000000003ab00000000000003ad00000000000003af00000000000003b100000000000003b300000000000003b500000000000003b700000000000003b900000000000003bb00000000000003bd00000000000003bf00000000000003c100000000000003c300000000000003c500000000000003c700000000000003c900000000000003cb00000000000003cd00000000000003cf00000000000003d100000000000003d300000000000003d500000000000003d700000000000003d900000000000003db00000000000003dd00000000000003df00000000000003e100000000000003e300000000000003e500000000000003e700000000000003e900000000000003eb00000000000003ed00000000000003ef00000000000003f100000000000003f300000000000003f500000000000003f700000000000003f900000000000003fb00000000000003fd00000000000003ff0000000000000401",
		},
		{
			Name: "VECMULMOD-Kyber-128",
			Input: func() string {
				ringDegree := fmt.Sprintf("%08x", 128)
				modulus := fmt.Sprintf("%016x", 3329)
				vectorA := ""
				vectorB := ""
				for i := 1; i <= 128; i++ {
					vectorA += fmt.Sprintf("%016x", uint64(i)%3329)
					vectorB += fmt.Sprintf("%016x", uint64(i+1)%3329)
				}
				return ringDegree + modulus + vectorA + vectorB
			}(),
			Expected: "00000000000000020000000000000006000000000000000c0000000000000014000000000000001e000000000000002a00000000000000380000000000000048000000000000005a000000000000006e0000000000000084000000000000009c00000000000000b600000000000000d200000000000000f0000000000000011000000000000001320000000000000156000000000000017c00000000000001a400000000000001ce00000000000001fa00000000000002280000000000000258000000000000028a00000000000002be00000000000002f4000000000000032c000000000000036600000000000003a200000000000003e00000000000000420000000000000046200000000000004a600000000000004ec0000000000000534000000000000057e00000000000005ca0000000000000618000000000000066800000000000006ba000000000000070e000000000000076400000000000007bc0000000000000816000000000000087200000000000008d00000000000000930000000000000099200000000000009f60000000000000a5c0000000000000ac40000000000000b2e0000000000000b9a0000000000000c080000000000000c780000000000000cea000000000000005d00000000000000d3000000000000014b00000000000001c5000000000000024100000000000002bf000000000000033f00000000000003c1000000000000044500000000000004cb000000000000055300000000000005dd000000000000066900000000000006f70000000000000787000000000000081900000000000008ad000000000000094300000000000009db0000000000000a750000000000000b110000000000000baf0000000000000c4f0000000000000cf10000000000000094000000000000013a00000000000001e2000000000000028c000000000000033800000000000003e60000000000000496000000000000054800000000000005fc00000000000006b2000000000000076a000000000000082400000000000008e0000000000000099e0000000000000a5e0000000000000b200000000000000be40000000000000caa0000000000000071000000000000013b000000000000020700000000000002d500000000000003a50000000000000477000000000000054b000000000000062100000000000006f900000000000007d300000000000008af000000000000098d0000000000000a6d0000000000000b4f0000000000000c330000000000000018000000000000010000000000000001ea00000000000002d600000000000003c400000000000004b400000000000005a6000000000000069a0000000000000790000000000000088800000000000009820000000000000a7e0000000000000b7c0000000000000c7c",
		},
		{
			Name: "VECADDMOD-Kyber-128",
			Input: func() string {
				ringDegree := fmt.Sprintf("%08x", 128)
				modulus := fmt.Sprintf("%016x", 3329)
				vectorA := ""
				vectorB := ""
				for i := 1; i <= 128; i++ {
					vectorA += fmt.Sprintf("%016x", uint64(i)%3329)
					vectorB += fmt.Sprintf("%016x", uint64(i+1)%3329)
				}
				return ringDegree + modulus + vectorA + vectorB
			}(),
			Expected: "0000000000000003000000000000000500000000000000070000000000000009000000000000000b000000000000000d000000000000000f00000000000000110000000000000013000000000000001500000000000000170000000000000019000000000000001b000000000000001d000000000000001f00000000000000210000000000000023000000000000002500000000000000270000000000000029000000000000002b000000000000002d000000000000002f00000000000000310000000000000033000000000000003500000000000000370000000000000039000000000000003b000000000000003d000000000000003f00000000000000410000000000000043000000000000004500000000000000470000000000000049000000000000004b000000000000004d000000000000004f00000000000000510000000000000053000000000000005500000000000000570000000000000059000000000000005b000000000000005d000000000000005f00000000000000610000000000000063000000000000006500000000000000670000000000000069000000000000006b000000000000006d000000000000006f00000000000000710000000000000073000000000000007500000000000000770000000000000079000000000000007b000000000000007d000000000000007f00000000000000810000000000000083000000000000008500000000000000870000000000000089000000000000008b000000000000008d000000000000008f00000000000000910000000000000093000000000000009500000000000000970000000000000099000000000000009b000000000000009d000000000000009f00000000000000a100000000000000a300000000000000a500000000000000a700000000000000a900000000000000ab00000000000000ad00000000000000af00000000000000b100000000000000b300000000000000b500000000000000b700000000000000b900000000000000bb00000000000000bd00000000000000bf00000000000000c100000000000000c300000000000000c500000000000000c700000000000000c900000000000000cb00000000000000cd00000000000000cf00000000000000d100000000000000d300000000000000d500000000000000d700000000000000d900000000000000db00000000000000dd00000000000000df00000000000000e100000000000000e300000000000000e500000000000000e700000000000000e900000000000000eb00000000000000ed00000000000000ef00000000000000f100000000000000f300000000000000f500000000000000f700000000000000f900000000000000fb00000000000000fd00000000000000ff0000000000000101",
		},
		{
			Name: "VECMULMOD-Dilithium-256",
			Input: func() string {
				ringDegree := fmt.Sprintf("%08x", 256)
				modulus := fmt.Sprintf("%016x", 8380417)
				vectorA := ""
				vectorB := ""
				for i := 1; i <= 256; i++ {
					vectorA += fmt.Sprintf("%016x", uint64(i)%8380417)
					vectorB += fmt.Sprintf("%016x", uint64(i+1)%8380417)
				}
				return ringDegree + modulus + vectorA + vectorB
			}(),
			Expected: "00000000000000020000000000000006000000000000000c0000000000000014000000000000001e000000000000002a00000000000000380000000000000048000000000000005a000000000000006e0000000000000084000000000000009c00000000000000b600000000000000d200000000000000f0000000000000011000000000000001320000000000000156000000000000017c00000000000001a400000000000001ce00000000000001fa00000000000002280000000000000258000000000000028a00000000000002be00000000000002f4000000000000032c000000000000036600000000000003a200000000000003e00000000000000420000000000000046200000000000004a600000000000004ec0000000000000534000000000000057e00000000000005ca0000000000000618000000000000066800000000000006ba000000000000070e000000000000076400000000000007bc0000000000000816000000000000087200000000000008d00000000000000930000000000000099200000000000009f60000000000000a5c0000000000000ac40000000000000b2e0000000000000b9a0000000000000c080000000000000c780000000000000cea0000000000000d5e0000000000000dd40000000000000e4c0000000000000ec60000000000000f420000000000000fc0000000000000104000000000000010c2000000000000114600000000000011cc000000000000125400000000000012de000000000000136a00000000000013f80000000000001488000000000000151a00000000000015ae000000000000164400000000000016dc0000000000001776000000000000181200000000000018b0000000000000195000000000000019f20000000000001a960000000000001b3c0000000000001be40000000000001c8e0000000000001d3a0000000000001de80000000000001e980000000000001f4a0000000000001ffe00000000000020b4000000000000216c000000000000222600000000000022e200000000000023a00000000000002460000000000000252200000000000025e600000000000026ac0000000000002774000000000000283e000000000000290a00000000000029d80000000000002aa80000000000002b7a0000000000002c4e0000000000002d240000000000002dfc0000000000002ed60000000000002fb20000000000003090000000000000317000000000000032520000000000003336000000000000341c000000000000350400000000000035ee00000000000036da00000000000037c800000000000038b800000000000039aa0000000000003a9e0000000000003b940000000000003c8c0000000000003d860000000000003e820000000000003f80000000000000408000000000000041820000000000004286000000000000438c0000000000004494000000000000459e00000000000046aa00000000000047b800000000000048c800000000000049da0000000000004aee0000000000004c040000000000004d1c0000000000004e360000000000004f520000000000005070000000000000519000000000000052b200000000000053d600000000000054fc0000000000005624000000000000574e000000000000587a00000000000059a80000000000005ad80000000000005c0a0000000000005d3e0000000000005e740000000000005fac00000000000060e60000000000006222000000000000636000000000000064a000000000000065e20000000000006726000000000000686c00000000000069b40000000000006afe0000000000006c4a0000000000006d980000000000006ee8000000000000703a000000000000718e00000000000072e4000000000000743c000000000000759600000000000076f2000000000000785000000000000079b00000000000007b120000000000007c760000000000007ddc0000000000007f4400000000000080ae000000000000821a000000000000838800000000000084f8000000000000866a00000000000087de00000000000089540000000000008acc0000000000008c460000000000008dc20000000000008f4000000000000090c0000000000000924200000000000093c6000000000000954c00000000000096d4000000000000985e00000000000099ea0000000000009b780000000000009d080000000000009e9a000000000000a02e000000000000a1c4000000000000a35c000000000000a4f6000000000000a692000000000000a830000000000000a9d0000000000000ab72000000000000ad16000000000000aebc000000000000b064000000000000b20e000000000000b3ba000000000000b568000000000000b718000000000000b8ca000000000000ba7e000000000000bc34000000000000bdec000000000000bfa6000000000000c162000000000000c320000000000000c4e0000000000000c6a2000000000000c866000000000000ca2c000000000000cbf4000000000000cdbe000000000000cf8a000000000000d158000000000000d328000000000000d4fa000000000000d6ce000000000000d8a4000000000000da7c000000000000dc56000000000000de32000000000000e010000000000000e1f0000000000000e3d2000000000000e5b6000000000000e79c000000000000e984000000000000eb6e000000000000ed5a000000000000ef48000000000000f138000000000000f32a000000000000f51e000000000000f714000000000000f90c000000000000fb06000000000000fd02000000000000ff000000000000010100",
		},
		{
			Name: "VECADDMOD-Dilithium-256",
			Input: func() string {
				ringDegree := fmt.Sprintf("%08x", 256)
				modulus := fmt.Sprintf("%016x", 8380417)
				vectorA := ""
				vectorB := ""
				for i := 1; i <= 256; i++ {
					vectorA += fmt.Sprintf("%016x", uint64(i)%8380417)
					vectorB += fmt.Sprintf("%016x", uint64(i+1)%8380417)
				}
				return ringDegree + modulus + vectorA + vectorB
			}(),
			Expected: "0000000000000003000000000000000500000000000000070000000000000009000000000000000b000000000000000d000000000000000f00000000000000110000000000000013000000000000001500000000000000170000000000000019000000000000001b000000000000001d000000000000001f00000000000000210000000000000023000000000000002500000000000000270000000000000029000000000000002b000000000000002d000000000000002f00000000000000310000000000000033000000000000003500000000000000370000000000000039000000000000003b000000000000003d000000000000003f00000000000000410000000000000043000000000000004500000000000000470000000000000049000000000000004b000000000000004d000000000000004f00000000000000510000000000000053000000000000005500000000000000570000000000000059000000000000005b000000000000005d000000000000005f00000000000000610000000000000063000000000000006500000000000000670000000000000069000000000000006b000000000000006d000000000000006f00000000000000710000000000000073000000000000007500000000000000770000000000000079000000000000007b000000000000007d000000000000007f00000000000000810000000000000083000000000000008500000000000000870000000000000089000000000000008b000000000000008d000000000000008f00000000000000910000000000000093000000000000009500000000000000970000000000000099000000000000009b000000000000009d000000000000009f00000000000000a100000000000000a300000000000000a500000000000000a700000000000000a900000000000000ab00000000000000ad00000000000000af00000000000000b100000000000000b300000000000000b500000000000000b700000000000000b900000000000000bb00000000000000bd00000000000000bf00000000000000c100000000000000c300000000000000c500000000000000c700000000000000c900000000000000cb00000000000000cd00000000000000cf00000000000000d100000000000000d300000000000000d500000000000000d700000000000000d900000000000000db00000000000000dd00000000000000df00000000000000e100000000000000e300000000000000e500000000000000e700000000000000e900000000000000eb00000000000000ed00000000000000ef00000000000000f100000000000000f300000000000000f500000000000000f700000000000000f900000000000000fb00000000000000fd00000000000000ff00000000000001010000000000000103000000000000010500000000000001070000000000000109000000000000010b000000000000010d000000000000010f00000000000001110000000000000113000000000000011500000000000001170000000000000119000000000000011b000000000000011d000000000000011f00000000000001210000000000000123000000000000012500000000000001270000000000000129000000000000012b000000000000012d000000000000012f00000000000001310000000000000133000000000000013500000000000001370000000000000139000000000000013b000000000000013d000000000000013f00000000000001410000000000000143000000000000014500000000000001470000000000000149000000000000014b000000000000014d000000000000014f00000000000001510000000000000153000000000000015500000000000001570000000000000159000000000000015b000000000000015d000000000000015f00000000000001610000000000000163000000000000016500000000000001670000000000000169000000000000016b000000000000016d000000000000016f00000000000001710000000000000173000000000000017500000000000001770000000000000179000000000000017b000000000000017d000000000000017f00000000000001810000000000000183000000000000018500000000000001870000000000000189000000000000018b000000000000018d000000000000018f00000000000001910000000000000193000000000000019500000000000001970000000000000199000000000000019b000000000000019d000000000000019f00000000000001a100000000000001a300000000000001a500000000000001a700000000000001a900000000000001ab00000000000001ad00000000000001af00000000000001b100000000000001b300000000000001b500000000000001b700000000000001b900000000000001bb00000000000001bd00000000000001bf00000000000001c100000000000001c300000000000001c500000000000001c700000000000001c900000000000001cb00000000000001cd00000000000001cf00000000000001d100000000000001d300000000000001d500000000000001d700000000000001d900000000000001db00000000000001dd00000000000001df00000000000001e100000000000001e300000000000001e500000000000001e700000000000001e900000000000001eb00000000000001ed00000000000001ef00000000000001f100000000000001f300000000000001f500000000000001f700000000000001f900000000000001fb00000000000001fd00000000000001ff0000000000000201",
		},
	}

	for _, test := range testCases {
		addr := "13" // VECMULMOD
		if strings.Contains(test.Name, "VECADDMOD") {
			addr = "14" // VECADDMOD
		}
		benchmarkPrecompiled(addr, test, bench)
	}
}
