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
	"encoding/binary"
	"encoding/json"
	"fmt"
	"os"
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

	common.BytesToAddress([]byte{0x01, 0x00}): &p256VerifyFjord{},

	common.BytesToAddress([]byte{0x12}): &NTT_FW{},
	common.BytesToAddress([]byte{0x13}): &NTT_INV{},
	common.BytesToAddress([]byte{0x14}): &NTT_VECMULMOD{},
	common.BytesToAddress([]byte{0x15}): &NTT_VECADDMOD{},

	common.BytesToAddress([]byte{0x2f, 0x08}): &bn256PairingJovian{},
	common.BytesToAddress([]byte{0x2f, 0x0e}): &bls12381PairingJovian{},
	common.BytesToAddress([]byte{0x2f, 0x0b}): &bls12381G1MultiExpJovian{},
	common.BytesToAddress([]byte{0x2f, 0x0d}): &bls12381G2MultiExpJovian{},
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

// TestPrecompiledNTTMalformedInput tests NTT precompiles handle invalid inputs correctly
func TestPrecompiledNTTMalformedInput(t *testing.T) {
	// NTT malformed input test vectors
	var nttMalformedInputTests = []precompiledFailureTest{
		{
			Input:         "",
			ExpectedError: "input too short: minimum 12 bytes required",
			Name:          "empty input",
		},
		{
			Input:         "00000000",
			ExpectedError: "input too short: minimum 12 bytes required",
			Name:          "too short input",
		},
		{
			// ringDegree=16, modulus=97
			Input:         "00000010000000000000006100000000000000010000000000000002",
			ExpectedError: "unsupported parameters: ringDegree=16, modulus=97 (only Falcon-512/1024 and ML-DSA supported)",
			Name:          "unsupported parameters",
		},
		{
			// Falcon-512: ringDegree=512, modulus=12289, but only 3 uint16 coefficients (should be 512)
			Input:         "000002000000000000003001000100020003",
			ExpectedError: "invalid coefficient data length for Falcon: expected 1024 bytes, got 6",
			Name:          "invalid coefficient data length for Falcon",
		},
		{
			// ML-DSA: ringDegree=256, modulus=8380417, but only 3 uint32 coefficients (should be 256)
			Input:         "0000010000000000007fe001000000010000000200000003",
			ExpectedError: "invalid coefficient data length for ML-DSA: expected 1024 bytes, got 12",
			Name:          "invalid coefficient data length for ML-DSA",
		},
	}

	// Test NTT_FW (0x12) malformed inputs
	t.Run("NTT_FW", func(t *testing.T) {
		for _, test := range nttMalformedInputTests {
			testPrecompiledFailure("12", test, t)
		}
	})

	// Test NTT_INV (0x13) malformed inputs
	t.Run("NTT_INV", func(t *testing.T) {
		for _, test := range nttMalformedInputTests {
			testPrecompiledFailure("13", test, t)
		}
	})
}

// Test NTT precompile with valid inputs
func TestPrecompiledNTT(t *testing.T) {
	t.Run("NTT_FW", func(t *testing.T) {
		t.Run("Falcon-512", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("12")]
			in := common.Hex2Bytes("000002000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200")
			gas := p.RequiredGas(in)

			if gas != 790 {
				t.Errorf("Expected gas 790, got %d", gas)
			}

			_, _, err := RunPrecompiledContract(p, in, gas, nil)
			if err != nil {
				t.Errorf("Failed to run NTT_FW Falcon-512: %v", err)
			}
		})

		t.Run("Falcon-1024", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("12")]
			in := common.Hex2Bytes("000004000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200020102020203020402050206020702080209020a020b020c020d020e020f0210021102120213021402150216021702180219021a021b021c021d021e021f0220022102220223022402250226022702280229022a022b022c022d022e022f0230023102320233023402350236023702380239023a023b023c023d023e023f0240024102420243024402450246024702480249024a024b024c024d024e024f0250025102520253025402550256025702580259025a025b025c025d025e025f0260026102620263026402650266026702680269026a026b026c026d026e026f0270027102720273027402750276027702780279027a027b027c027d027e027f0280028102820283028402850286028702880289028a028b028c028d028e028f0290029102920293029402950296029702980299029a029b029c029d029e029f02a002a102a202a302a402a502a602a702a802a902aa02ab02ac02ad02ae02af02b002b102b202b302b402b502b602b702b802b902ba02bb02bc02bd02be02bf02c002c102c202c302c402c502c602c702c802c902ca02cb02cc02cd02ce02cf02d002d102d202d302d402d502d602d702d802d902da02db02dc02dd02de02df02e002e102e202e302e402e502e602e702e802e902ea02eb02ec02ed02ee02ef02f002f102f202f302f402f502f602f702f802f902fa02fb02fc02fd02fe02ff0300030103020303030403050306030703080309030a030b030c030d030e030f0310031103120313031403150316031703180319031a031b031c031d031e031f0320032103220323032403250326032703280329032a032b032c032d032e032f0330033103320333033403350336033703380339033a033b033c033d033e033f0340034103420343034403450346034703480349034a034b034c034d034e034f0350035103520353035403550356035703580359035a035b035c035d035e035f0360036103620363036403650366036703680369036a036b036c036d036e036f0370037103720373037403750376037703780379037a037b037c037d037e037f0380038103820383038403850386038703880389038a038b038c038d038e038f0390039103920393039403950396039703980399039a039b039c039d039e039f03a003a103a203a303a403a503a603a703a803a903aa03ab03ac03ad03ae03af03b003b103b203b303b403b503b603b703b803b903ba03bb03bc03bd03be03bf03c003c103c203c303c403c503c603c703c803c903ca03cb03cc03cd03ce03cf03d003d103d203d303d403d503d603d703d803d903da03db03dc03dd03de03df03e003e103e203e303e403e503e603e703e803e903ea03eb03ec03ed03ee03ef03f003f103f203f303f403f503f603f703f803f903fa03fb03fc03fd03fe03ff0400")
			gas := p.RequiredGas(in)

			if gas != 1750 {
				t.Errorf("Expected gas 1750, got %d", gas)
			}

			_, _, err := RunPrecompiledContract(p, in, gas, nil)
			if err != nil {
				t.Errorf("Failed to run NTT_FW Falcon-1024: %v", err)
			}
		})

		t.Run("ML-DSA", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("12")]
			in := common.Hex2Bytes("0000010000000000007fe0010000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000100000001100000012000000130000001400000015000000160000001700000018000000190000001a0000001b0000001c0000001d0000001e0000001f000000200000002100000022000000230000002400000025000000260000002700000028000000290000002a0000002b0000002c0000002d0000002e0000002f000000300000003100000032000000330000003400000035000000360000003700000038000000390000003a0000003b0000003c0000003d0000003e0000003f000000400000004100000042000000430000004400000045000000460000004700000048000000490000004a0000004b0000004c0000004d0000004e0000004f000000500000005100000052000000530000005400000055000000560000005700000058000000590000005a0000005b0000005c0000005d0000005e0000005f000000600000006100000062000000630000006400000065000000660000006700000068000000690000006a0000006b0000006c0000006d0000006e0000006f000000700000007100000072000000730000007400000075000000760000007700000078000000790000007a0000007b0000007c0000007d0000007e0000007f000000800000008100000082000000830000008400000085000000860000008700000088000000890000008a0000008b0000008c0000008d0000008e0000008f000000900000009100000092000000930000009400000095000000960000009700000098000000990000009a0000009b0000009c0000009d0000009e0000009f000000a0000000a1000000a2000000a3000000a4000000a5000000a6000000a7000000a8000000a9000000aa000000ab000000ac000000ad000000ae000000af000000b0000000b1000000b2000000b3000000b4000000b5000000b6000000b7000000b8000000b9000000ba000000bb000000bc000000bd000000be000000bf000000c0000000c1000000c2000000c3000000c4000000c5000000c6000000c7000000c8000000c9000000ca000000cb000000cc000000cd000000ce000000cf000000d0000000d1000000d2000000d3000000d4000000d5000000d6000000d7000000d8000000d9000000da000000db000000dc000000dd000000de000000df000000e0000000e1000000e2000000e3000000e4000000e5000000e6000000e7000000e8000000e9000000ea000000eb000000ec000000ed000000ee000000ef000000f0000000f1000000f2000000f3000000f4000000f5000000f6000000f7000000f8000000f9000000fa000000fb000000fc000000fd000000fe000000ff00000100")
			gas := p.RequiredGas(in)

			if gas != 220 {
				t.Errorf("Expected gas 220, got %d", gas)
			}

			_, _, err := RunPrecompiledContract(p, in, gas, nil)
			if err != nil {
				t.Errorf("Failed to run NTT_FW ML-DSA: %v", err)
			}
		})
	})

	t.Run("NTT_INV_Roundtrip", func(t *testing.T) {
		// Test roundtrip: original -> NTT_FW -> NTT_INV -> should equal original
		t.Run("Falcon-512", func(t *testing.T) {
			original := common.Hex2Bytes("000002000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200")

			// Save original coefficient data before any modifications
			originalCoeffs := make([]byte, len(original)-12)
			copy(originalCoeffs, original[12:])

			// Step 1: Run NTT_FW
			pFW := allPrecompiles[common.HexToAddress("12")]
			gasFW := pFW.RequiredGas(original)
			fwResult, _, err := RunPrecompiledContract(pFW, original, gasFW, nil)
			if err != nil {
				t.Fatalf("NTT_FW failed: %v", err)
			}

			// Step 2: Prepend header to NTT_FW result for NTT_INV input
			// NTT_FW returns only coefficients, NTT_INV needs header + coefficients
			invInput := append(original[:12:12], fwResult...) // Use full slice expression to prevent corruption

			// Step 3: Run NTT_INV on the result
			pINV := allPrecompiles[common.HexToAddress("13")]
			gasINV := pINV.RequiredGas(invInput)
			invResult, _, err := RunPrecompiledContract(pINV, invInput, gasINV, nil)
			if err != nil {
				t.Fatalf("NTT_INV failed: %v", err)
			}

			// Step 4: Verify roundtrip (compare saved coefficient data)
			if !bytes.Equal(originalCoeffs, invResult) {
				t.Errorf("Roundtrip failed: original coefficients != NTT_INV(NTT_FW(original))")
				t.Errorf("Original coeff length: %d, Result length: %d", len(originalCoeffs), len(invResult))
			}
		})

		t.Run("Falcon-1024", func(t *testing.T) {
			original := common.Hex2Bytes("000004000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200020102020203020402050206020702080209020a020b020c020d020e020f0210021102120213021402150216021702180219021a021b021c021d021e021f0220022102220223022402250226022702280229022a022b022c022d022e022f0230023102320233023402350236023702380239023a023b023c023d023e023f0240024102420243024402450246024702480249024a024b024c024d024e024f0250025102520253025402550256025702580259025a025b025c025d025e025f0260026102620263026402650266026702680269026a026b026c026d026e026f0270027102720273027402750276027702780279027a027b027c027d027e027f0280028102820283028402850286028702880289028a028b028c028d028e028f0290029102920293029402950296029702980299029a029b029c029d029e029f02a002a102a202a302a402a502a602a702a802a902aa02ab02ac02ad02ae02af02b002b102b202b302b402b502b602b702b802b902ba02bb02bc02bd02be02bf02c002c102c202c302c402c502c602c702c802c902ca02cb02cc02cd02ce02cf02d002d102d202d302d402d502d602d702d802d902da02db02dc02dd02de02df02e002e102e202e302e402e502e602e702e802e902ea02eb02ec02ed02ee02ef02f002f102f202f302f402f502f602f702f802f902fa02fb02fc02fd02fe02ff0300030103020303030403050306030703080309030a030b030c030d030e030f0310031103120313031403150316031703180319031a031b031c031d031e031f0320032103220323032403250326032703280329032a032b032c032d032e032f0330033103320333033403350336033703380339033a033b033c033d033e033f0340034103420343034403450346034703480349034a034b034c034d034e034f0350035103520353035403550356035703580359035a035b035c035d035e035f0360036103620363036403650366036703680369036a036b036c036d036e036f0370037103720373037403750376037703780379037a037b037c037d037e037f0380038103820383038403850386038703880389038a038b038c038d038e038f0390039103920393039403950396039703980399039a039b039c039d039e039f03a003a103a203a303a403a503a603a703a803a903aa03ab03ac03ad03ae03af03b003b103b203b303b403b503b603b703b803b903ba03bb03bc03bd03be03bf03c003c103c203c303c403c503c603c703c803c903ca03cb03cc03cd03ce03cf03d003d103d203d303d403d503d603d703d803d903da03db03dc03dd03de03df03e003e103e203e303e403e503e603e703e803e903ea03eb03ec03ed03ee03ef03f003f103f203f303f403f503f603f703f803f903fa03fb03fc03fd03fe03ff0400")

			// Save original coefficient data before any modifications
			originalCoeffs := make([]byte, len(original)-12)
			copy(originalCoeffs, original[12:])

			// Step 1: Run NTT_FW
			pFW := allPrecompiles[common.HexToAddress("12")]
			gasFW := pFW.RequiredGas(original)
			fwResult, _, err := RunPrecompiledContract(pFW, original, gasFW, nil)
			if err != nil {
				t.Fatalf("NTT_FW failed: %v", err)
			}

			// Step 2: Prepend header to NTT_FW result for NTT_INV input
			invInput := append(original[:12:12], fwResult...)

			// Step 3: Run NTT_INV on the result
			pINV := allPrecompiles[common.HexToAddress("13")]
			gasINV := pINV.RequiredGas(invInput)
			invResult, _, err := RunPrecompiledContract(pINV, invInput, gasINV, nil)
			if err != nil {
				t.Fatalf("NTT_INV failed: %v", err)
			}

			// Step 4: Verify roundtrip (compare saved coefficient data)
			if !bytes.Equal(originalCoeffs, invResult) {
				t.Errorf("Roundtrip failed: original coefficients != NTT_INV(NTT_FW(original))")
				t.Errorf("Original coeff length: %d, Result length: %d", len(originalCoeffs), len(invResult))
			}
		})

		t.Run("ML-DSA", func(t *testing.T) {
			original := common.Hex2Bytes("0000010000000000007fe0010000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000100000001100000012000000130000001400000015000000160000001700000018000000190000001a0000001b0000001c0000001d0000001e0000001f000000200000002100000022000000230000002400000025000000260000002700000028000000290000002a0000002b0000002c0000002d0000002e0000002f000000300000003100000032000000330000003400000035000000360000003700000038000000390000003a0000003b0000003c0000003d0000003e0000003f000000400000004100000042000000430000004400000045000000460000004700000048000000490000004a0000004b0000004c0000004d0000004e0000004f000000500000005100000052000000530000005400000055000000560000005700000058000000590000005a0000005b0000005c0000005d0000005e0000005f000000600000006100000062000000630000006400000065000000660000006700000068000000690000006a0000006b0000006c0000006d0000006e0000006f000000700000007100000072000000730000007400000075000000760000007700000078000000790000007a0000007b0000007c0000007d0000007e0000007f000000800000008100000082000000830000008400000085000000860000008700000088000000890000008a0000008b0000008c0000008d0000008e0000008f000000900000009100000092000000930000009400000095000000960000009700000098000000990000009a0000009b0000009c0000009d0000009e0000009f000000a0000000a1000000a2000000a3000000a4000000a5000000a6000000a7000000a8000000a9000000aa000000ab000000ac000000ad000000ae000000af000000b0000000b1000000b2000000b3000000b4000000b5000000b6000000b7000000b8000000b9000000ba000000bb000000bc000000bd000000be000000bf000000c0000000c1000000c2000000c3000000c4000000c5000000c6000000c7000000c8000000c9000000ca000000cb000000cc000000cd000000ce000000cf000000d0000000d1000000d2000000d3000000d4000000d5000000d6000000d7000000d8000000d9000000da000000db000000dc000000dd000000de000000df000000e0000000e1000000e2000000e3000000e4000000e5000000e6000000e7000000e8000000e9000000ea000000eb000000ec000000ed000000ee000000ef000000f0000000f1000000f2000000f3000000f4000000f5000000f6000000f7000000f8000000f9000000fa000000fb000000fc000000fd000000fe000000ff00000100")

			// Save original coefficient data before any modifications
			originalCoeffs := make([]byte, len(original)-12)
			copy(originalCoeffs, original[12:])

			// Step 1: Run NTT_FW
			pFW := allPrecompiles[common.HexToAddress("12")]
			gasFW := pFW.RequiredGas(original)
			fwResult, _, err := RunPrecompiledContract(pFW, original, gasFW, nil)
			if err != nil {
				t.Fatalf("NTT_FW failed: %v", err)
			}

			// Step 2: Prepend header to NTT_FW result for NTT_INV input
			invInput := append(original[:12:12], fwResult...)

			// Step 3: Run NTT_INV on the result
			pINV := allPrecompiles[common.HexToAddress("13")]
			gasINV := pINV.RequiredGas(invInput)
			invResult, _, err := RunPrecompiledContract(pINV, invInput, gasINV, nil)
			if err != nil {
				t.Fatalf("NTT_INV failed: %v", err)
			}

			// Step 4: Verify roundtrip (compare saved coefficient data)
			if !bytes.Equal(originalCoeffs, invResult) {
				t.Errorf("Roundtrip failed: original coefficients != NTT_INV(NTT_FW(original))")
				t.Errorf("Original coeff length: %d, Result length: %d", len(originalCoeffs), len(invResult))
			}
		})
	})
}

