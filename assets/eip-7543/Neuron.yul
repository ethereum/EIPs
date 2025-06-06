// solc --evm-version london --strict-assembly Neuron.yul >> Neuron.txt

// user can set_weights any number of (decimal) weights
// user can run the Neuron, outputting sigmoid of the weighted sum of inputs

object "Neuron" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code {
            // a = ac*10^aq is a decimal
            // ac, aq int256 as 2's complement

            // Dispatcher
            switch selector()
            
            // set_weights(int256[])
            case 0x61d311e8 {
                let num_weights := div(calldatasize(), 64) // should be even // 64 since two words make one decimal
                for { let i := 0 } lt(i, num_weights) { i := add(i, 1) }
                {
                    let memory_address := add(mul(i, 64), 4)
                    let weight_c := calldataload(memory_address)
                    let index_address := mul(i, 2)
                    sstore(index_address, weight_c)

                    memory_address := add(memory_address, 32)
                    let weight_q := calldataload(memory_address)
                    index_address := add(index_address, 1)
                    sstore(index_address, weight_q)
                }
            }

            // will use as many input weights as input supplied
            // first two inputs are precision and steps
            // run(int256[])
            case 0xc5b5bb77 {
                let precision := calldataload(4)
                let steps := calldataload(36)
                
                let num_inputs_times_64 := sub(calldatasize(), 68) // expect full word per weight // 64 since two words make one decimal // 68: 4 for function selector
                calldatacopy(0, 68, num_inputs_times_64) // inputs
                
                let num_inputs := div(num_inputs_times_64, 64) // expect full word per weight // 64 since two words make one decimal // 68: 4 for function selector
                let yc, yq := neuron(num_inputs, precision, steps)
                
                mstore(0, yc)
                mstore(32, yq)

                log0(0, 32) // yc
                log0(32, 32) // yq

                return(0, 64)
            }
            default {
                revert(0, 0)
            }
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            // Neuron with sigmoid activation
            // https://en.wikipedia.org/wiki/Artificial_neuron

            function neuron(num_inputs, precision, steps) -> yc, yq {
                let xc, xq := weighted_sum(num_inputs, precision, steps)
                yc, yq := sigmoid(xc, xq, precision, steps)                
            }

            function weighted_sum(num_inputs, precision, steps) -> total_c, total_q {
                total_c := 0
                total_q := 0

                for { let i := 0 } lt(i, num_inputs) { i := add(i, 1) }
                {
                    let index_address := mul(i, 2)
                    let weight_c := sload(index_address)
                    index_address := add(index_address, 1)
                    let weight_q := sload(index_address)
                    
                    let memory_address := mul(i, 64)
                    let input_c := mload(memory_address)
                    memory_address := add(memory_address, 32)
                    let input_q := mload(memory_address)

                    let product_c, product_q := dec_mul(weight_c, weight_q, input_c, input_q, precision)

                    total_c, total_q := dec_add(total_c, total_q, product_c, product_q, precision)
                }
            }

            function sigmoid(xc, xq, precision, steps) -> yc, yq {
                let mxc, mxq := dec_neg(xc, xq) // -x
                let emxc, emxq := dec_exp(mxc, mxq, precision, steps) // exp(-x)
                let oemxc, oemxq := dec_add(1, 0, emxc, emxq, precision) // 1 + exp(-x)
                yc, yq := dec_inv(oemxc, oemxq, precision) // (1 + exp(-x))^(-1) = sigmoid(x)
            }


            // OPCODE -> function

            // a + b = c
            function dec_add(ac, aq, bc, bq, precision) -> cc, cq {
                cc, cq := verbatim_5i_2o(hex"d0", ac, aq, bc, bq, precision)
            }

            // -a = b
            function dec_neg(ac, aq) -> bc, bq {
                bc, bq := verbatim_2i_2o(hex"d1", ac, aq)
            }

            // a * b = c
            function dec_mul(ac, aq, bc, bq, precision) -> cc, cq {
                cc, cq := verbatim_5i_2o(hex"d2", ac, aq, bc, bq, precision)
            }

            // 1 / a = b
            function dec_inv(ac, aq, precision) -> bc, bq {
                bc, bq := verbatim_3i_2o(hex"d3", ac, aq, precision)
            }

            // dec_exp(a) = b
            function dec_exp(ac, aq, precision, steps) -> bc, bq {
                bc, bq := verbatim_4i_2o(hex"d4", ac, aq, precision, steps)
            }

            // dec_ln(a) = b
            function dec_ln(ac, aq, precision, steps) -> bc, bq {
                bc, bq := verbatim_4i_2o(hex"d5", ac, aq, precision, steps)
            }

            // dec_sin(a) = b
            function dec_sin(ac, aq, precision, steps) -> bc, bq {
                bc, bq := verbatim_4i_2o(hex"d6", ac, aq, precision, steps)
            }

            // derived functions

            // a - b = c
            function dec_sub(ac, aq, bc, bq, precision) -> cc, cq {
                cc, cq := dec_neg(bc, bq)
                cc, cq := dec_add(ac, aq, cc, cq, precision)
            }

            // a / b = c
            function dec_div(ac, aq, bc, bq, precision) -> cc, cq {
                cc, cq := dec_inv(bc, bq, precision)
                cc, cq := dec_mul(ac, aq, cc, cq, precision)
            }
            
            // a^b = dec_exp(b * dec_ln(a))
            function pow(ac, aq, bc, bq, precision, steps) -> cc, cq {
                cc, cq := dec_ln(ac, aq, precision, steps)
                cc, cq := dec_mul(bc, bq, cc, cq, precision)
                cc, cq := dec_exp(cc, cq, precision, steps)
            }

            // dec_sqrt(a) = a^(1/2) = a^(5*10(-1))
            function dec_sqrt(ac, aq, precision, steps) -> bc, bq {
                let MINUS_ONE := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // -1
                bc, bq := pow(ac, aq, 5, MINUS_ONE, precision, steps)
            }

            // dec_sqr(a) = a*a
            function dec_sqr(ac, aq, precision) -> bc, bq {
                bc, bq := dec_mul(ac, aq, ac, aq, precision)
            }
        }
    }
}
