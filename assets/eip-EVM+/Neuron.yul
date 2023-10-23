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

                //debug
                // sstore(12, num_inputs)
                // sstore(13, precision)
                // sstore(14, steps)
                // sstore(15, yc)
                // sstore(16, yq)
                log0(0, 32) // yc
                log0(32, 32) // yq
                //debug

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

                //debug
                // sstore(15, xc)
                // sstore(16, xq)
                // sstore(17, yc)
                // sstore(18, yq)
                //debug
                
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

                    //debug
                    // sstore(add(mul(i,10),30), index_address)
                    // sstore(add(mul(i,10),31), memory_address)
                    // sstore(add(mul(i,10),32), input_c)
                    // sstore(add(mul(i,10),33), input_q)
                    // sstore(add(mul(i,10),34), weight_c)
                    // sstore(add(mul(i,10),35), weight_q)
                    // sstore(add(mul(i,10),36), product_c)
                    // sstore(add(mul(i,10),37), product_q)
                    // sstore(add(mul(i,10),38), total_c)
                    // sstore(add(mul(i,10),39), total_q)
                    //debug
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

            // dec_sqrt(a) = a^(1/2)
            function dec_sqrt(ac, aq, precision, steps) -> bc, bq {
                let MINUS_ONE := 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff // -1
                bc, bq := pow(ac, aq, 5, MINUS_ONE, precision, steps)
            }

            // dec_sqr(a) = a^2
            function dec_sqr(ac, aq, precision) -> bc, bq {
                bc, bq := dec_mul(ac, aq, ac, aq, precision)
            }
        }
    }
}


// // BlackScholes
// // S: underlying price
// // K: strike
// // r: interest
// // s: volatility
// // T: time

// function r_s2_T() {
//     let precision := mload(320)

//     let sc := mload(192)
//     let sq := mload(224)
//     let s_sqr_c, s_sqr_q := dec_sqr(sc, sq, precision)

//     let sigma_sqr_half_c, sigma_sqr_half_q := dec_div(s_sqr_c, s_sqr_q, 2, 0, precision)
    
//     let rc := mload(128)
//     let rq := mload(160)
//     let r_p_s_c, r_p_s_q := dec_add(sigma_sqr_half_c, sigma_sqr_half_q, rc, rq, precision)

//     let Tc := mload(256)
//     let Tq := mload(288)
//     let r_s2_T_c, r_s2_T_q := dec_mul(r_p_s_c, r_p_s_q, Tc, Tq, precision)

//     mstore(384, r_s2_T_c)
//     mstore(416, r_s2_T_q)
// }

// function ln_S_K() {
//     let precision := mload(320)
//     let steps := mload(352)

//     let Sc := mload(0)
//     let Sq := mload(32)
//     let Kc := mload(64)
//     let Kq := mload(96)
//     let S_K_c, S_K_q := dec_div(Sc, Sq, Kc, Kq, precision)
//     let ln_S_K_c, ln_S_K_q := dec_ln(S_K_c, S_K_q, precision, steps)

//     mstore(448, ln_S_K_c)
//     mstore(480, ln_S_K_q)
// }
// function d_plus_s_T() {
//     let precision := mload(320)
//     let steps := mload(352)

//     let sc := mload(192)
//     let sq := mload(224)
//     let Tc := mload(256)
//     let Tq := mload(288)
//     let sqrt_T_c, sqrt_T_q := dec_sqrt(Tc, Tq, precision, steps)
//     let s_sqrt_T_c, s_sqrt_T_q := dec_mul(sc, sq, sqrt_T_c, sqrt_T_q, precision)

//     mstore(384, s_sqrt_T_c)
//     mstore(416, s_sqrt_T_q)
// }
// function d_plus() {
//     let precision := mload(320)
//     let steps := mload(352)

//     r_s2_T()
//     let r_s2_T_c := mload(384)
//     let r_s2_T_q := mload(416)
//     ln_S_K()
//     let ln_S_K_c := mload(448)
//     let ln_S_K_q := mload(480)
//     let ln_S_K_p_r_s2_T_c, ln_S_K_p_r_s2_T_q := dec_add(ln_S_K_c,ln_S_K_q, r_s2_T_c, r_s2_T_q, precision)
    