// Test NTT_VECMULMOD and NTT_VECADDMOD precompiles with malformed inputs
func TestPrecompiledVectorOpMalformedInput(t *testing.T) {
	// Vector operation malformed input test vectors
	var vectorOpMalformedInputTests = []precompiledFailureTest{
		{
			Input:         "",
			ExpectedError: "input too short: minimum 12 bytes required",
			Name:          "empty input",
		},
		{
			Input:         "00000000",
			ExpectedError: "input too short: minimum 12 bytes required",
			Name:          "too short input",
		},
		{
			// ringDegree=0 (invalid)
			Input:         "000000000000000000003001",
			ExpectedError: "ring degree must be a power of 2",
			Name:          "zero ring degree",
		},
		{
			// ringDegree=15 (not power of 2)
			Input:         "0000000f000000000000300100000001000000020000000300000004",
			ExpectedError: "ring degree must be a power of 2",
			Name:          "non-power-of-2 ring degree",
		},
		{
			// ringDegree=16, modulus=97 (unsupported)
			Input:         "00000010000000000000006100000000000000010000000000000002",
			ExpectedError: "unsupported modulus: 97 (only 12289 and 8380417 supported)",
			Name:          "unsupported modulus",
		},
		{
			// Falcon-512: ringDegree=512, modulus=12289, but only 6 bytes of data (not enough for even one coefficient per vector)
			Input:         "000002000000000000003001000100020003",
			ExpectedError: "invalid data length: expected 2048 bytes, got 6",
			Name:          "invalid vector data length for Falcon (too short)",
		},
		{
			// Falcon-512: ringDegree=512, modulus=12289, but only one vector provided (1024 bytes instead of 2048)
			Input:         "000002000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200",
			ExpectedError: "invalid data length: expected 2048 bytes, got 1024",
			Name:          "invalid vector data length for Falcon (one vector only)",
		},
		{
			// ML-DSA: ringDegree=256, modulus=8380417, but only 3 uint32 coefficients per vector
			Input:         "0000010000000000007fe001000000010000000200000003000000040000000500000006",
			ExpectedError: "invalid data length: expected 2048 bytes, got 24",
			Name:          "invalid vector data length for ML-DSA (too short)",
		},
	}

	// Test NTT_VECMULMOD (0x14) malformed inputs
	t.Run("NTT_VECMULMOD", func(t *testing.T) {
		for _, test := range vectorOpMalformedInputTests {
			testPrecompiledFailure("14", test, t)
		}
	})

	// Test NTT_VECADDMOD (0x15) malformed inputs
	t.Run("NTT_VECADDMOD", func(t *testing.T) {
		for _, test := range vectorOpMalformedInputTests {
			testPrecompiledFailure("15", test, t)
		}
	})
}

// Test NTT_VECMULMOD and NTT_VECADDMOD precompiles with valid inputs
func TestPrecompiledVectorOp(t *testing.T) {
	t.Run("NTT_VECMULMOD", func(t *testing.T) {
		t.Run("Falcon-512-simple", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("14")]
			// Simple test: multiply small values
			// Ring degree = 512, modulus = 12289
			// vecA = [1, 2], vecB = [3, 4], rest zeros
			// Expected: [3, 8], rest zeros (in Montgomery domain)
			header := "000002000000000000003001" // ringDegree=512, modulus=12289

			// Create two vectors of 512 uint16 elements each
			vecA := make([]byte, 512*2)
			vecB := make([]byte, 512*2)

			// Set first two elements: vecA[0]=1, vecA[1]=2
			binary.BigEndian.PutUint16(vecA[0:2], 1)
			binary.BigEndian.PutUint16(vecA[2:4], 2)

			// Set first two elements: vecB[0]=3, vecB[1]=4
			binary.BigEndian.PutUint16(vecB[0:2], 3)
			binary.BigEndian.PutUint16(vecB[2:4], 4)

			input := common.Hex2Bytes(header)
			input = append(input, vecA...)
			input = append(input, vecB...)

			gas := p.RequiredGas(input)

			result, _, err := RunPrecompiledContract(p, input, gas, nil)
			if err != nil {
				t.Errorf("Failed to run VECMULMOD: %v", err)
			}

			if len(result) != 512*2 {
				t.Errorf("Expected result length %d, got %d", 512*2, len(result))
			}

			// Verify result[0] and result[1] are non-zero (Montgomery multiplication of small values)
			r0 := binary.BigEndian.Uint16(result[0:2])
			r1 := binary.BigEndian.Uint16(result[2:4])

			if r0 == 0 || r1 == 0 {
				t.Errorf("Expected non-zero results for multiplication, got r0=%d, r1=%d", r0, r1)
			}
		})

		t.Run("ML-DSA-256-simple", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("14")]
			// Simple test: multiply small values
			// Ring degree = 256, modulus = 8380417
			// vecA = [1, 2], vecB = [3, 4], rest zeros
			// Expected: [3, 8], rest zeros
			header := "0000010000000000007fe001" // ringDegree=256, modulus=8380417

			// Create two vectors of 256 int32 elements each
			vecA := make([]byte, 256*4)
			vecB := make([]byte, 256*4)

			// Set first two elements: vecA[0]=1, vecA[1]=2
			binary.BigEndian.PutUint32(vecA[0:4], 1)
			binary.BigEndian.PutUint32(vecA[4:8], 2)

			// Set first two elements: vecB[0]=3, vecB[1]=4
			binary.BigEndian.PutUint32(vecB[0:4], 3)
			binary.BigEndian.PutUint32(vecB[4:8], 4)

			input := common.Hex2Bytes(header)
			input = append(input, vecA...)
			input = append(input, vecB...)

			gas := p.RequiredGas(input)

			result, _, err := RunPrecompiledContract(p, input, gas, nil)
			if err != nil {
				t.Errorf("Failed to run VECMULMOD: %v", err)
			}

			if len(result) != 256*4 {
				t.Errorf("Expected result length %d, got %d", 256*4, len(result))
			}

			// Verify result[0] = 1*3 = 3, result[1] = 2*4 = 8
			r0 := binary.BigEndian.Uint32(result[0:4])
			r1 := binary.BigEndian.Uint32(result[4:8])

			if r0 != 3 {
				t.Errorf("Expected result[0]=3, got %d", r0)
			}
			if r1 != 8 {
				t.Errorf("Expected result[1]=8, got %d", r1)
			}
		})
	})

	t.Run("NTT_VECADDMOD", func(t *testing.T) {
		t.Run("Falcon-512-simple", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("15")]
			// Simple test: add small values
			// Ring degree = 512, modulus = 12289
			// vecA = [1, 2], vecB = [3, 4], rest zeros
			// Expected: [4, 6], rest zeros
			header := "000002000000000000003001" // ringDegree=512, modulus=12289

			// Create two vectors of 512 uint16 elements each
			vecA := make([]byte, 512*2)
			vecB := make([]byte, 512*2)

			// Set first two elements: vecA[0]=1, vecA[1]=2
			binary.BigEndian.PutUint16(vecA[0:2], 1)
			binary.BigEndian.PutUint16(vecA[2:4], 2)

			// Set first two elements: vecB[0]=3, vecB[1]=4
			binary.BigEndian.PutUint16(vecB[0:2], 3)
			binary.BigEndian.PutUint16(vecB[2:4], 4)

			input := common.Hex2Bytes(header)
			input = append(input, vecA...)
			input = append(input, vecB...)

			gas := p.RequiredGas(input)

			result, _, err := RunPrecompiledContract(p, input, gas, nil)
			if err != nil {
				t.Errorf("Failed to run VECADDMOD: %v", err)
			}

			if len(result) != 512*2 {
				t.Errorf("Expected result length %d, got %d", 512*2, len(result))
			}

			// Verify result[0] = 1+3 = 4, result[1] = 2+4 = 6
			r0 := binary.BigEndian.Uint16(result[0:2])
			r1 := binary.BigEndian.Uint16(result[2:4])

			if r0 != 4 {
				t.Errorf("Expected result[0]=4, got %d", r0)
			}
			if r1 != 6 {
				t.Errorf("Expected result[1]=6, got %d", r1)
			}
		})

		t.Run("ML-DSA-256-simple", func(t *testing.T) {
			p := allPrecompiles[common.HexToAddress("15")]
			// Simple test: add small values
			// Ring degree = 256, modulus = 8380417
			// vecA = [1, 2], vecB = [3, 4], rest zeros
			// Expected: [4, 6], rest zeros
			header := "0000010000000000007fe001" // ringDegree=256, modulus=8380417

			// Create two vectors of 256 int32 elements each
			vecA := make([]byte, 256*4)
			vecB := make([]byte, 256*4)

			// Set first two elements: vecA[0]=1, vecA[1]=2
			binary.BigEndian.PutUint32(vecA[0:4], 1)
			binary.BigEndian.PutUint32(vecA[4:8], 2)

			// Set first two elements: vecB[0]=3, vecB[1]=4
			binary.BigEndian.PutUint32(vecB[0:4], 3)
			binary.BigEndian.PutUint32(vecB[4:8], 4)

			input := common.Hex2Bytes(header)
			input = append(input, vecA...)
			input = append(input, vecB...)

			gas := p.RequiredGas(input)

			result, _, err := RunPrecompiledContract(p, input, gas, nil)
			if err != nil {
				t.Errorf("Failed to run VECADDMOD: %v", err)
			}

			if len(result) != 256*4 {
				t.Errorf("Expected result length %d, got %d", 256*4, len(result))
			}

			// Verify result[0] = 1+3 = 4, result[1] = 2+4 = 6
			r0 := binary.BigEndian.Uint32(result[0:4])
			r1 := binary.BigEndian.Uint32(result[4:8])

			if r0 != 4 {
				t.Errorf("Expected result[0]=4, got %d", r0)
			}
			if r1 != 6 {
				t.Errorf("Expected result[1]=6, got %d", r1)
			}
		})
	})
}

// Benchmark NTT_FW precompile with crypto standards
func BenchmarkPrecompiledNTT_FW(bench *testing.B) {
	testCases := []precompiledTest{
		{
			Name:     "NTT_FW-Falcon-512",
			Input:    "000002000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200",
			Expected: "0feb0760083604d3264c22900a531f4f0a7719cf2d6a25e11d2b1efd266b249d231d1a3b101d191a29eb2c9a0f121004131a1aa607e6174211560cae11bd13690dd7105e2e6311a8245201c00acb0a190778124c04841f401618205a1ea72f8a07ca2b630ea015a91b710b622f7d2d721dce02fb19f223a81d712906249a1997282e2f04232014550dea04071b8619a7056b1aab1c911c5b02690f550d751ee0296c1336005309200c54040128100faf012909af062606730e052e4e297f2dd1226b2f7623672d080a0404b6169c22d9073822eb2e0f10d1119b2f9f1d75297f28e012f80a120e942d33116913580fdf279a18740b2315702a7f021608d8274c1344022e25e107bb2b6d263414fe2ffd1c0129ae29be0c5101011e6802501fdb019e25e023e402560dfb12ca29812c3f1fe514c4203f0bc9110c104b222a2de505380a7811e00d0a150524a720f429a2211529ad000e03e10255110322c61f7a2662244a2138244a2ce50f6310fe2b7706ca0636123a0d550989298014b80abb1b262cd419dc104721dd187710d50098071629d624fb28080aef2796255f27dc02b711352e4e23e01de41a2c2b061f101fcd099d20cb2f8218f603a015310be626330cd0138b00070aa72b660cf30e0f17f70f782aa1104313fd20550e3120290bd1173a04810edc15b409811b3609c3235a0279232c06400a15202912381dff28970a752a44128428230b011ba903cc1c400d330aae1aba08911a101edd1cd22dfd03da27f6267c2688227512081cc20c520cae1b4712be0954089b2b8b0c48015d10132e2219cc0c5e27510aee1c7412f526fd2f772c7f24a92874280e2e6a08862a4b1e081d3c15f916a006792b5d149f0d2d0ac3117a0ee20f0926c30eb50a6b0a3825ec01e90a16193017860b7c2459014002700cb6023610382e4c1240230c0bf41995062c23352f161623220702a40b982e7224ec21a92cf1189d24b60375026a1c2b022a0ff10a4c086a130f0db70e6c1bd8096a0dd30a4a19bc29910e6311ab01012b8a16660da60c2919a021e407272849177a024715bc08b72c7907c4151c18d014f5060c039d071e09470d370c761307257d038422ff182817002cdf13c31bd42334065e2c941c0c023d257122dd1e8800fe19500d4009c90bdc044b0e0d1c160bdd29322a9706950de3093711fd28b121c319051d4e19f7021126d1239e1efe246610511f092d1816a72a7729d12aa820c411412d83149c083e077a209f23912802039025f3025318ce0b212d19048d15b10fe61dd701de0317007a28e91c07089628570bbf143e27cf0b052fb618f9095f154b29e02a99149d034d0bab245817b801442fbd1dbf2aae1445056518f729b40e3e1be608b1043e019103ff2d610b6a1df403ab2f7d27f018a50546213a2a94162c19220b392e03",
		},
		{
			Name:     "NTT_FW-Falcon-1024",
			Input:    "000004000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200020102020203020402050206020702080209020a020b020c020d020e020f0210021102120213021402150216021702180219021a021b021c021d021e021f0220022102220223022402250226022702280229022a022b022c022d022e022f0230023102320233023402350236023702380239023a023b023c023d023e023f0240024102420243024402450246024702480249024a024b024c024d024e024f0250025102520253025402550256025702580259025a025b025c025d025e025f0260026102620263026402650266026702680269026a026b026c026d026e026f0270027102720273027402750276027702780279027a027b027c027d027e027f0280028102820283028402850286028702880289028a028b028c028d028e028f0290029102920293029402950296029702980299029a029b029c029d029e029f02a002a102a202a302a402a502a602a702a802a902aa02ab02ac02ad02ae02af02b002b102b202b302b402b502b602b702b802b902ba02bb02bc02bd02be02bf02c002c102c202c302c402c502c602c702c802c902ca02cb02cc02cd02ce02cf02d002d102d202d302d402d502d602d702d802d902da02db02dc02dd02de02df02e002e102e202e302e402e502e602e702e802e902ea02eb02ec02ed02ee02ef02f002f102f202f302f402f502f602f702f802f902fa02fb02fc02fd02fe02ff0300030103020303030403050306030703080309030a030b030c030d030e030f0310031103120313031403150316031703180319031a031b031c031d031e031f0320032103220323032403250326032703280329032a032b032c032d032e032f0330033103320333033403350336033703380339033a033b033c033d033e033f0340034103420343034403450346034703480349034a034b034c034d034e034f0350035103520353035403550356035703580359035a035b035c035d035e035f0360036103620363036403650366036703680369036a036b036c036d036e036f0370037103720373037403750376037703780379037a037b037c037d037e037f0380038103820383038403850386038703880389038a038b038c038d038e038f0390039103920393039403950396039703980399039a039b039c039d039e039f03a003a103a203a303a403a503a603a703a803a903aa03ab03ac03ad03ae03af03b003b103b203b303b403b503b603b703b803b903ba03bb03bc03bd03be03bf03c003c103c203c303c403c503c603c703c803c903ca03cb03cc03cd03ce03cf03d003d103d203d303d403d503d603d703d803d903da03db03dc03dd03de03df03e003e103e203e303e403e503e603e703e803e903ea03eb03ec03ed03ee03ef03f003f103f203f303f403f503f603f703f803f903fa03fb03fc03fd03fe03ff0400",
			Expected: "0cab2f0119b5265b0f23086d188b2c2008e80ed921550eb00a7e094c09b8232a14ee040a14b12b651c0002c011ff07f62a0e220201d005130b541b842e3223dc051e13071b070af306671c340a0c2a7e0e73238a0fef0fc3168a05621ebd0b1b1ce605311e891b2010dc07690fb42dab2fe90474036b040d0ba6030d187f2cdb053c25a1035d24cc054e0d3b23de2056283e1450142d2a3211ce01c8275e22a41e7915302b2823132432018007272f7519b71e79192a121c1a880674014c01e2101b072e02a52bb822f322ff20bc23c2270d069e1fdc0fe1140526cb12c212af1ba10efb105b188220440004036b108b04a90d951443231803450544055d196128bd08b6201c066a2563241708602d4a0b1b0594109223eb17be102b24c30563065c1cd2272911e4268e2c8529b629061b8c14e22b880b5022ae103d051c26a8199518532b9301591d800c9f18d72e4510132ef30e3811cf2fe5124f09eb16b629f421e527090fee170b166b2d7517fd13e12a291a8914921dbb1c8d2558220e2ca61a0f07d108b92073216b12fe000a2d532cc1151b2c8702b12c140b3526e7020b11a72c520ab410f813b12e862cca20fc12a22ea121c10ceb051f0b491a6204f410b31d690bec25b60487144c128a18ad043a27d1195709fc1cb11adc22ed1ed01b2a100f226c1bb129d916b814c00fc719fb00772846205d096727782dad0e2f12242009226b0470249e15181dc90f9324a21b7c1a5505af03e201cd168b2f891f670652190b2dc50bd014d3040126fb2e421eaa18281f450e150cd10bfc20ce118527082ff91dd319482a922ce31fdb177b0b362365222327de2b771ccb15441fea2b0222951075086500e416e91c0a16e604f90e1a2dce0c7510f3268205b1005b19c32fea08c317fc2a8928e3028e257f0a6a2d1328141b0400c411ac0c200deb28081d160d1008a024de1f101c302e560ade07b5114f18ef237d0c5906c2191705b515fe22421e2e079813001c382cf207272824076804a52794067c1f7612de27021d0b03fe294a13e028580a28132b2ee723c50a9b076823e1204011e905740376084614aa291225f816a52fb10ed8250d1a610e44240b2c560d360b6f0903266b090d0be5133914bb2d5d15991e9b1e2505101d30172e0ffa19a813f51434019308df13481407168112a228801fab1d4a10730f1b298827bf1a2c1f421506234719f608a3223415bd277428742df003f106fb08e91ab42a1c1e770da62b380d65217c1ddb12c12ee10fd5227312751b4d27f11ce417a512d124a8054e12d7292705f81d44148c1f5621fa1cc00de9298a214507bc1c400c6a2c8c08a82bb61578224a20932512292a12fd02ad14d4228101a417490d061edc018721ce1f730ee71ad52a3e055307ff15fc263308b1186023ef247223a5225516ed12e50e29237b071e02472b1627de1b9e06ed049d13cb15522ce421e420ed0a652f29187b059017bf29830310206629cb12dd0eac2b81091a0db302e02adc134d087307262e4625e708940dc1136b1bc9119028462b59172713fb12e10c401e781c1815ef290d08ea2245252a26741a34104c0667192526d304cb1db904e02c282feb1c8c191a28541bf1102415812f1e2d1c252d22b112e0275c1d9025a7070e037d22a6279b27c617412186098917d01e1d1adc0d55065a2244284f023f0a1513bb2425114208ff19b8198308e7038b2ca8293e172f28181c57156708831cd003c1178b15400074199403e1040f2abe1b0125021afb1ad81acf07c72d0903002ef01184000b09ac11d419282ab615bc0f1d12532f51210a01d8010619192da800f420330e732e7403ed141010c82c7421d32d901aab0a9f1d6e212e26030ca51adb2f60193b17691fd917ee0670010b24b203b3222a24b00b241ef71d9814c52f0c0f9604d80a3a25bb2f242ad204de28e70e74158c04f10b8b07172cff14a715cd182019d50e3311ed2cd21cc82d1d19d00d46194318091f06081722cc13d0002c0f6306b82ef51c7f0f68250c012e277021bd0b4c164b2bbc1bad157204f11cf3233220a601e807280fa526a20648199f28640dcb06291adb0d1d1d9909f51a3d24e615b5214906120e08108106de05901f94148620d9107208ab2717278326f1102505fc180b20e421f303c1104522851fef0a5d1b16257826512637034d27a60ee51e5a0a2c2e85220f263b1795178809fe1a180fe92b6627c02099093807800c4328f229de207f2ce426d618c224280d41141511c421f112de053b0ce313e21b2207a01f7821da29781854199e06ec0f6320b7000106580e12017510ec22e72e1e06760d6b2da40cc90a191f610d320bea1e631715245015c6078618ce15232dd00f720687094c296f015e17f22022215208a113bf0c9a1b281ff12c161ae810101001215a09581916022a089e080127ee2be60f6906191fde2cce204817b90e9117f3157809721cc70be00e222a3806712dad0b5d21b3063f2d4702f027890df80648160a192821d100bb12ca284400a012630ce11f522d0725852a4915ed16e70ffb078301d60e25011e05b812830f3620231bc227172f8b191a2b1e2a2002bb09a1039a142c220b1c55262f0dcb19ed290b224c1b2100c71922104b2bd10ea2187b2dec18d513ac15ee044208231f7022a60bd31de415c81ae3140b263c1f3f28630e8506b425e51a6a256c035b215a0ce3295d101807cc205a24a827c30f84009805532c790a11248707ef0cf02be12fcf2d9d2ec306ee2ffb2547246622400ec6140411de28ae16410ffe0f9325c41d69282529992b7a17f008ad29e2290620780a1e166d08ae0cd02ee60be21b6b1ecf1efc23be16931a021203",
		},
		{
			Name:     "NTT_FW-ML-DSA-256",
			Input:    "0000010000000000007fe0010000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000100000001100000012000000130000001400000015000000160000001700000018000000190000001a0000001b0000001c0000001d0000001e0000001f000000200000002100000022000000230000002400000025000000260000002700000028000000290000002a0000002b0000002c0000002d0000002e0000002f000000300000003100000032000000330000003400000035000000360000003700000038000000390000003a0000003b0000003c0000003d0000003e0000003f000000400000004100000042000000430000004400000045000000460000004700000048000000490000004a0000004b0000004c0000004d0000004e0000004f000000500000005100000052000000530000005400000055000000560000005700000058000000590000005a0000005b0000005c0000005d0000005e0000005f000000600000006100000062000000630000006400000065000000660000006700000068000000690000006a0000006b0000006c0000006d0000006e0000006f000000700000007100000072000000730000007400000075000000760000007700000078000000790000007a0000007b0000007c0000007d0000007e0000007f000000800000008100000082000000830000008400000085000000860000008700000088000000890000008a0000008b0000008c0000008d0000008e0000008f000000900000009100000092000000930000009400000095000000960000009700000098000000990000009a0000009b0000009c0000009d0000009e0000009f000000a0000000a1000000a2000000a3000000a4000000a5000000a6000000a7000000a8000000a9000000aa000000ab000000ac000000ad000000ae000000af000000b0000000b1000000b2000000b3000000b4000000b5000000b6000000b7000000b8000000b9000000ba000000bb000000bc000000bd000000be000000bf000000c0000000c1000000c2000000c3000000c4000000c5000000c6000000c7000000c8000000c9000000ca000000cb000000cc000000cd000000ce000000cf000000d0000000d1000000d2000000d3000000d4000000d5000000d6000000d7000000d8000000d9000000da000000db000000dc000000dd000000de000000df000000e0000000e1000000e2000000e3000000e4000000e5000000e6000000e7000000e8000000e9000000ea000000eb000000ec000000ed000000ee000000ef000000f0000000f1000000f2000000f3000000f4000000f5000000f6000000f7000000f8000000f9000000fa000000fb000000fc000000fd000000fe000000ff00000100",
			Expected: "ffc0e5f5ffccf7a7ffd16090004edaa0ffe71eb5ff73c3cbffe816a4ffaa68e8002d128900232447fffbc48800687808ffcc23a6ff8887d4ffd085b7ffb886f7ff50787aff5f29c0ff91d975ff1ede45ff5455b0ff39e7daff996f80ff570e8affde03f2ff9927c0ffbd960aff90b5340039e72dfff657710005c979ff99167100589a8900d65079ffedd0140059c60200696427004eba3d00122b9600717966002e890d001d9f150089e6aa006269b8fff32611ff898dc9001ae6bfffaa09dbffb50b370023ba61003b4460001d4eb80041022c00244598006c1331005829630014c6bbffef9ca5ffacd6f3ff8da3e5004334eaffc85ba4ffb04e46fff5185cffa02252ffddd8ceff977426ffe45376000d940c000b7406ff830114ffa8512effdbfd160058d400ff726e3affeaabf400413b6c00237720006a08a500ba812bffe9ae30fff4ced2ff779d7fff74f673ffefd00bffec82b1ff828eb1ffbfcf67006691eb008a7261001b0fd3007e964dffecc411ffb8aaa70039d446002be95e0038fb8d00946b6f005188a6fff8a1c20073dc960046207c000c2ae60060c30400187a800007feecffe2e96e00255b2affa9a238ff8327a0ffa2bcc90013becb00b1379b00401b0f006fd627004768f70105411f00a529f500a4942500be8a8f002d6ba300307ec7006c48b50093fb4500086cc1001336a7ffbf9f24ffa40db0fffa327a0044f6b4ffb3861dffe7664dfff7f812ffb50442002b72f1ffffb0a30041adb6fffc3596002dc3aa000bb9eeff5cb969ffadb0fdffd84203ffc2f9c3ff64ccdeff53b11efffcdcedff7e51a3fffabc1effceade6ff681582ffa89796ffabe545ffd95673ff5055fbff67c95d0012ae2b00620801fff4a23affa211d2fff4817aff998fe00004658fffe9c0afffa9a064001427ec0016ff05008496dbff624a1bffdcc465fff043fd0015d6b3003886f2ffe11fe4ffcfc63000427a42001b189f0015584100cfe9e800561e18fffba85d002204bb000b35bf00463b1900638201fff43d6500a28da100736c6dffff143fffd1d0efffb8d547001f52c7ffffecbe000139320064c65fffe78021ffd097abffdbc8770019b65b0036a513ffb34364ff64d086ff8a1165ffed3815ffd545fcffd92542ffcd17f0ff780ede00151f9eff9a21a0ffedf6e2004b78c4002395f9ffa810d500096b7a000d2bccffd3dd0cff6ff9c0ff97ee1dffd4f15fff828229ffc7f9c50008b217ffe521eb00526069006be427000ee455005cfeef0043b45f005a72a10042edfe0019c3ae00384bde006d2092ffe995990036989bffc384ea0018486e001ce2bf001dc2d50028952600311ff2008755df003c760900a4620b00c18e7d00677b50007eb5a8002e71ac003bdafa0053c84c0042e5760003951eff91d60cfffa06c8006bb1b6",
		},
	}

	for _, test := range testCases {
		benchmarkPrecompiled("12", test, bench)
	}
}