//     d_plus_s_T()
//     let s_sqrt_T_c := mload(384)
//     let s_sqrt_T_q := mload(416)

//     let d_plus_c, d_plus_q := dec_div(ln_S_K_p_r_s2_T_c, ln_S_K_p_r_s2_T_q, s_sqrt_T_c, s_sqrt_T_q, precision)
    
//     mstore(448, d_plus_c)
//     mstore(480, d_plus_q)
// }
// function d_minus() {
//     let precision := mload(320)

//     let d_plus_c := mload(448)
//     let d_plus_q := mload(480)
//     let s_sqrt_T_c := mload(384)
//     let s_sqrt_T_q := mload(416)
//     let d_minus_c, d_minus_q := dec_sub(d_plus_c, d_plus_q, s_sqrt_T_c, s_sqrt_T_q, precision)
    
//     mstore(384, d_minus_c)
//     mstore(416, d_minus_q)
// }
// // approximation
// // 1/(1+dec_exp(-1.65451*a))
// function CDF(ac, aq) -> bc, bq {
//     let precision := mload(320)
//     let steps := mload(352)

//     let C := 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd79b5 // -165451
//     let MINUS_FIVE := 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb // -5

//     let b1_c, b1_q := dec_mul(C, MINUS_FIVE, ac, aq, precision)
//     let b2_c, b2_q := dec_exp(b1_c, b1_q, precision, steps)
//     let b3_c, b3_q := dec_add(b2_c, b2_q, 1, 0, precision)
//     bc, bq := dec_inv(b3_c, b3_q, precision)
// }
// function cdf_dp_S() {
//     let precision := mload(320)
    
//     let d_plus_c := mload(448)
//     let d_plus_q := mload(480)
//     let cdf_dp_c, cdf_dp_q := CDF(d_plus_c, d_plus_q)
    
//     let Sc := mload(0)
//     let Sq := mload(32)
//     let cdf_dp_S_c, cdf_dp_S_q := dec_mul(Sc, Sq, cdf_dp_c, cdf_dp_q, precision)

//     mstore(448, cdf_dp_S_c)
//     mstore(480, cdf_dp_S_q)
// }
// function cdf_dm_K_exp_r_T() {
//     let precision := mload(320)
//     let steps := mload(352)

//     let rc := mload(128)
//     let rq := mload(160)
//     let r_n_c, r_n_q := dec_neg(rc, rq)
//     let Tc := mload(256)
//     let Tq := mload(288)
//     let r_T_c, r_T_q := dec_mul(r_n_c, r_n_q, Tc, Tq, precision)
//     let exp_r_T_c, exp_r_T_q := dec_exp(r_T_c, r_T_q, precision, steps)
//     let Kc := mload(64)
//     let Kq := mload(96)
//     let K_exp_r_T_c, K_exp_r_T_q := dec_mul(Kc, Kq, exp_r_T_c, exp_r_T_q, precision)

//     mstore(384, K_exp_r_T_c)
//     mstore(416, K_exp_r_T_q)
// }
// function cdf_dm_K() {
//     let precision := mload(320)
//     let steps := mload(352)

//     let d_minus_c := mload(384)
//     let d_minus_q := mload(416)
    
//     cdf_dm_K_exp_r_T()
//     let K_exp_r_T_c := mload(384)
//     let K_exp_r_T_q := mload(416)

//     let cdf_dm_c, cdf_dm_q := CDF(d_minus_c, d_minus_q)
//     let cdf_dm_K_c, cdf_dm_K_q := dec_mul(cdf_dm_c, cdf_dm_q, K_exp_r_T_c, K_exp_r_T_q, precision)
    
//     mstore(384, cdf_dm_K_c)
//     mstore(416, cdf_dm_K_q)
// }
// function callprice() -> ac, aq {
//     let precision := mload(320)
    
//     d_plus()
//     d_minus()
//     cdf_dp_S()
//     cdf_dm_K()

//     let cdf_dm_K_c := mload(384)
//     let cdf_dm_K_q := mload(416)
//     let cdf_dp_S_c := mload(448)
//     let cdf_dp_S_q := mload(480)

//     ac, aq := dec_sub(cdf_dp_S_c, cdf_dp_S_q, cdf_dm_K_c, cdf_dm_K_q, precision)
// }