// Benchmark NTT_INV precompile with crypto standards
func BenchmarkPrecompiledNTT_INV(bench *testing.B) {
	testCases := []precompiledTest{
		{
			Name:     "NTT_INV-Falcon-512",
			Input:    "000002000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200",
			Expected: "190108a51daf239f0374093714e82691180e259a29e723a013fc0e0c15e02283112b1cdf16b6233e172808402a3218fc1ecb0dfd10e40a560a6a1ab20eb8003c1c0d27d92b6c115e2a401a0f25af1b27116a18e305821f5322582e1028ef08101d1a2bd206cd1c1e04f316a525e11ce928f11c3a200e10452db10d7b03bf21731fd8258a1da324c9026e259e07c812051e052abf14732f3e2deb2fcf264c1f31140104720a94294821fe2bd01f8d006220e514c726161c49273d2a441b39232a00e027b42be9090019cd127b02f321a92ea529d62e5e14360c5925cf234828d00d0526c00db42ee4138a17cd0b2c25ac150c11712b661f330cf3181412971109062304cd04e523712ffc0903182d139c0d201bee10b920ed20dc0917005912f628be177c152a030714ff2a8b248107530217135c24ac2b49277b1bd612df020120e11e2712f52a4003cd17c729481a5c225222331b3a06581d021553165a0c1900062235145d075f12a717162b0f2cfb033f1b9d1798125917170f681a6927ee23c11ab52cde1176265718182fb9209805631f9f2b2d0cba178d159214d3218d0ab123a6230b1abe060d0ff413e5254a0fd413bd0c4308a90870075a07660c1c2dfc0d9b1dd0171014cf1d131e252012276d006025470beb2cbe24c2007c148b18a60749127510c70fce0f09123703dd04752c5b2df2218f098e11551a76201e1c90201e1a761155098e218f2df22c5b047503dd12370f090fce10c71275074918a6148b007c24c22cbe0beb25470060276d20121e251d1314cf17101dd00d9b2dfc0c1c0766075a087008a90c4313bd0fd4254a13e50ff4060d1abe230b23a60ab1218d14d31592178d0cba2b2d1f9f056320982fb91818265711762cde1ab523c127ee1a690f681717125917981b9d033f2cfb2b0f171612a7075f145d223500060c19165a15531d0206581b3a223322521a5c294817c703cd2a4012f51e2720e1020112df1bd6277b2b4924ac135c0217075324812a8b14ff0307152a177c28be12f60059091720dc20ed10b91bee0d20139c182d09032ffc237104e504cd06231109129718140cf31f332b661171150c25ac0b2c17cd138a2ee40db426c00d0528d0234825cf0c5914362e5e29d62ea521a902f3127b19cd09002be927b400e0232a1b392a44273d1c49261614c720e500621f8d2bd021fe29480a94047214011f31264c2fcf2deb2f3e14732abf1e05120507c8259e026e24c91da3258a1fd8217303bf0d7b2db11045200e1c3a28f11ce925e116a504f31c1e06cd2bd21d1a081028ef2e1022581f53058218e3116a1b2725af1a0f2a40115e2b6c27d91c0d003c0eb81ab20a6a0a5610e40dfd1ecb18fc2a3208401728233e16b61cdf112b228315e00e0c13fc23a029e7259a180e269114e809370374239f1daf08a5",
		},
		{
			Name:     "NTT_INV-Falcon-1024",
			Input:    "000004000000000000003001000100020003000400050006000700080009000a000b000c000d000e000f0010001100120013001400150016001700180019001a001b001c001d001e001f0020002100220023002400250026002700280029002a002b002c002d002e002f0030003100320033003400350036003700380039003a003b003c003d003e003f0040004100420043004400450046004700480049004a004b004c004d004e004f0050005100520053005400550056005700580059005a005b005c005d005e005f0060006100620063006400650066006700680069006a006b006c006d006e006f0070007100720073007400750076007700780079007a007b007c007d007e007f0080008100820083008400850086008700880089008a008b008c008d008e008f0090009100920093009400950096009700980099009a009b009c009d009e009f00a000a100a200a300a400a500a600a700a800a900aa00ab00ac00ad00ae00af00b000b100b200b300b400b500b600b700b800b900ba00bb00bc00bd00be00bf00c000c100c200c300c400c500c600c700c800c900ca00cb00cc00cd00ce00cf00d000d100d200d300d400d500d600d700d800d900da00db00dc00dd00de00df00e000e100e200e300e400e500e600e700e800e900ea00eb00ec00ed00ee00ef00f000f100f200f300f400f500f600f700f800f900fa00fb00fc00fd00fe00ff0100010101020103010401050106010701080109010a010b010c010d010e010f0110011101120113011401150116011701180119011a011b011c011d011e011f0120012101220123012401250126012701280129012a012b012c012d012e012f0130013101320133013401350136013701380139013a013b013c013d013e013f0140014101420143014401450146014701480149014a014b014c014d014e014f0150015101520153015401550156015701580159015a015b015c015d015e015f0160016101620163016401650166016701680169016a016b016c016d016e016f0170017101720173017401750176017701780179017a017b017c017d017e017f0180018101820183018401850186018701880189018a018b018c018d018e018f0190019101920193019401950196019701980199019a019b019c019d019e019f01a001a101a201a301a401a501a601a701a801a901aa01ab01ac01ad01ae01af01b001b101b201b301b401b501b601b701b801b901ba01bb01bc01bd01be01bf01c001c101c201c301c401c501c601c701c801c901ca01cb01cc01cd01ce01cf01d001d101d201d301d401d501d601d701d801d901da01db01dc01dd01de01df01e001e101e201e301e401e501e601e701e801e901ea01eb01ec01ed01ee01ef01f001f101f201f301f401f501f601f701f801f901fa01fb01fc01fd01fe01ff0200020102020203020402050206020702080209020a020b020c020d020e020f0210021102120213021402150216021702180219021a021b021c021d021e021f0220022102220223022402250226022702280229022a022b022c022d022e022f0230023102320233023402350236023702380239023a023b023c023d023e023f0240024102420243024402450246024702480249024a024b024c024d024e024f0250025102520253025402550256025702580259025a025b025c025d025e025f0260026102620263026402650266026702680269026a026b026c026d026e026f0270027102720273027402750276027702780279027a027b027c027d027e027f0280028102820283028402850286028702880289028a028b028c028d028e028f0290029102920293029402950296029702980299029a029b029c029d029e029f02a002a102a202a302a402a502a602a702a802a902aa02ab02ac02ad02ae02af02b002b102b202b302b402b502b602b702b802b902ba02bb02bc02bd02be02bf02c002c102c202c302c402c502c602c702c802c902ca02cb02cc02cd02ce02cf02d002d102d202d302d402d502d602d702d802d902da02db02dc02dd02de02df02e002e102e202e302e402e502e602e702e802e902ea02eb02ec02ed02ee02ef02f002f102f202f302f402f502f602f702f802f902fa02fb02fc02fd02fe02ff0300030103020303030403050306030703080309030a030b030c030d030e030f0310031103120313031403150316031703180319031a031b031c031d031e031f0320032103220323032403250326032703280329032a032b032c032d032e032f0330033103320333033403350336033703380339033a033b033c033d033e033f0340034103420343034403450346034703480349034a034b034c034d034e034f0350035103520353035403550356035703580359035a035b035c035d035e035f0360036103620363036403650366036703680369036a036b036c036d036e036f0370037103720373037403750376037703780379037a037b037c037d037e037f0380038103820383038403850386038703880389038a038b038c038d038e038f0390039103920393039403950396039703980399039a039b039c039d039e039f03a003a103a203a303a403a503a603a703a803a903aa03ab03ac03ad03ae03af03b003b103b203b303b403b503b603b703b803b903ba03bb03bc03bd03be03bf03c003c103c203c303c403c503c603c703c803c903ca03cb03cc03cd03ce03cf03d003d103d203d303d403d503d603d703d803d903da03db03dc03dd03de03df03e003e103e203e303e403e503e603e703e803e903ea03eb03ec03ed03ee03ef03f003f103f203f303f403f503f603f703f803f903fa03fb03fc03fd03fe03ff0400",
			Expected: "1a011804114a189c0b5d055c173d173406e80f91126e2cb929d004bc1d210595001b2c811b3317f623cd17f8173f2fc527f80d2d1c1825322bc002a61505044a2256104d09bd26142d6c2210167b2f8f2e5017a51080023b246327e901f707ea0d9512051bfa1f9821c8203e14ac1d5414d41c490563194c1d70029800782a5108192f891fb12ffb26d72a7622bc041d247f1296041d28221b5d07f7064d243822d42f9e01c52eb40b0411a50ea506ad14af27702c1f231821dd014f10202a220a3314a927a324900d9a1a15083b1bff09e601bd2d4a02711bc120e309d127f221e11fad087316f4101b2dce208a0cf52b6100561af612fe077e121a12e501d40faf2dfe1b1303280b4527ee19911b7c04dc193f1b3b1c360f9020e1240a08d40c09099b257d1a7228e615e12e7b01d52bd502402f9d2e601c971c780e610836280207d108e414ec1528079a228f2bee13fb25ee279f1ab90f19048600c4290311c91fd7298e07fc1c2b208b0891080b1e790d4524871f26067119b516531fcb01c02ade1f671e2a27d12ebc120027c60399143624f60bed05e62ee713511c5a2d49213623ab1ff62cbb0688286c0e7318b209191b9d108b168f2a5a219f171c1a0a04dd1d7f09961b68251f2dc71785271424302f9a1066165805841b572f472a181e3222e2086426cb14fc0e65186e19e612f100270661252e2440221209c00c4623e5099a0fbf09ca167016e11bc02ff70568120608f6005902ed273808d71a4026ef07db03e121721f2711d903b411b702e7122e1f5f00b20e5525ec1a93217b24542ef828682a541ea3060e135e29fe19cb2515139619010ff70ea6112a042e0b7c26b8218a1957210226911fe81ef501fe07ab279825be06900402089311c1007a0c4d192125ea209a247f013f079a133d2f8e22d1228f04ea04b728af14a305ef1465047a067300450cb024b40a0311f82aa612082cb42b10183227f1000c249b14691dd928ba06670ebe2077254e0ed52e2c0aa5261d2f3829f519a5067e1177073900ef2f302f0424b229c62e2e06eb1ed02e5c04d104011fdb19eb1781038305691e0b29bb290b22ec16921cad2350002f1cda2f71204a112f0e2a0ac60ab30f3d2c86265928a919741a2b2f1a2d942b240c7329a608341319119e15620f5e174b2299161514c3057b18fb0c1a15641fe8263b27ca233f1a931bdf1fa82685277a0b9418861ad7115220df10e01edf0eb40d810ecc0e5d1838106d2bf723c71b361d350b9f0aab2e20157e299e07030a250eb70c4928e7102313611ed90c3300c019101a8d05a617d60962297b09c9198302c400f81b9529161741014b00a40e920fb424ea1e56218e2dcf1f9c0bd31e120767246e180e07ba1b1908ea2b0e28b52b262be31637131d178d131c1e9222aa2dba04eb113c103b1555091f1555103b113c04eb2dba22aa1e92131c178d131d16372be32b2628b52b0e08ea1b1907ba180e246e07671e120bd31f9c2dcf218e1e5624ea0fb40e9200a4014b174129161b9500f802c4198309c9297b096217d605a61a8d191000c00c331ed91361102328e70c490eb70a250703299e157e2e200aab0b9f1d351b3623c72bf7106d18380e5d0ecc0d810eb41edf10e020df11521ad718860b94277a26851fa81bdf1a93233f27ca263b1fe815640c1a18fb057b14c316152299174b0f5e1562119e1319083429a60c732b242d942f1a1a2b197428a926592c860f3d0ab30ac60e2a112f204a2f711cda002f23501cad169222ec290b29bb1e0b05690383178119eb1fdb040104d12e5c1ed006eb2e2e29c624b22f042f3000ef07391177067e19a529f52f38261d0aa52e2c0ed5254e20770ebe066728ba1dd91469249b000c27f118322b102cb412082aa611f80a0324b40cb000450673047a146505ef14a328af04b704ea228f22d12f8e133d079a013f247f209a25ea19210c4d007a11c108930402069025be279807ab01fe1ef51fe8269121021957218a26b80b7c042e112a0ea60ff719011396251519cb29fe135e060e1ea32a5428682ef82454217b1a9325ec0e5500b21f5f122e02e711b703b411d91f27217203e107db26ef1a4008d7273802ed005908f6120605682ff71bc016e1167009ca0fbf099a23e50c4609c022122440252e0661002712f119e6186e0e6514fc26cb086422e21e322a182f471b570584165810662f9a2430271417852dc7251f1b6809961d7f04dd1a0a171c219f2a5a168f108b1b9d091918b20e73286c06882cbb1ff623ab21362d491c5a13512ee705e60bed24f61436039927c612002ebc27d11e2a1f672ade01c01fcb165319b506711f2624870d451e79080b0891208b1c2b07fc298e1fd711c9290300c404860f191ab9279f25ee13fb2bee228f079a152814ec08e407d1280208360e611c781c972e602f9d02402bd501d52e7b15e128e61a72257d099b0c0908d4240a20e10f901c361b3b193f04dc1b7c199127ee0b4503281b132dfe0faf01d412e5121a077e12fe1af600562b610cf5208a2dce101b16f408731fad21e127f209d120e31bc102712d4a01bd09e61bff083b1a150d9a249027a314a90a332a221020014f21dd23182c1f277014af06ad0ea511a50b042eb401c52f9e22d42438064d07f71b5d2822041d1296247f041d22bc2a7626d72ffb1fb12f8908192a51007802981d70194c05631c4914d41d5414ac203e21c81f981bfa12050d9507ea01f727e92463023b108017a52e502f8f167b22102d6c261409bd104d2256044a150502a62bc025321c180d2d27f82fc5173f17f823cd17f61b332c81001b05951d2104bc29d02cb9126e0f9106e81734173d055c0b5d189c114a1804",
		},
		{
			Name:     "NTT_INV-ML-DSA-256",
			Input:    "0000010000000000007fe0010000000100000002000000030000000400000005000000060000000700000008000000090000000a0000000b0000000c0000000d0000000e0000000f000000100000001100000012000000130000001400000015000000160000001700000018000000190000001a0000001b0000001c0000001d0000001e0000001f000000200000002100000022000000230000002400000025000000260000002700000028000000290000002a0000002b0000002c0000002d0000002e0000002f000000300000003100000032000000330000003400000035000000360000003700000038000000390000003a0000003b0000003c0000003d0000003e0000003f000000400000004100000042000000430000004400000045000000460000004700000048000000490000004a0000004b0000004c0000004d0000004e0000004f000000500000005100000052000000530000005400000055000000560000005700000058000000590000005a0000005b0000005c0000005d0000005e0000005f000000600000006100000062000000630000006400000065000000660000006700000068000000690000006a0000006b0000006c0000006d0000006e0000006f000000700000007100000072000000730000007400000075000000760000007700000078000000790000007a0000007b0000007c0000007d0000007e0000007f000000800000008100000082000000830000008400000085000000860000008700000088000000890000008a0000008b0000008c0000008d0000008e0000008f000000900000009100000092000000930000009400000095000000960000009700000098000000990000009a0000009b0000009c0000009d0000009e0000009f000000a0000000a1000000a2000000a3000000a4000000a5000000a6000000a7000000a8000000a9000000aa000000ab000000ac000000ad000000ae000000af000000b0000000b1000000b2000000b3000000b4000000b5000000b6000000b7000000b8000000b9000000ba000000bb000000bc000000bd000000be000000bf000000c0000000c1000000c2000000c3000000c4000000c5000000c6000000c7000000c8000000c9000000ca000000cb000000cc000000cd000000ce000000cf000000d0000000d1000000d2000000d3000000d4000000d5000000d6000000d7000000d8000000d9000000da000000db000000dc000000dd000000de000000df000000e0000000e1000000e2000000e3000000e4000000e5000000e6000000e7000000e8000000e9000000ea000000eb000000ec000000ed000000ee000000ef000000f0000000f1000000f2000000f3000000f4000000f5000000f6000000f7000000f8000000f9000000fa000000fb000000fc000000fd000000fe000000ff00000100",
			Expected: "003ff081004291d4000468af00799f7e00669c7500651af9005a89750059d805002238ca00006fd700382f710002d94a00458f1a00571a50001c12e100071da30016683a0038d6f5003913b80067a6df002411b90004236f00464895005782df0029f341004dd6a5000f846f005f33720016e42f004a2644006d0b4e005a37d8000870e60016d214002c797600381449002b8d500030a31a007c0f4c000abd020079c506004aedc6003ac2a30075b68800145b6c005ad35a000b79560026989a00631a49000e3fa000135c4f006275010035444d00339e7600556fdf007a8d01005de15f002ac82a00386a9a002d793b001837c00009210500661b6b001e9fa0002f6cf200175ba7007907d700167d67003277790006a2a7000fd2a900006e91006b9e0d00112f3b00706f6b007c67ea0024a6b30052192500732bdf006772110019296d0035d1b100559a4a003a5d82007fd5a3006572750008b23d0057b5490035d9970074807b0032aeac003cfc57000811cf006ad624001ddedd0033882c0016cc400039949900001c2b007987380038cd590067112c0025e7bc00697a00006b75db0006583c00089e110046da1b0036aac1007b71ce000890c100040bf2001adb60003b32290043c97b000f9963007149b5005f966000006b3e0015326a006efc56007c0825005d941e00426a5c0056867200203cc600603ae20018883a005c005c0018883a00603ae200203cc60056867200426a5c005d941e007c0825006efc560015326a00006b3e005f9660007149b5000f99630043c97b003b3229001adb6000040bf2000890c1007b71ce0036aac10046da1b00089e110006583c006b75db00697a000025e7bc0067112c0038cd590079873800001c2b003994990016cc400033882c001ddedd006ad624000811cf003cfc570032aeac0074807b0035d9970057b5490008b23d00657275007fd5a3003a5d8200559a4a0035d1b10019296d0067721100732bdf005219250024a6b3007c67ea00706f6b00112f3b006b9e0d00006e91000fd2a90006a2a70032777900167d67007907d700175ba7002f6cf2001e9fa000661b6b00092105001837c0002d793b00386a9a002ac82a005de15f007a8d0100556fdf00339e760035444d0062750100135c4f000e3fa000631a490026989a000b7956005ad35a00145b6c0075b688003ac2a3004aedc60079c506000abd02007c0f4c0030a31a002b8d5000381449002c79760016d214000870e6005a37d8006d0b4e004a26440016e42f005f3372000f846f004dd6a50029f341005782df004648950004236f002411b90067a6df003913b80038d6f50016683a00071da3001c12e100571a5000458f1a0002d94a00382f7100006fd7002238ca0059d805005a897500651af900669c7500799f7e000468af004291d4",
		},
	}

	for _, test := range testCases {
		benchmarkPrecompiled("13", test, bench)
	}
}

// Benchmark NTT_VECMULMOD precompile with crypto standards
func BenchmarkPrecompiledNTT_VECMULMOD(bench *testing.B) {
	testCases := []precompiledTest{
		{
			Name: "VECMULMOD-Falcon-512",
			// Input: header + vecA (NTT_FW output) + vecB (NTT_INV output)
			Input:    "000002000000000000003001" + "0feb0760083604d3264c22900a531f4f0a7719cf2d6a25e11d2b1efd266b249d231d1a3b101d191a29eb2c9a0f121004131a1aa607e6174211560cae11bd13690dd7105e2e6311a8245201c00acb0a190778124c04841f401618205a1ea72f8a07ca2b630ea015a91b710b622f7d2d721dce02fb19f223a81d712906249a1997282e2f04232014550dea04071b8619a7056b1aab1c911c5b02690f550d751ee0296c1336005309200c54040128100faf012909af062606730e052e4e297f2dd1226b2f7623672d080a0404b6169c22d9073822eb2e0f10d1119b2f9f1d75297f28e012f80a120e942d33116913580fdf279a18740b2315702a7f021608d8274c1344022e25e107bb2b6d263414fe2ffd1c0129ae29be0c5101011e6802501fdb019e25e023e402560dfb12ca29812c3f1fe514c4203f0bc9110c104b222a2de505380a7811e00d0a150524a720f429a2211529ad000e03e10255110322c61f7a2662244a2138244a2ce50f6310fe2b7706ca0636123a0d550989298014b80abb1b262cd419dc104721dd187710d50098071629d624fb28080aef2796255f27dc02b711352e4e23e01de41a2c2b061f101fcd099d20cb2f8218f603a015310be626330cd0138b00070aa72b660cf30e0f17f70f782aa1104313fd20550e3120290bd1173a04810edc15b409811b3609c3235a0279232c06400a15202912381dff28970a752a44128428230b011ba903cc1c400d330aae1aba08911a101edd1cd22dfd03da27f6267c2688227512081cc20c520cae1b4712be0954089b2b8b0c48015d10132e2219cc0c5e27510aee1c7412f526fd2f772c7f24a92874280e2e6a08862a4b1e081d3c15f916a006792b5d149f0d2d0ac3117a0ee20f0926c30eb50a6b0a3825ec01e90a16193017860b7c2459014002700cb6023610382e4c1240230c0bf41995062c23352f161623220702a40b982e7224ec21a92cf1189d24b60375026a1c2b022a0ff10a4c086a130f0db70e6c1bd8096a0dd30a4a19bc29910e6311ab01012b8a16660da60c2919a021e407272849177a024715bc08b72c7907c4151c18d014f5060c039d071e09470d370c761307257d038422ff182817002cdf13c31bd42334065e2c941c0c023d257122dd1e8800fe19500d4009c90bdc044b0e0d1c160bdd29322a9706950de3093711fd28b121c319051d4e19f7021126d1239e1efe246610511f092d1816a72a7729d12aa820c411412d83149c083e077a209f23912802039025f3025318ce0b212d19048d15b10fe61dd701de0317007a28e91c07089628570bbf143e27cf0b052fb618f9095f154b29e02a99149d034d0bab245817b801442fbd1dbf2aae1445056518f729b40e3e1be608b1043e019103ff2d610b6a1df403ab2f7d27f018a50546213a2a94162c19220b392e03" + "190108a51daf239f0374093714e82691180e259a29e723a013fc0e0c15e02283112b1cdf16b6233e172808402a3218fc1ecb0dfd10e40a560a6a1ab20eb8003c1c0d27d92b6c115e2a401a0f25af1b27116a18e305821f5322582e1028ef08101d1a2bd206cd1c1e04f316a525e11ce928f11c3a200e10452db10d7b03bf21731fd8258a1da324c9026e259e07c812051e052abf14732f3e2deb2fcf264c1f31140104720a94294821fe2bd01f8d006220e514c726161c49273d2a441b39232a00e027b42be9090019cd127b02f321a92ea529d62e5e14360c5925cf234828d00d0526c00db42ee4138a17cd0b2c25ac150c11712b661f330cf3181412971109062304cd04e523712ffc0903182d139c0d201bee10b920ed20dc0917005912f628be177c152a030714ff2a8b248107530217135c24ac2b49277b1bd612df020120e11e2712f52a4003cd17c729481a5c225222331b3a06581d021553165a0c1900062235145d075f12a717162b0f2cfb033f1b9d1798125917170f681a6927ee23c11ab52cde1176265718182fb9209805631f9f2b2d0cba178d159214d3218d0ab123a6230b1abe060d0ff413e5254a0fd413bd0c4308a90870075a07660c1c2dfc0d9b1dd0171014cf1d131e252012276d006025470beb2cbe24c2007c148b18a60749127510c70fce0f09123703dd04752c5b2df2218f098e11551a76201e1c90201e1a761155098e218f2df22c5b047503dd12370f090fce10c71275074918a6148b007c24c22cbe0beb25470060276d20121e251d1314cf17101dd00d9b2dfc0c1c0766075a087008a90c4313bd0fd4254a13e50ff4060d1abe230b23a60ab1218d14d31592178d0cba2b2d1f9f056320982fb91818265711762cde1ab523c127ee1a690f681717125917981b9d033f2cfb2b0f171612a7075f145d223500060c19165a15531d0206581b3a223322521a5c294817c703cd2a4012f51e2720e1020112df1bd6277b2b4924ac135c0217075324812a8b14ff0307152a177c28be12f60059091720dc20ed10b91bee0d20139c182d09032ffc237104e504cd06231109129718140cf31f332b661171150c25ac0b2c17cd138a2ee40db426c00d0528d0234825cf0c5914362e5e29d62ea521a902f3127b19cd09002be927b400e0232a1b392a44273d1c49261614c720e500621f8d2bd021fe29480a94047214011f31264c2fcf2deb2f3e14732abf1e05120507c8259e026e24c91da3258a1fd8217303bf0d7b2db11045200e1c3a28f11ce925e116a504f31c1e06cd2bd21d1a081028ef2e1022581f53058218e3116a1b2725af1a0f2a40115e2b6c27d91c0d003c0eb81ab20a6a0a5610e40dfd1ecb18fc2a3208401728233e16b61cdf112b228315e00e0c13fc23a029e7259a180e269114e809370374239f1daf08a5",
			Expected: "1aa12f8d25d714790baf164e02b90c9815440d4f0d0213841b3010cb231f1c0526511d9f1aff1fdf15800ed608452b9b255e2c4b16112f2b25da05ef10680c840fd5041818cf0d4d1889094d2f4d07191cfb0fe81e840d5c187202950bc600a427cc009b140e291f0d6f1ccc2865196415831f1e09e920332c1c085d0a0b24010e29076417b11b290dd82c2b063a04a211b40bd60cf8272309150176120024d1282a14450dea2928269e1829267c00de18e22ed9266426ff1ebc2ff40abf25bb1d0001b7055d0f8f03d20da21cb111d2201515042f0619020e5c271012421be9014a2ab12bc915932419277416a018602bdc165216e127621f1728ad23fc2fbb17d6269f226904d616e42f7116141192057801841bc41e8b2c2d2d970dcc05dd11e515f92796223512e827081e720aad16302a110db214b106bf1e40092815fb02a511b504512b0702571caa1c4a135c2b1429c72d250ad524421b6b2d6c22fc26482d77134117e421f2101c29a508f319411d8c0f7b177505b91eaf04122dee156e20f4149d21cf251016e1243209d91ab72a5c27dd2b3409461fc30917245125ed0a97158d0c4418d01d3e1c8a027f0e482bf610c10440073d05b2054212281c9d1e4f03cd116d046b2c4a20fe13aa217d2ce2168d1a780f252ba91f980c800b7512040f3a17d30bb3018f0a47058e0cda2abb29ef196222a51b012bc61fd120ca02b70c0c1325066d0ede1049060216a12cf813552e2c00dc29552924218302712db90ac12c8125072fda1a38188712cc1bc402222ec106e1128e24e6041d0f3e0206087011c516f42562218001f107a407d926c81b432df7078f155d24452ec108c003912b161e5e1a4110731533122d09c629391aab2eec01ae1ce01fcb13e92f9100ef2d0c2d211810260108710a72289522612b882c5f1a4b1df90a3f124407d11079298712242d5808602d280ea524432a20252b0cab2eb30e8904ab0777265124630bdb12af2a6418cb1eb528d90ed112ac28372b220560198024e72945195829581b2800531952156523d8073c2dd9288c0c06249e2bf116d01c7306ce227f291500a11bc308ee09852bf90bc913811dc70d830fba0aed0d3b2d70173005a32b2d2f530d0b24740951120b1b740873093825a927762d8511fe00e1018c2ad812f92e430d3e0ff72996217317e322b61dbf10a0163f12bd23142f622aa51c1a1eaf043a17c02ca41e93286e0bc513630456034b1b0f04fb0e9b00fa1ffb2fb3196907ba032c1da30efd281728942c990d5616da1daf11b82283030c2e1b2fb20aa305230f0c08431b2a0fea11131bbe1b9d0d7b1e03111a050412f924fc1c06241c20c00de2113713a527871bb7249e204d25d624d20f391fba077513cc169e253301a10bb829282558171814ad1c6a161811a00e580f781a0707a6",
		},
		{
			Name: "VECMULMOD-Falcon-1024",
			// Input: header + vecA (NTT_FW output) + vecB (NTT_INV output)
			Input:    "000004000000000000003001" + "0cab2f0119b5265b0f23086d188b2c2008e80ed921550eb00a7e094c09b8232a14ee040a14b12b651c0002c011ff07f62a0e220201d005130b541b842e3223dc051e13071b070af306671c340a0c2a7e0e73238a0fef0fc3168a05621ebd0b1b1ce605311e891b2010dc07690fb42dab2fe90474036b040d0ba6030d187f2cdb053c25a1035d24cc054e0d3b23de2056283e1450142d2a3211ce01c8275e22a41e7915302b2823132432018007272f7519b71e79192a121c1a880674014c01e2101b072e02a52bb822f322ff20bc23c2270d069e1fdc0fe1140526cb12c212af1ba10efb105b188220440004036b108b04a90d951443231803450544055d196128bd08b6201c066a2563241708602d4a0b1b0594109223eb17be102b24c30563065c1cd2272911e4268e2c8529b629061b8c14e22b880b5022ae103d051c26a8199518532b9301591d800c9f18d72e4510132ef30e3811cf2fe5124f09eb16b629f421e527090fee170b166b2d7517fd13e12a291a8914921dbb1c8d2558220e2ca61a0f07d108b92073216b12fe000a2d532cc1151b2c8702b12c140b3526e7020b11a72c520ab410f813b12e862cca20fc12a22ea121c10ceb051f0b491a6204f410b31d690bec25b60487144c128a18ad043a27d1195709fc1cb11adc22ed1ed01b2a100f226c1bb129d916b814c00fc719fb00772846205d096727782dad0e2f12242009226b0470249e15181dc90f9324a21b7c1a5505af03e201cd168b2f891f670652190b2dc50bd014d3040126fb2e421eaa18281f450e150cd10bfc20ce118527082ff91dd319482a922ce31fdb177b0b362365222327de2b771ccb15441fea2b0222951075086500e416e91c0a16e604f90e1a2dce0c7510f3268205b1005b19c32fea08c317fc2a8928e3028e257f0a6a2d1328141b0400c411ac0c200deb28081d160d1008a024de1f101c302e560ade07b5114f18ef237d0c5906c2191705b515fe22421e2e079813001c382cf207272824076804a52794067c1f7612de27021d0b03fe294a13e028580a28132b2ee723c50a9b076823e1204011e905740376084614aa291225f816a52fb10ed8250d1a610e44240b2c560d360b6f0903266b090d0be5133914bb2d5d15991e9b1e2505101d30172e0ffa19a813f51434019308df13481407168112a228801fab1d4a10730f1b298827bf1a2c1f421506234719f608a3223415bd277428742df003f106fb08e91ab42a1c1e770da62b380d65217c1ddb12c12ee10fd5227312751b4d27f11ce417a512d124a8054e12d7292705f81d44148c1f5621fa1cc00de9298a214507bc1c400c6a2c8c08a82bb61578224a20932512292a12fd02ad14d4228101a417490d061edc018721ce1f730ee71ad52a3e055307ff15fc263308b1186023ef247223a5225516ed12e50e29237b071e02472b1627de1b9e06ed049d13cb15522ce421e420ed0a652f29187b059017bf29830310206629cb12dd0eac2b81091a0db302e02adc134d087307262e4625e708940dc1136b1bc9119028462b59172713fb12e10c401e781c1815ef290d08ea2245252a26741a34104c0667192526d304cb1db904e02c282feb1c8c191a28541bf1102415812f1e2d1c252d22b112e0275c1d9025a7070e037d22a6279b27c617412186098917d01e1d1adc0d55065a2244284f023f0a1513bb2425114208ff19b8198308e7038b2ca8293e172f28181c57156708831cd003c1178b15400074199403e1040f2abe1b0125021afb1ad81acf07c72d0903002ef01184000b09ac11d419282ab615bc0f1d12532f51210a01d8010619192da800f420330e732e7403ed141010c82c7421d32d901aab0a9f1d6e212e26030ca51adb2f60193b17691fd917ee0670010b24b203b3222a24b00b241ef71d9814c52f0c0f9604d80a3a25bb2f242ad204de28e70e74158c04f10b8b07172cff14a715cd182019d50e3311ed2cd21cc82d1d19d00d46194318091f06081722cc13d0002c0f6306b82ef51c7f0f68250c012e277021bd0b4c164b2bbc1bad157204f11cf3233220a601e807280fa526a20648199f28640dcb06291adb0d1d1d9909f51a3d24e615b5214906120e08108106de05901f94148620d9107208ab2717278326f1102505fc180b20e421f303c1104522851fef0a5d1b16257826512637034d27a60ee51e5a0a2c2e85220f263b1795178809fe1a180fe92b6627c02099093807800c4328f229de207f2ce426d618c224280d41141511c421f112de053b0ce313e21b2207a01f7821da29781854199e06ec0f6320b7000106580e12017510ec22e72e1e06760d6b2da40cc90a191f610d320bea1e631715245015c6078618ce15232dd00f720687094c296f015e17f22022215208a113bf0c9a1b281ff12c161ae810101001215a09581916022a089e080127ee2be60f6906191fde2cce204817b90e9117f3157809721cc70be00e222a3806712dad0b5d21b3063f2d4702f027890df80648160a192821d100bb12ca284400a012630ce11f522d0725852a4915ed16e70ffb078301d60e25011e05b812830f3620231bc227172f8b191a2b1e2a2002bb09a1039a142c220b1c55262f0dcb19ed290b224c1b2100c71922104b2bd10ea2187b2dec18d513ac15ee044208231f7022a60bd31de415c81ae3140b263c1f3f28630e8506b425e51a6a256c035b215a0ce3295d101807cc205a24a827c30f84009805532c790a11248707ef0cf02be12fcf2d9d2ec306ee2ffb2547246622400ec6140411de28ae16410ffe0f9325c41d69282529992b7a17f008ad29e2290620780a1e166d08ae0cd02ee60be21b6b1ecf1efc23be16931a021203" + "1a011804114a189c0b5d055c173d173406e80f91126e2cb929d004bc1d210595001b2c811b3317f623cd17f8173f2fc527f80d2d1c1825322bc002a61505044a2256104d09bd26142d6c2210167b2f8f2e5017a51080023b246327e901f707ea0d9512051bfa1f9821c8203e14ac1d5414d41c490563194c1d70029800782a5108192f891fb12ffb26d72a7622bc041d247f1296041d28221b5d07f7064d243822d42f9e01c52eb40b0411a50ea506ad14af27702c1f231821dd014f10202a220a3314a927a324900d9a1a15083b1bff09e601bd2d4a02711bc120e309d127f221e11fad087316f4101b2dce208a0cf52b6100561af612fe077e121a12e501d40faf2dfe1b1303280b4527ee19911b7c04dc193f1b3b1c360f9020e1240a08d40c09099b257d1a7228e615e12e7b01d52bd502402f9d2e601c971c780e610836280207d108e414ec1528079a228f2bee13fb25ee279f1ab90f19048600c4290311c91fd7298e07fc1c2b208b0891080b1e790d4524871f26067119b516531fcb01c02ade1f671e2a27d12ebc120027c60399143624f60bed05e62ee713511c5a2d49213623ab1ff62cbb0688286c0e7318b209191b9d108b168f2a5a219f171c1a0a04dd1d7f09961b68251f2dc71785271424302f9a1066165805841b572f472a181e3222e2086426cb14fc0e65186e19e612f100270661252e2440221209c00c4623e5099a0fbf09ca167016e11bc02ff70568120608f6005902ed273808d71a4026ef07db03e121721f2711d903b411b702e7122e1f5f00b20e5525ec1a93217b24542ef828682a541ea3060e135e29fe19cb2515139619010ff70ea6112a042e0b7c26b8218a1957210226911fe81ef501fe07ab279825be06900402089311c1007a0c4d192125ea209a247f013f079a133d2f8e22d1228f04ea04b728af14a305ef1465047a067300450cb024b40a0311f82aa612082cb42b10183227f1000c249b14691dd928ba06670ebe2077254e0ed52e2c0aa5261d2f3829f519a5067e1177073900ef2f302f0424b229c62e2e06eb1ed02e5c04d104011fdb19eb1781038305691e0b29bb290b22ec16921cad2350002f1cda2f71204a112f0e2a0ac60ab30f3d2c86265928a919741a2b2f1a2d942b240c7329a608341319119e15620f5e174b2299161514c3057b18fb0c1a15641fe8263b27ca233f1a931bdf1fa82685277a0b9418861ad7115220df10e01edf0eb40d810ecc0e5d1838106d2bf723c71b361d350b9f0aab2e20157e299e07030a250eb70c4928e7102313611ed90c3300c019101a8d05a617d60962297b09c9198302c400f81b9529161741014b00a40e920fb424ea1e56218e2dcf1f9c0bd31e120767246e180e07ba1b1908ea2b0e28b52b262be31637131d178d131c1e9222aa2dba04eb113c103b1555091f1555103b113c04eb2dba22aa1e92131c178d131d16372be32b2628b52b0e08ea1b1907ba180e246e07671e120bd31f9c2dcf218e1e5624ea0fb40e9200a4014b174129161b9500f802c4198309c9297b096217d605a61a8d191000c00c331ed91361102328e70c490eb70a250703299e157e2e200aab0b9f1d351b3623c72bf7106d18380e5d0ecc0d810eb41edf10e020df11521ad718860b94277a26851fa81bdf1a93233f27ca263b1fe815640c1a18fb057b14c316152299174b0f5e1562119e1319083429a60c732b242d942f1a1a2b197428a926592c860f3d0ab30ac60e2a112f204a2f711cda002f23501cad169222ec290b29bb1e0b05690383178119eb1fdb040104d12e5c1ed006eb2e2e29c624b22f042f3000ef07391177067e19a529f52f38261d0aa52e2c0ed5254e20770ebe066728ba1dd91469249b000c27f118322b102cb412082aa611f80a0324b40cb000450673047a146505ef14a328af04b704ea228f22d12f8e133d079a013f247f209a25ea19210c4d007a11c108930402069025be279807ab01fe1ef51fe8269121021957218a26b80b7c042e112a0ea60ff719011396251519cb29fe135e060e1ea32a5428682ef82454217b1a9325ec0e5500b21f5f122e02e711b703b411d91f27217203e107db26ef1a4008d7273802ed005908f6120605682ff71bc016e1167009ca0fbf099a23e50c4609c022122440252e0661002712f119e6186e0e6514fc26cb086422e21e322a182f471b570584165810662f9a2430271417852dc7251f1b6809961d7f04dd1a0a171c219f2a5a168f108b1b9d091918b20e73286c06882cbb1ff623ab21362d491c5a13512ee705e60bed24f61436039927c612002ebc27d11e2a1f672ade01c01fcb165319b506711f2624870d451e79080b0891208b1c2b07fc298e1fd711c9290300c404860f191ab9279f25ee13fb2bee228f079a152814ec08e407d1280208360e611c781c972e602f9d02402bd501d52e7b15e128e61a72257d099b0c0908d4240a20e10f901c361b3b193f04dc1b7c199127ee0b4503281b132dfe0faf01d412e5121a077e12fe1af600562b610cf5208a2dce101b16f408731fad21e127f209d120e31bc102712d4a01bd09e61bff083b1a150d9a249027a314a90a332a221020014f21dd23182c1f277014af06ad0ea511a50b042eb401c52f9e22d42438064d07f71b5d2822041d1296247f041d22bc2a7626d72ffb1fb12f8908192a51007802981d70194c05631c4914d41d5414ac203e21c81f981bfa12050d9507ea01f727e92463023b108017a52e502f8f167b22102d6c261409bd104d2256044a150502a62bc025321c180d2d27f82fc5173f17f823cd17f61b332c81001b05951d2104bc29d02cb9126e0f9106e81734173d055c0b5d189c114a1804",
			Expected: "23cf2c810a1023cb0d22273c1a3e012c00f81b192fbb2f821b3d22e622d3255c250f1d4c0e8a0065271f18a12e0b02622c8d1b051a7118c800ad1e140cc00a64006b02a51db0144d2866073d1710044920000c71020617361e491fb9041921da07b12a0322ff09260c030674062d1f361c2b227508ff16ba1f7c098e0b4b17c101fa2ce71415133d24382b7f29150ef9102a0f031b5f275e07b01fad261c29be28190e9c0c31213d0e7a06f31bf5197815052ae82cf609630cb1019f1911025d2ff602472fe11634034721e825b81f6412a11069238a238303321b6e2e8d02e226021abd2e012c310c592735055d049002d30ff60b0113ee1e740eec1415145d0ee41a3c03f82e252be9005d29eb03ea2615007d0e402277152e2ab910051cff07a40f622d7105ad02bb159b060f266e06551b860f3b231317fb0ef7261520d405d82cce2edb11760f001ea72c3820cf24f11fd2110c2aae094d1fa117c406bb05090bd816340da215541ce71f292bdb16bb16662e0f2e540d8e05672a2b2c8d20e007bd2efb06df07f9240c04e10db41c3621df03b22aec1fb202fb16432a3d123614040fd80dd82559295b295c0d432e41004a18eb282a03331e621370140526d904d60a0515e71e690bd92fba0e9d146e1fb11b3f000221fb2cf905782056287c091e0f930c2c24fb03512fc90ff10347110b1221012c28a61ea70a6d2d7a113a18a41002078b1f791803200b2889244607b0229710c419cd1bfe1e602297124201b1251e01a516d71506021d03651a0b2ec32af00f0f2d870ec52b8d13120a19066219900cc70cf018b61a9e023e226d24ec00c52dbe2b5c0bf013e71a03005e1bb612c011292c142005086d0aee2f7e0d41108819cf10e12e1d0c7c25c629572b5e2d0e2e161a532d4f1da121ce1b052d3d027b01d20e522ee50c09059a132a13ad2a2711c60c6f131416e22f812eb007f81e4d04c30f6e2d9304870483211729cc08d01ca216e4147c007b18272b23037705d31e4e10e71a87220d26760bd30c5517941cb51db412b8128f18f5096b07b62f960e41137b06ca08ac19572ca505f6290319d5203812a905011d750a2010950d3f22c009eb12f029ec2af72b4a0917004d0069171d08592cbf17e50359038d091d04e023ce0162070f144623e720a11a4e24e31c0a14ac226a0b2422cb17b01d991f680bc911fa22ad01222cb41f4023d42df618e91e8d2bb3030817482686023f218504ed136720e21e3f00aa005222b7164d0ccb2cc10d151cc0201d07ad2e5d0f0925a019be0c400cdc1fb6200c1c9c246326452c5e0c55051027692a1c158b20ea2df91105007c0df820fd100307ec16d11952089f0286217502a9119b057524bc23b31fce1ae1225300052d1604b00a80185c245f01b4050327602d6a2e271c6c28eb02e01dfc038103242a53015a067a22f222f228a31286262b1336171e26c11122156223a61f342ab91f3209bb088c22ca2af816e1110625410b14242614fc271624900c762d130c771730286a06ac0f3428fa28702c28010308ed05e0139104320d352fd00a2a1e4b23b51efb138e08e811a20ea426c92cc826d50277245101ec1a38147d2a3028db1dd8010602732970119a061e00d518a528bf112e1f93160d101f23a0089d2abc2c7d26152e870d04233014d212a4135b07ba1f520bcf07d1082a005e0b7c2bcd26931e951a430f00233c057c07ff053f12ef2c0225e31d9c241121842f05206f0fdc0f25013a0d0d27462ebe05ef1b8c15be21c4185504e702af109e08c80ff52eb80e6218de2c4b12150c7628732ead0740162729cd2eb1049521cb107c2ff81aac026e17af2cbc29de023c06c803010f201cba1e8f28f5115d13121243223e01f518cf049012ec027306e82d450a6f03081bd9233c07ad0ad320660a5a206b1a5525ef2ff91e4c2234141110f3057c022c2013059f2af10541212c1762047d061105822cc000ce25b92d000de7136b189e1ca8288c10aa2dc02e90140327e513be294429c624a808a7095e0cd81ea11cca24bc0d870b201efd1d750f572791263b1d3e217719b60f02167b0a9716351f3326f313402dd10c6e2c0c11a802e7165f00dc108e0c3719120ed42f6b286208bf03fe1596189a29be1b0513a427f215790f792c99137f2a910264148a1ddf1072199605d117e118f22eca18f710cc0dd80d4d0985061116582e962e2a2b790e1107c61dea2aaa02901ce0046916ef066d13a12f1d11ac10542ce8084121370e362ff425b6176b26c52b8711f822b111ee168f068927b411cb0dfd048b26881ed311bc2ebc0095121d001f158c22fb053f094118782745248b2f8119791042010f08a728c2242205490bd1268f23a7224d0309160d198020272a421a1129f701be0db916c624832d0b14ba20c91f6410a1099616691d580404179d13192c870580110101432d450b4e13991d231b8f256729840fc42b11151115e424f003da060c1baa22030e56066f0fbc175020bd08d82bf018b505c301fd01491fbb296208f51ce82dc503241f251c252e6f12d424501ba714042347079d279f00a308e12fec1a8f2bd613c305fa2cd51c400b6d187100e4066d27c2092510411e3213d42f8f11920a61214b1d2b083d13210b4a10661bc91b161e3a0c66021501061f2e1cff04d616cd0a4d0d5302332b0b05690d642e0428300ea40904260825c021e80f281ef808be0f6d1fff230a1986003f281a0aa2091e2516237406f212230e8526371c12237305050919259419b32c3c13710166217e20380877051221431e7126402d9a12cd2b801789074003221abf09b923c515091a0805a80c750b111f1b217c01691b1b2d911e022d37270a", // Don't need to verify output in benchmark
		},
		{
			Name: "VECMULMOD-ML-DSA-256",
			// Input: header + vecA (NTT_FW output) + vecB (NTT_INV output)
			Input:    "0000010000000000007fe001" + "ffc0e5f5ffccf7a7ffd16090004edaa0ffe71eb5ff73c3cbffe816a4ffaa68e8002d128900232447fffbc48800687808ffcc23a6ff8887d4ffd085b7ffb886f7ff50787aff5f29c0ff91d975ff1ede45ff5455b0ff39e7daff996f80ff570e8affde03f2ff9927c0ffbd960aff90b5340039e72dfff657710005c979ff99167100589a8900d65079ffedd0140059c60200696427004eba3d00122b9600717966002e890d001d9f150089e6aa006269b8fff32611ff898dc9001ae6bfffaa09dbffb50b370023ba61003b4460001d4eb80041022c00244598006c1331005829630014c6bbffef9ca5ffacd6f3ff8da3e5004334eaffc85ba4ffb04e46fff5185cffa02252ffddd8ceff977426ffe45376000d940c000b7406ff830114ffa8512effdbfd160058d400ff726e3affeaabf400413b6c00237720006a08a500ba812bffe9ae30fff4ced2ff779d7fff74f673ffefd00bffec82b1ff828eb1ffbfcf67006691eb008a7261001b0fd3007e964dffecc411ffb8aaa70039d446002be95e0038fb8d00946b6f005188a6fff8a1c20073dc960046207c000c2ae60060c30400187a800007feecffe2e96e00255b2affa9a238ff8327a0ffa2bcc90013becb00b1379b00401b0f006fd627004768f70105411f00a529f500a4942500be8a8f002d6ba300307ec7006c48b50093fb4500086cc1001336a7ffbf9f24ffa40db0fffa327a0044f6b4ffb3861dffe7664dfff7f812ffb50442002b72f1ffffb0a30041adb6fffc3596002dc3aa000bb9eeff5cb969ffadb0fdffd84203ffc2f9c3ff64ccdeff53b11efffcdcedff7e51a3fffabc1effceade6ff681582ffa89796ffabe545ffd95673ff5055fbff67c95d0012ae2b00620801fff4a23affa211d2fff4817aff998fe00004658fffe9c0afffa9a064001427ec0016ff05008496dbff624a1bffdcc465fff043fd0015d6b3003886f2ffe11fe4ffcfc63000427a42001b189f0015584100cfe9e800561e18fffba85d002204bb000b35bf00463b1900638201fff43d6500a28da100736c6dffff143fffd1d0efffb8d547001f52c7ffffecbe000139320064c65fffe78021ffd097abffdbc8770019b65b0036a513ffb34364ff64d086ff8a1165ffed3815ffd545fcffd92542ffcd17f0ff780ede00151f9eff9a21a0ffedf6e2004b78c4002395f9ffa810d500096b7a000d2bccffd3dd0cff6ff9c0ff97ee1dffd4f15fff828229ffc7f9c50008b217ffe521eb00526069006be427000ee455005cfeef0043b45f005a72a10042edfe0019c3ae00384bde006d2092ffe995990036989bffc384ea0018486e001ce2bf001dc2d50028952600311ff2008755df003c760900a4620b00c18e7d00677b50007eb5a8002e71ac003bdafa0053c84c0042e5760003951eff91d60cfffa06c8006bb1b6" + "003ff081004291d4000468af00799f7e00669c7500651af9005a89750059d805002238ca00006fd700382f710002d94a00458f1a00571a50001c12e100071da30016683a0038d6f5003913b80067a6df002411b90004236f00464895005782df0029f341004dd6a5000f846f005f33720016e42f004a2644006d0b4e005a37d8000870e60016d214002c797600381449002b8d500030a31a007c0f4c000abd020079c506004aedc6003ac2a30075b68800145b6c005ad35a000b79560026989a00631a49000e3fa000135c4f006275010035444d00339e7600556fdf007a8d01005de15f002ac82a00386a9a002d793b001837c00009210500661b6b001e9fa0002f6cf200175ba7007907d700167d67003277790006a2a7000fd2a900006e91006b9e0d00112f3b00706f6b007c67ea0024a6b30052192500732bdf006772110019296d0035d1b100559a4a003a5d82007fd5a3006572750008b23d0057b5490035d9970074807b0032aeac003cfc57000811cf006ad624001ddedd0033882c0016cc400039949900001c2b007987380038cd590067112c0025e7bc00697a00006b75db0006583c00089e110046da1b0036aac1007b71ce000890c100040bf2001adb60003b32290043c97b000f9963007149b5005f966000006b3e0015326a006efc56007c0825005d941e00426a5c0056867200203cc600603ae20018883a005c005c0018883a00603ae200203cc60056867200426a5c005d941e007c0825006efc560015326a00006b3e005f9660007149b5000f99630043c97b003b3229001adb6000040bf2000890c1007b71ce0036aac10046da1b00089e110006583c006b75db00697a000025e7bc0067112c0038cd590079873800001c2b003994990016cc400033882c001ddedd006ad624000811cf003cfc570032aeac0074807b0035d9970057b5490008b23d00657275007fd5a3003a5d8200559a4a0035d1b10019296d0067721100732bdf005219250024a6b3007c67ea00706f6b00112f3b006b9e0d00006e91000fd2a90006a2a70032777900167d67007907d700175ba7002f6cf2001e9fa000661b6b00092105001837c0002d793b00386a9a002ac82a005de15f007a8d0100556fdf00339e760035444d0062750100135c4f000e3fa000631a490026989a000b7956005ad35a00145b6c0075b688003ac2a3004aedc60079c506000abd02007c0f4c0030a31a002b8d5000381449002c79760016d214000870e6005a37d8006d0b4e004a26440016e42f005f3372000f846f004dd6a50029f341005782df004648950004236f002411b90067a6df003913b80038d6f50016683a00071da3001c12e100571a5000458f1a0002d94a00382f7100006fd7002238ca0059d805005a897500651af900669c7500799f7e000468af004291d4",
			Expected: "000b7dba00087e62002c9df400635b15002b6ba800690f3a00294af2006aaf120042682b0015a1e50076d4160078a68400456ead0040bad5002f50330047a46f000a7d8d000a5275006885850075785e001a47f600167eb8007964c700593bf700275c8e002958f3004a857c004a481d000aa7b70061f9c10055868f0017319d00218dd100656c530003b08800307fe00020e238001a4f8e0022b9bb00633960000f470b001abfe90020f43100222222007a45eb00196494000a413b007e67ca005b1fed0060c07d0017e07e00073605002da2e1006e7fc6001bc16f003312b40058d99d0054d6ac003a1c92002a2da300751b210064e71c00425bdd00099a0b0050576600300571004d894200079076000a31d4000c63c6002af5a9003deadf00605c9900562c16003ef224007778f5000cc22d000ab2a700101ec000193a00000f9ebd005f07130043f95800020329007b0ca7006983110066fa1200249e52005e730a00701275005491fa002ba1120029a1790063d2670026724600721a0a005d768d005fac7e0062a9ed0055b110007016e80016eba30049ef940048d7da001b596b003a59c1005afa21004f6ec00011283a003e67cd004822c5000734f000299acd0004f66400789aca000b207800098e220035f3d700078df00046378a0015d0dd0062811b0068cb47002d83100068a09b0006712b001d3827000bdd93002d50a00060e9d30059049600245f36007353240040ad91006f8082004e8c8a002ac22200189cf800296acb001f294a0007cebc0002d13e007163b700141615002a75c7003a0c450016b478007814500042bed80068c708002fc673005fed640044d87b0000b1e8004993850039b80a005e4fb600135cce00057a3f00207a310038631a001de279006d0788003058e9000968370007845a006260160064ef3b006382f1006bf44200316f37000d228a006643ba0029fd690045727800250f1d0019bdca0058c9f7002a76e0001be774006485a500019775006b4c96002ca5a40030b9930072b661007d34230018b7db0026d7d200162287006fab37004e6416004b5ac10005a23f000d56ee003c81650049d7b5003dd3790056e8b7007f84ef0005dc57000337e70040bd330011c47b00720912007319bb00199826002d927c0021f12c0029196700104035002225fa00099dc8002271670014ee930022e4110077d1c50048ebaf001f3a9d002221180056df5100024eec00670f61000157d300745e4c00474364005b25f9000084d20007dab700610870007b49f8004fa450004765770038f4cd002a0c08007dd7e3002f665c00283cf60025e1a3003509530014be27007aa5490007f0d30025fddd0072ef24002cf541001906a500083946000be3d00067291a002c251a0044476600700eca0069b5070034d77200161061", // Don't need to verify output in benchmark
		},
	}

	for _, test := range testCases {
		benchmarkPrecompiled("14", test, bench)
	}
}

// Benchmark NTT_VECADDMOD precompile with crypto standards
func BenchmarkPrecompiledNTT_VECADDMOD(bench *testing.B) {
	testCases := []precompiledTest{
		{
			Name: "VECADDMOD-Falcon-512",
			// Input: header + vecA (NTT_FW output) + vecB (NTT_INV output)
			Input:    "000002000000000000003001" + "0feb0760083604d3264c22900a531f4f0a7719cf2d6a25e11d2b1efd266b249d231d1a3b101d191a29eb2c9a0f121004131a1aa607e6174211560cae11bd13690dd7105e2e6311a8245201c00acb0a190778124c04841f401618205a1ea72f8a07ca2b630ea015a91b710b622f7d2d721dce02fb19f223a81d712906249a1997282e2f04232014550dea04071b8619a7056b1aab1c911c5b02690f550d751ee0296c1336005309200c54040128100faf012909af062606730e052e4e297f2dd1226b2f7623672d080a0404b6169c22d9073822eb2e0f10d1119b2f9f1d75297f28e012f80a120e942d33116913580fdf279a18740b2315702a7f021608d8274c1344022e25e107bb2b6d263414fe2ffd1c0129ae29be0c5101011e6802501fdb019e25e023e402560dfb12ca29812c3f1fe514c4203f0bc9110c104b222a2de505380a7811e00d0a150524a720f429a2211529ad000e03e10255110322c61f7a2662244a2138244a2ce50f6310fe2b7706ca0636123a0d550989298014b80abb1b262cd419dc104721dd187710d50098071629d624fb28080aef2796255f27dc02b711352e4e23e01de41a2c2b061f101fcd099d20cb2f8218f603a015310be626330cd0138b00070aa72b660cf30e0f17f70f782aa1104313fd20550e3120290bd1173a04810edc15b409811b3609c3235a0279232c06400a15202912381dff28970a752a44128428230b011ba903cc1c400d330aae1aba08911a101edd1cd22dfd03da27f6267c2688227512081cc20c520cae1b4712be0954089b2b8b0c48015d10132e2219cc0c5e27510aee1c7412f526fd2f772c7f24a92874280e2e6a08862a4b1e081d3c15f916a006792b5d149f0d2d0ac3117a0ee20f0926c30eb50a6b0a3825ec01e90a16193017860b7c2459014002700cb6023610382e4c1240230c0bf41995062c23352f161623220702a40b982e7224ec21a92cf1189d24b60375026a1c2b022a0ff10a4c086a130f0db70e6c1bd8096a0dd30a4a19bc29910e6311ab01012b8a16660da60c2919a021e407272849177a024715bc08b72c7907c4151c18d014f5060c039d071e09470d370c761307257d038422ff182817002cdf13c31bd42334065e2c941c0c023d257122dd1e8800fe19500d4009c90bdc044b0e0d1c160bdd29322a9706950de3093711fd28b121c319051d4e19f7021126d1239e1efe246610511f092d1816a72a7729d12aa820c411412d83149c083e077a209f23912802039025f3025318ce0b212d19048d15b10fe61dd701de0317007a28e91c07089628570bbf143e27cf0b052fb618f9095f154b29e02a99149d034d0bab245817b801442fbd1dbf2aae1445056518f729b40e3e1be608b1043e019103ff2d610b6a1df403ab2f7d27f018a50546213a2a94162c19220b392e03" + "190108a51daf239f0374093714e82691180e259a29e723a013fc0e0c15e02283112b1cdf16b6233e172808402a3218fc1ecb0dfd10e40a560a6a1ab20eb8003c1c0d27d92b6c115e2a401a0f25af1b27116a18e305821f5322582e1028ef08101d1a2bd206cd1c1e04f316a525e11ce928f11c3a200e10452db10d7b03bf21731fd8258a1da324c9026e259e07c812051e052abf14732f3e2deb2fcf264c1f31140104720a94294821fe2bd01f8d006220e514c726161c49273d2a441b39232a00e027b42be9090019cd127b02f321a92ea529d62e5e14360c5925cf234828d00d0526c00db42ee4138a17cd0b2c25ac150c11712b661f330cf3181412971109062304cd04e523712ffc0903182d139c0d201bee10b920ed20dc0917005912f628be177c152a030714ff2a8b248107530217135c24ac2b49277b1bd612df020120e11e2712f52a4003cd17c729481a5c225222331b3a06581d021553165a0c1900062235145d075f12a717162b0f2cfb033f1b9d1798125917170f681a6927ee23c11ab52cde1176265718182fb9209805631f9f2b2d0cba178d159214d3218d0ab123a6230b1abe060d0ff413e5254a0fd413bd0c4308a90870075a07660c1c2dfc0d9b1dd0171014cf1d131e252012276d006025470beb2cbe24c2007c148b18a60749127510c70fce0f09123703dd04752c5b2df2218f098e11551a76201e1c90201e1a761155098e218f2df22c5b047503dd12370f090fce10c71275074918a6148b007c24c22cbe0beb25470060276d20121e251d1314cf17101dd00d9b2dfc0c1c0766075a087008a90c4313bd0fd4254a13e50ff4060d1abe230b23a60ab1218d14d31592178d0cba2b2d1f9f056320982fb91818265711762cde1ab523c127ee1a690f681717125917981b9d033f2cfb2b0f171612a7075f145d223500060c19165a15531d0206581b3a223322521a5c294817c703cd2a4012f51e2720e1020112df1bd6277b2b4924ac135c0217075324812a8b14ff0307152a177c28be12f60059091720dc20ed10b91bee0d20139c182d09032ffc237104e504cd06231109129718140cf31f332b661171150c25ac0b2c17cd138a2ee40db426c00d0528d0234825cf0c5914362e5e29d62ea521a902f3127b19cd09002be927b400e0232a1b392a44273d1c49261614c720e500621f8d2bd021fe29480a94047214011f31264c2fcf2deb2f3e14732abf1e05120507c8259e026e24c91da3258a1fd8217303bf0d7b2db11045200e1c3a28f11ce925e116a504f31c1e06cd2bd21d1a081028ef2e1022581f53058218e3116a1b2725af1a0f2a40115e2b6c27d91c0d003c0eb81ab20a6a0a5610e40dfd1ecb18fc2a3208401728233e16b61cdf112b228315e00e0c13fc23a029e7259a180e269114e809370374239f1daf08a5",
			Expected: "28ec100525e5287229c02bc71f3b15df22850f682750198001262d090c4a171f0447071926d30c57111204d90943290001e428a318ca21981bc02760207513a529e4083629ce23061e911bcf0079254018e22b2f0a060e92086f1e691795079924e42734156d01c620642207255d1a5a16be1f3509ff03ec1b21068028590b091805248d10c2091d105829a5234e2bac2370156901031b9800530f2303c00e100d6c17a80ae702672e522fd1179c1011220e1e762c3c22bc0541289114b720fa234b27291f4f060723d11731198f148105dc1cc02c6c25071df4256d10bc224e05e409b717c60d7710bc29361e84058a0ca529e5068804a207711a2a1b6f0854196706fb2ac62b2c2b682f372d2b13982921159b0a762d3e21dd277f02a902d02a5c0d5b090d055d22fa0d541e01039121fc282014ea071108862c2105082fe62619289f24d5074918d20c6d1a3b13fd13661bdf1b480a391f572656091f2b932668167e05942ba90f8b26790c0c28710a0921d329d21fae20a008e72f2102a80ee6178816b921bd1833008e108d21300c791974202704c1227c0d270a3119680d6804da21580e9d23f12a200eea14592fa11d5a2d0e082a21660afa1c971802242e1a6b015a17171f7618782b182e210f630fd81fe71c2e10ba15160ead04b324771e8316f61fa32582188a2d6d0da027cf2ed4211d27cf13a3017d2cae0e1c15262a9314b923d901b02c90199a002620b511101ce529c3185f2ad70151241b16a2186528721b3d23452e60074e1d2203be2cc0096b2fd11e231fab195a19e32f591c2f0587212614ce2ffa1731003022c91c46135b0c722ab613311b18220f13371bd702da02cd2d86235a01a51afb1a022dc50a7b29920538207f23a0296a2e2c022510541151212d2b892f1e271927982e3b2d7f23cc14dd179712a804742312180d2fef1b7f1036056d015c143924f625f427b90cb2257627302b9212dc2456046b2f0a1e00076b05942d16266b0fce15bf105803f422d20d512ee6110c072024a1015a04a007412e931ce2058d2f041ac31075207d0242092c0d9c01450de726252b672d0912ff22d002831ab8224302211e330d49170e21e225dc0dbf09e30c920f1b190212b710c91a692c1324151485217b1379031c164005b1038f052b0136074e0620206e16df2cab22aa2a1c125f183d1d920b021695248b06830ad112ce154924340e3b1e46118a1165187b0bd5026f166113af224b023e2dc8275212112750057c014006372261050704111a012a6e2c5614d909f408ab2ee91d9400f814f506a51aae2b1219c010b11c6f1adc0ea7236e0f8a0b3d26040c751f5a0be7030f02690bae0a122ea308aa030f1e61132801f325660f231f67211d12bc26821340197601ef274b29631d8900b22bd7062103ca19a00cc028e806a7",
		},
		{
			Name: "VECADDMOD-Falcon-1024",
			// Input: header + vecA (NTT_FW output) + vecB (NTT_INV output)
			Input:    "000004000000000000003001" + "0cab2f0119b5265b0f23086d188b2c2008e80ed921550eb00a7e094c09b8232a14ee040a14b12b651c0002c011ff07f62a0e220201d005130b541b842e3223dc051e13071b070af306671c340a0c2a7e0e73238a0fef0fc3168a05621ebd0b1b1ce605311e891b2010dc07690fb42dab2fe90474036b040d0ba6030d187f2cdb053c25a1035d24cc054e0d3b23de2056283e1450142d2a3211ce01c8275e22a41e7915302b2823132432018007272f7519b71e79192a121c1a880674014c01e2101b072e02a52bb822f322ff20bc23c2270d069e1fdc0fe1140526cb12c212af1ba10efb105b188220440004036b108b04a90d951443231803450544055d196128bd08b6201c066a2563241708602d4a0b1b0594109223eb17be102b24c30563065c1cd2272911e4268e2c8529b629061b8c14e22b880b5022ae103d051c26a8199518532b9301591d800c9f18d72e4510132ef30e3811cf2fe5124f09eb16b629f421e527090fee170b166b2d7517fd13e12a291a8914921dbb1c8d2558220e2ca61a0f07d108b92073216b12fe000a2d532cc1151b2c8702b12c140b3526e7020b11a72c520ab410f813b12e862cca20fc12a22ea121c10ceb051f0b491a6204f410b31d690bec25b60487144c128a18ad043a27d1195709fc1cb11adc22ed1ed01b2a100f226c1bb129d916b814c00fc719fb00772846205d096727782dad0e2f12242009226b0470249e15181dc90f9324a21b7c1a5505af03e201cd168b2f891f670652190b2dc50bd014d3040126fb2e421eaa18281f450e150cd10bfc20ce118527082ff91dd319482a922ce31fdb177b0b362365222327de2b771ccb15441fea2b0222951075086500e416e91c0a16e604f90e1a2dce0c7510f3268205b1005b19c32fea08c317fc2a8928e3028e257f0a6a2d1328141b0400c411ac0c200deb28081d160d1008a024de1f101c302e560ade07b5114f18ef237d0c5906c2191705b515fe22421e2e079813001c382cf207272824076804a52794067c1f7612de27021d0b03fe294a13e028580a28132b2ee723c50a9b076823e1204011e905740376084614aa291225f816a52fb10ed8250d1a610e44240b2c560d360b6f0903266b090d0be5133914bb2d5d15991e9b1e2505101d30172e0ffa19a813f51434019308df13481407168112a228801fab1d4a10730f1b298827bf1a2c1f421506234719f608a3223415bd277428742df003f106fb08e91ab42a1c1e770da62b380d65217c1ddb12c12ee10fd5227312751b4d27f11ce417a512d124a8054e12d7292705f81d44148c1f5621fa1cc00de9298a214507bc1c400c6a2c8c08a82bb61578224a20932512292a12fd02ad14d4228101a417490d061edc018721ce1f730ee71ad52a3e055307ff15fc263308b1186023ef247223a5225516ed12e50e29237b071e02472b1627de1b9e06ed049d13cb15522ce421e420ed0a652f29187b059017bf29830310206629cb12dd0eac2b81091a0db302e02adc134d087307262e4625e708940dc1136b1bc9119028462b59172713fb12e10c401e781c1815ef290d08ea2245252a26741a34104c0667192526d304cb1db904e02c282feb1c8c191a28541bf1102415812f1e2d1c252d22b112e0275c1d9025a7070e037d22a6279b27c617412186098917d01e1d1adc0d55065a2244284f023f0a1513bb2425114208ff19b8198308e7038b2ca8293e172f28181c57156708831cd003c1178b15400074199403e1040f2abe1b0125021afb1ad81acf07c72d0903002ef01184000b09ac11d419282ab615bc0f1d12532f51210a01d8010619192da800f420330e732e7403ed141010c82c7421d32d901aab0a9f1d6e212e26030ca51adb2f60193b17691fd917ee0670010b24b203b3222a24b00b241ef71d9814c52f0c0f9604d80a3a25bb2f242ad204de28e70e74158c04f10b8b07172cff14a715cd182019d50e3311ed2cd21cc82d1d19d00d46194318091f06081722cc13d0002c0f6306b82ef51c7f0f68250c012e277021bd0b4c164b2bbc1bad157204f11cf3233220a601e807280fa526a20648199f28640dcb06291adb0d1d1d9909f51a3d24e615b5214906120e08108106de05901f94148620d9107208ab2717278326f1102505fc180b20e421f303c1104522851fef0a5d1b16257826512637034d27a60ee51e5a0a2c2e85220f263b1795178809fe1a180fe92b6627c02099093807800c4328f229de207f2ce426d618c224280d41141511c421f112de053b0ce313e21b2207a01f7821da29781854199e06ec0f6320b7000106580e12017510ec22e72e1e06760d6b2da40cc90a191f610d320bea1e631715245015c6078618ce15232dd00f720687094c296f015e17f22022215208a113bf0c9a1b281ff12c161ae810101001215a09581916022a089e080127ee2be60f6906191fde2cce204817b90e9117f3157809721cc70be00e222a3806712dad0b5d21b3063f2d4702f027890df80648160a192821d100bb12ca284400a012630ce11f522d0725852a4915ed16e70ffb078301d60e25011e05b812830f3620231bc227172f8b191a2b1e2a2002bb09a1039a142c220b1c55262f0dcb19ed290b224c1b2100c71922104b2bd10ea2187b2dec18d513ac15ee044208231f7022a60bd31de415c81ae3140b263c1f3f28630e8506b425e51a6a256c035b215a0ce3295d101807cc205a24a827c30f84009805532c790a11248707ef0cf02be12fcf2d9d2ec306ee2ffb2547246622400ec6140411de28ae16410ffe0f9325c41d69282529992b7a17f008ad29e2290620780a1e166d08ae0cd02ee60be21b6b1ecf1efc23be16931a021203" + "1a011804114a189c0b5d055c173d173406e80f91126e2cb929d004bc1d210595001b2c811b3317f623cd17f8173f2fc527f80d2d1c1825322bc002a61505044a2256104d09bd26142d6c2210167b2f8f2e5017a51080023b246327e901f707ea0d9512051bfa1f9821c8203e14ac1d5414d41c490563194c1d70029800782a5108192f891fb12ffb26d72a7622bc041d247f1296041d28221b5d07f7064d243822d42f9e01c52eb40b0411a50ea506ad14af27702c1f231821dd014f10202a220a3314a927a324900d9a1a15083b1bff09e601bd2d4a02711bc120e309d127f221e11fad087316f4101b2dce208a0cf52b6100561af612fe077e121a12e501d40faf2dfe1b1303280b4527ee19911b7c04dc193f1b3b1c360f9020e1240a08d40c09099b257d1a7228e615e12e7b01d52bd502402f9d2e601c971c780e610836280207d108e414ec1528079a228f2bee13fb25ee279f1ab90f19048600c4290311c91fd7298e07fc1c2b208b0891080b1e790d4524871f26067119b516531fcb01c02ade1f671e2a27d12ebc120027c60399143624f60bed05e62ee713511c5a2d49213623ab1ff62cbb0688286c0e7318b209191b9d108b168f2a5a219f171c1a0a04dd1d7f09961b68251f2dc71785271424302f9a1066165805841b572f472a181e3222e2086426cb14fc0e65186e19e612f100270661252e2440221209c00c4623e5099a0fbf09ca167016e11bc02ff70568120608f6005902ed273808d71a4026ef07db03e121721f2711d903b411b702e7122e1f5f00b20e5525ec1a93217b24542ef828682a541ea3060e135e29fe19cb2515139619010ff70ea6112a042e0b7c26b8218a1957210226911fe81ef501fe07ab279825be06900402089311c1007a0c4d192125ea209a247f013f079a133d2f8e22d1228f04ea04b728af14a305ef1465047a067300450cb024b40a0311f82aa612082cb42b10183227f1000c249b14691dd928ba06670ebe2077254e0ed52e2c0aa5261d2f3829f519a5067e1177073900ef2f302f0424b229c62e2e06eb1ed02e5c04d104011fdb19eb1781038305691e0b29bb290b22ec16921cad2350002f1cda2f71204a112f0e2a0ac60ab30f3d2c86265928a919741a2b2f1a2d942b240c7329a608341319119e15620f5e174b2299161514c3057b18fb0c1a15641fe8263b27ca233f1a931bdf1fa82685277a0b9418861ad7115220df10e01edf0eb40d810ecc0e5d1838106d2bf723c71b361d350b9f0aab2e20157e299e07030a250eb70c4928e7102313611ed90c3300c019101a8d05a617d60962297b09c9198302c400f81b9529161741014b00a40e920fb424ea1e56218e2dcf1f9c0bd31e120767246e180e07ba1b1908ea2b0e28b52b262be31637131d178d131c1e9222aa2dba04eb113c103b1555091f1555103b113c04eb2dba22aa1e92131c178d131d16372be32b2628b52b0e08ea1b1907ba180e246e07671e120bd31f9c2dcf218e1e5624ea0fb40e9200a4014b174129161b9500f802c4198309c9297b096217d605a61a8d191000c00c331ed91361102328e70c490eb70a250703299e157e2e200aab0b9f1d351b3623c72bf7106d18380e5d0ecc0d810eb41edf10e020df11521ad718860b94277a26851fa81bdf1a93233f27ca263b1fe815640c1a18fb057b14c316152299174b0f5e1562119e1319083429a60c732b242d942f1a1a2b197428a926592c860f3d0ab30ac60e2a112f204a2f711cda002f23501cad169222ec290b29bb1e0b05690383178119eb1fdb040104d12e5c1ed006eb2e2e29c624b22f042f3000ef07391177067e19a529f52f38261d0aa52e2c0ed5254e20770ebe066728ba1dd91469249b000c27f118322b102cb412082aa611f80a0324b40cb000450673047a146505ef14a328af04b704ea228f22d12f8e133d079a013f247f209a25ea19210c4d007a11c108930402069025be279807ab01fe1ef51fe8269121021957218a26b80b7c042e112a0ea60ff719011396251519cb29fe135e060e1ea32a5428682ef82454217b1a9325ec0e5500b21f5f122e02e711b703b411d91f27217203e107db26ef1a4008d7273802ed005908f6120605682ff71bc016e1167009ca0fbf099a23e50c4609c022122440252e0661002712f119e6186e0e6514fc26cb086422e21e322a182f471b570584165810662f9a2430271417852dc7251f1b6809961d7f04dd1a0a171c219f2a5a168f108b1b9d091918b20e73286c06882cbb1ff623ab21362d491c5a13512ee705e60bed24f61436039927c612002ebc27d11e2a1f672ade01c01fcb165319b506711f2624870d451e79080b0891208b1c2b07fc298e1fd711c9290300c404860f191ab9279f25ee13fb2bee228f079a152814ec08e407d1280208360e611c781c972e602f9d02402bd501d52e7b15e128e61a72257d099b0c0908d4240a20e10f901c361b3b193f04dc1b7c199127ee0b4503281b132dfe0faf01d412e5121a077e12fe1af600562b610cf5208a2dce101b16f408731fad21e127f209d120e31bc102712d4a01bd09e61bff083b1a150d9a249027a314a90a332a221020014f21dd23182c1f277014af06ad0ea511a50b042eb401c52f9e22d42438064d07f71b5d2822041d1296247f041d22bc2a7626d72ffb1fb12f8908192a51007802981d70194c05631c4914d41d5414ac203e21c81f981bfa12050d9507ea01f727e92463023b108017a52e502f8f167b22102d6c261409bd104d2256044a150502a62bc025321c180d2d27f82fc5173f17f823cd17f61b332c81001b05951d2104bc29d02cb9126e0f9106e81734173d055c0b5d189c114a1804",
			Expected: "26ac17042aff0ef61a800dc92fc813530fd01e6a03c20b68044d0e0826d928bf1509008a2fe4135a0fcc1ab8293e07ba22052f2f1de82a4507131e2a133628262774235424c4010603d20e4320872a0c0cc20b2e206f11fe0aec2d4b20b413052a7b17360a820ab702a327a724601afe14bc20bd08ce1d59291605a518f7272b0d552529230e24c62c2507b0169924731cbc26e6184a22532d2b09bf2dab16db114c14cd2ced21c62f36132515cc06212e6615e8154805330c6407c3116c2c041a4e1bd72a482047008c0d1328f70fc000f2085b1d2512522fc617ad1c930aa00d812ea818ce2f76005e2dd223f51d8000090deb2f3906150ac3175e18421b35086b06b30b2e099200a71c0421f118c50ff71ed32bcd1020274e010b18cc0e371265266d1ca52c561f73126528302adb176017222b2409af0f442cb5137d2ede119620240476164502a714390b652a32240e24e005d62c880efd16d50aaf0fb80bbc11bb209617ea033506f5060520080259076d0f0f03b7242c06410baa11d82e6614ec273826e31843202624fe27d000eb10f60a10087308972afa1e8613402f5402dc1ffc2aaa0db21a3926f10b3c09ad1bbb1a3d024b237a2f792ce8017d1efe15900ae71582111d29a612122a0f0fc0286a276a29bd205422350632223318e7095b02f02ad0127b0ed4251d2d2e29ad2cec009e2ea7158a2da71989076c1a75060829a302290e3a0b0d2bf909880f892a0a2d82234b060806cf29051f6219c816550e2d1cec1f362af726ac07b508b1012800d707861ff71c6a02bc268f124805d825ff2860182607ea009f104019d80145004a06fa0b2307d40a1c2df519722b6621b9141e29cc2967277506d00afe18e40ca405b1238b130514f52f15177200d52610190a2ead08951f072a220a2808bb09f71fe31aa21fee057b0a5a20c313da0c6c2190138308e5018d13c32633104d058319bd0e0213fe0bae044906ce0db11a1e03d61afb24951656037611850bc6055202c82d8503dc2188202125f424552e3b1dfa032d284d0891221d08551a161db622200f6c0b6913bb0a2a296a08f708df26510e64221c18e32d371c5d0227253c073a0db414540d841b60163513b605a70592023d0be12e2f178714b21c2e1948118316d51f6223132b462957239218de2b78295d28ca1bfc2b9d0499050e0d3106ad06e41cc61251060a0ee90b8a1ac0258a21290d0a270f185209531cce12a5147c17b5291112532ee4099c1efe289b0eb0297a1d6c2d0025531c101978257206a7292d108b22f4080824271f0a29e71f0807d01a32072b2b5c163a17b2130c240908b407d4057f13cc09f32c5a240a01fd157c13671ab710cb224920a71092090b0bb6251426961ca02ab81a80079b15fa26201b8a1b1c2d89094e27430b0921a8295d04e0028f2c421c04237e03b5185a073228cf1a870a2f1a091c2a26e82b8928c61d0919a10572081203930d4a2fcd1df00a770e77059d02780c7a1d0e2770029c1294096d13f109be1e67275b117b098c10852cee25920b0a01a7132e1ccd2e882bf10d002aab0af02950092f01d02e8e03e00098213709e91be51744017d106a0aed20161fee2be12cf9015106b02abd1da524351dfc0dfb160b04022db70fe129241d202d9323250e84122d1b040f0a17c029712d342a3703d612d01b1d08581ae7198a1973291d05c2245b1133135d25f6040a011e2bc1136800a220c012af11ec17c027830e8725b5266f20be190420bb043e1e0d07ad0b930de613e2148925d20271068316702b6f1fe60dad16a5178319851ca70d4a0c182402200d010701f520520f1e077209d708672dab2a0a1eb50ef30b4817201e062969110616270f060a6b013f1ae72750016c12781c8c29f6011513032eb528672eda24f51197237101fc1ab413ae0844098f0f24184921f42a5f181b00800fb30a0a258b01742038094b1521278e20b31dd714c307aa246924732f1b08c42d2e0fd3090a085c29a119831f4c045a208d155e0eeb057f22fe1a201af9216d051a115a04ed260f1414146929450e6d0dc41691103d07da2f0408cf092f2b562c181fa425500c4c10fe257400e3047c2dbd0cec2436066b16fe22870c4605860b532b6707481a3c186a00b01b67033619e5280e0c4a1611285403e823360c6a085c18c200111c422eb51918217f21bd0e2b09b00fb014dc027425d40bc40e9b218317de050716cd01550e170e15218a235f1a902437070d0d6e127221db0cd91bb40c80184c1eab02d328e62e19112a077b1af11e5e27c005640d492dd40a85072802b62ebd2e292c3c20dc0bc924a71de81cc9272004142bef2ea02ca62bab13f526f4079f107a1dc2011308a426ec26d210360b0d1865142728fd0ddf041c1d3f2b301b5921c2001328d503e612e918461e620dd125ef177501c60ade03d529c32a60254a2eff0a4f224a29e323c217650bfc0658190208fc271b27612f1421ed173d034a2cf80967185900ed07370fcc192d282420a604ce1bb1132023a40d9502ec0aae2f6d13fa2df819f507cd0ed819cc28661d9710962e6807751c692b35285e05d604b0241a10bc0fc604522cdd19c104e90608152218731d9e227a209a07af03f026252f7b1ae70fe81ea402d91ec805e204310bcd1a0b16d82ca2238d1561064814ba15c20a9313932e55198f28db111d24240f301fcd11b4182f0ead218f199a01df27640c5306ac0557176e028f2d3c20db0c4c05061f940b3f2b6f16491fac2c2e2d0209b7059316bb268a23cb16aa0d9d1ddf02581d2b078a258804a7101c1d65136f0322052d29fd2e9b0d980eda103c05661f3e0e7612ca029e060b24582f1b2f2f2b4c2a07", // Don't need to verify output in benchmark
		},
		{
			Name: "VECADDMOD-ML-DSA-256",
			// Input: header + vecA (NTT_FW output) + vecB (NTT_INV output)
			Input:    "0000010000000000007fe001" + "ffc0e5f5ffccf7a7ffd16090004edaa0ffe71eb5ff73c3cbffe816a4ffaa68e8002d128900232447fffbc48800687808ffcc23a6ff8887d4ffd085b7ffb886f7ff50787aff5f29c0ff91d975ff1ede45ff5455b0ff39e7daff996f80ff570e8affde03f2ff9927c0ffbd960aff90b5340039e72dfff657710005c979ff99167100589a8900d65079ffedd0140059c60200696427004eba3d00122b9600717966002e890d001d9f150089e6aa006269b8fff32611ff898dc9001ae6bfffaa09dbffb50b370023ba61003b4460001d4eb80041022c00244598006c1331005829630014c6bbffef9ca5ffacd6f3ff8da3e5004334eaffc85ba4ffb04e46fff5185cffa02252ffddd8ceff977426ffe45376000d940c000b7406ff830114ffa8512effdbfd160058d400ff726e3affeaabf400413b6c00237720006a08a500ba812bffe9ae30fff4ced2ff779d7fff74f673ffefd00bffec82b1ff828eb1ffbfcf67006691eb008a7261001b0fd3007e964dffecc411ffb8aaa70039d446002be95e0038fb8d00946b6f005188a6fff8a1c20073dc960046207c000c2ae60060c30400187a800007feecffe2e96e00255b2affa9a238ff8327a0ffa2bcc90013becb00b1379b00401b0f006fd627004768f70105411f00a529f500a4942500be8a8f002d6ba300307ec7006c48b50093fb4500086cc1001336a7ffbf9f24ffa40db0fffa327a0044f6b4ffb3861dffe7664dfff7f812ffb50442002b72f1ffffb0a30041adb6fffc3596002dc3aa000bb9eeff5cb969ffadb0fdffd84203ffc2f9c3ff64ccdeff53b11efffcdcedff7e51a3fffabc1effceade6ff681582ffa89796ffabe545ffd95673ff5055fbff67c95d0012ae2b00620801fff4a23affa211d2fff4817aff998fe00004658fffe9c0afffa9a064001427ec0016ff05008496dbff624a1bffdcc465fff043fd0015d6b3003886f2ffe11fe4ffcfc63000427a42001b189f0015584100cfe9e800561e18fffba85d002204bb000b35bf00463b1900638201fff43d6500a28da100736c6dffff143fffd1d0efffb8d547001f52c7ffffecbe000139320064c65fffe78021ffd097abffdbc8770019b65b0036a513ffb34364ff64d086ff8a1165ffed3815ffd545fcffd92542ffcd17f0ff780ede00151f9eff9a21a0ffedf6e2004b78c4002395f9ffa810d500096b7a000d2bccffd3dd0cff6ff9c0ff97ee1dffd4f15fff828229ffc7f9c50008b217ffe521eb00526069006be427000ee455005cfeef0043b45f005a72a10042edfe0019c3ae00384bde006d2092ffe995990036989bffc384ea0018486e001ce2bf001dc2d50028952600311ff2008755df003c760900a4620b00c18e7d00677b50007eb5a8002e71ac003bdafa0053c84c0042e5760003951eff91d60cfffa06c8006bb1b6" + "003ff081004291d4000468af00799f7e00669c7500651af9005a89750059d805002238ca00006fd700382f710002d94a00458f1a00571a50001c12e100071da30016683a0038d6f5003913b80067a6df002411b90004236f00464895005782df0029f341004dd6a5000f846f005f33720016e42f004a2644006d0b4e005a37d8000870e60016d214002c797600381449002b8d500030a31a007c0f4c000abd020079c506004aedc6003ac2a30075b68800145b6c005ad35a000b79560026989a00631a49000e3fa000135c4f006275010035444d00339e7600556fdf007a8d01005de15f002ac82a00386a9a002d793b001837c00009210500661b6b001e9fa0002f6cf200175ba7007907d700167d67003277790006a2a7000fd2a900006e91006b9e0d00112f3b00706f6b007c67ea0024a6b30052192500732bdf006772110019296d0035d1b100559a4a003a5d82007fd5a3006572750008b23d0057b5490035d9970074807b0032aeac003cfc57000811cf006ad624001ddedd0033882c0016cc400039949900001c2b007987380038cd590067112c0025e7bc00697a00006b75db0006583c00089e110046da1b0036aac1007b71ce000890c100040bf2001adb60003b32290043c97b000f9963007149b5005f966000006b3e0015326a006efc56007c0825005d941e00426a5c0056867200203cc600603ae20018883a005c005c0018883a00603ae200203cc60056867200426a5c005d941e007c0825006efc560015326a00006b3e005f9660007149b5000f99630043c97b003b3229001adb6000040bf2000890c1007b71ce0036aac10046da1b00089e110006583c006b75db00697a000025e7bc0067112c0038cd590079873800001c2b003994990016cc400033882c001ddedd006ad624000811cf003cfc570032aeac0074807b0035d9970057b5490008b23d00657275007fd5a3003a5d8200559a4a0035d1b10019296d0067721100732bdf005219250024a6b3007c67ea00706f6b00112f3b006b9e0d00006e91000fd2a90006a2a70032777900167d67007907d700175ba7002f6cf2001e9fa000661b6b00092105001837c0002d793b00386a9a002ac82a005de15f007a8d0100556fdf00339e760035444d0062750100135c4f000e3fa000631a490026989a000b7956005ad35a00145b6c0075b688003ac2a3004aedc60079c506000abd02007c0f4c0030a31a002b8d5000381449002c79760016d214000870e6005a37d8006d0b4e004a26440016e42f005f3372000f846f004dd6a50029f341005782df004648950004236f002411b90067a6df003913b80038d6f50016683a00071da3001c12e100571a5000458f1a0002d94a00382f7100006fd7002238ca0059d805005a897500651af900669c7500799f7e000468af004291d4",
			Expected: "0000d676000f897b0055a94000489a1d004dbb2a0058bec50042a019000440ed004f4b530023941e0033f3f9006b51520011b2c0005f8225006c7899003f849bffe6c0b50017e0b6004acd2e00066525fff8476affbdeb4a005f9816002e716a0007f7330066de66004cfa7a006fc8a70050cb5c00407db50072d4c700732e4a00610b6f006d428c001a498a0011fa4a00151176007f5d57000e5ae1007c366800286e1200688cdb0044c94c0058403f0007817d006441240026601500508276001825800031fa01004ea0af007fc3b9007646790057e40e0041a30f0052d6630072a81a001a64cf0065218e003afd21005b6caa00515caa001669b10013b7fc004f6f450075147600107bfd007ab0de00400b85001216ad0012b3be00289fc000479b23006a033b0062bda6006713de0065e21f00759045005d548300a2133b0002d79d002aa083004d17ca002f33f6006fa5ae0051f526000b20ef001784b0001c8b81007f12db004dbe7f003bb2a30074b5e1002380cb0057b323005f718a004fc7cd004e20070051a4d1007228fa002cc9ee002d51a7003212a2004a5d030004105a000e5728006b6780006c354500602cfa007e796f002b2d8b0017cabd004c32fa007b4d380033bfa10057025a00f6aad30084e05400251f620053dcf8001c87f8002ca6eb0049fcd2005685a0005ef3330033736d001fda06003c75eb005632d6005d7eee0013c0ff0007a313004e7e8400774e9f0009270e007bb8c80030ca0b00116800002e2ee8006b504e004de31f003d2a61001c0b7e007e0bedffff883fffd79d1100056dae0079a372003166df00158801fff09394002ecfd300175b200042d073fff61db8004eba8a004b7b84005baf3800749e66005b866c000b4dba004cf80d0022446c005496d300319234005124430049adb100793755001803b3003479ae0078d63b007b492800387c94001b7d660025607a00784bf30034420c007cca5200c335c60028573c00204f10001e8ca4007ba52a00576a54004f400d00748bf700328049007a0f1400318bb800682e570031dd1e0036ae6e002f59b0001fd8d2004b01c9007081270068af6c000941b2005220f500616d3d001124c3005f3d88005f61450020d68b000a8a49003b9a430060544000062e7f007839e700409a3b0079503900266c1d0037f165001dc75d00442e1d00581992004da212fffa96c30013fd6900059479002def7a00000e0e00352b8d007bd400005ad14f00463bfe007befa300274532005a988e0039c6120052726d00679a5300623f1f0044c370002fde2e003abc0a006776a400000f4c0055f677005699ca003efd6000383d95002388bf0013b058006a1124004487c6001fcac0007f257f0050aa760015d2fe002e71c00028206e006a3193000b758a007e4f78002e6389", // Don't need to verify output in benchmark
		},
	}

	for _, test := range testCases {
		benchmarkPrecompiled("15", test, bench)
	}
}
