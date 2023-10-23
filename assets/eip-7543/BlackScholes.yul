// solc --evm-version london --strict-assembly BlackScholes.yul >> BlackScholes.txt

object "BlackScholes" {
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
            // callprice(int256,int256,int256,int256,int256,int256,int256,int256,int256,int256,int256,int256)
            case 0x95ba71af {
                // Sc, Sq, Kc, Kq, rc, rq, sc, sq, Tc, Tq, precision, steps
                // 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352
                calldatacopy(0, 4, 384)

                let ac, aq := callprice()
                sstore(0, ac)
                sstore(1, aq)
            }
            default {
                revert(0, 0)
            }
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            // BlackScholes
            // S: underlying price
            // K: strike
            // r: interest
            // s: volatility
            // T: time

            function r_s2_T() {
                let precision := mload(320)

                let sc := mload(192)
                let sq := mload(224)
                let s_sqr_c, s_sqr_q := dec_sqr(sc, sq, precision)

                let sigma_sqr_half_c, sigma_sqr_half_q := dec_div(s_sqr_c, s_sqr_q, 2, 0, precision)
                
                let rc := mload(128)
                let rq := mload(160)
                let r_p_s_c, r_p_s_q := dec_add(sigma_sqr_half_c, sigma_sqr_half_q, rc, rq, precision)

                let Tc := mload(256)
                let Tq := mload(288)
                let r_s2_T_c, r_s2_T_q := dec_mul(r_p_s_c, r_p_s_q, Tc, Tq, precision)

                mstore(384, r_s2_T_c)
                mstore(416, r_s2_T_q)
            }

            function ln_S_K() {
                let precision := mload(320)
                let steps := mload(352)

                let Sc := mload(0)
                let Sq := mload(32)
                let Kc := mload(64)
                let Kq := mload(96)
                let S_K_c, S_K_q := dec_div(Sc, Sq, Kc, Kq, precision)
                let ln_S_K_c, ln_S_K_q := dec_ln(S_K_c, S_K_q, precision, steps)

                mstore(448, ln_S_K_c)
                mstore(480, ln_S_K_q)
            }
            function d_plus_s_T() {
                let precision := mload(320)
                let steps := mload(352)

                let sc := mload(192)
                let sq := mload(224)
                let Tc := mload(256)
                let Tq := mload(288)
                let sqrt_T_c, sqrt_T_q := dec_sqrt(Tc, Tq, precision, steps)
                let s_sqrt_T_c, s_sqrt_T_q := dec_mul(sc, sq, sqrt_T_c, sqrt_T_q, precision)

                mstore(384, s_sqrt_T_c)
                mstore(416, s_sqrt_T_q)
            }
            function d_plus() {
                let precision := mload(320)
                let steps := mload(352)

                r_s2_T()
                let r_s2_T_c := mload(384)
                let r_s2_T_q := mload(416)
                ln_S_K()
                let ln_S_K_c := mload(448)
                let ln_S_K_q := mload(480)
                let ln_S_K_p_r_s2_T_c, ln_S_K_p_r_s2_T_q := dec_add(ln_S_K_c,ln_S_K_q, r_s2_T_c, r_s2_T_q, precision)
                
                d_plus_s_T()
                let s_sqrt_T_c := mload(384)
                let s_sqrt_T_q := mload(416)

                let d_plus_c, d_plus_q := dec_div(ln_S_K_p_r_s2_T_c, ln_S_K_p_r_s2_T_q, s_sqrt_T_c, s_sqrt_T_q, precision)
                
                mstore(448, d_plus_c)
                mstore(480, d_plus_q)
            }
            function d_minus() {
                let precision := mload(320)

                let d_plus_c := mload(448)
                let d_plus_q := mload(480)
                let s_sqrt_T_c := mload(384)
                let s_sqrt_T_q := mload(416)
                let d_minus_c, d_minus_q := dec_sub(d_plus_c, d_plus_q, s_sqrt_T_c, s_sqrt_T_q, precision)
                
                mstore(384, d_minus_c)
                mstore(416, d_minus_q)
            }
            // approximation
            // 1/(1+dec_exp(-1.65451*a))
            function CDF(ac, aq) -> bc, bq {
                let precision := mload(320)
                let steps := mload(352)

                let C := 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd79b5 // -165451
                let MINUS_FIVE := 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb // -5

                let b1_c, b1_q := dec_mul(C, MINUS_FIVE, ac, aq, precision)
                let b2_c, b2_q := dec_exp(b1_c, b1_q, precision, steps)
                let b3_c, b3_q := dec_add(b2_c, b2_q, 1, 0, precision)
                bc, bq := dec_inv(b3_c, b3_q, precision)
            }
            function cdf_dp_S() {
                let precision := mload(320)
                
                let d_plus_c := mload(448)
                let d_plus_q := mload(480)
                let cdf_dp_c, cdf_dp_q := CDF(d_plus_c, d_plus_q)
                
                let Sc := mload(0)
                let Sq := mload(32)
                let cdf_dp_S_c, cdf_dp_S_q := dec_mul(Sc, Sq, cdf_dp_c, cdf_dp_q, precision)

                mstore(448, cdf_dp_S_c)
                mstore(480, cdf_dp_S_q)
            }
            function cdf_dm_K_exp_r_T() {
                let precision := mload(320)
                let steps := mload(352)

                let rc := mload(128)
                let rq := mload(160)
                let r_n_c, r_n_q := dec_neg(rc, rq)
                let Tc := mload(256)
                let Tq := mload(288)
                let r_T_c, r_T_q := dec_mul(r_n_c, r_n_q, Tc, Tq, precision)
                let exp_r_T_c, exp_r_T_q := dec_exp(r_T_c, r_T_q, precision, steps)
                let Kc := mload(64)
                let Kq := mload(96)
                let K_exp_r_T_c, K_exp_r_T_q := dec_mul(Kc, Kq, exp_r_T_c, exp_r_T_q, precision)

                mstore(384, K_exp_r_T_c)
                mstore(416, K_exp_r_T_q)
            }
            function cdf_dm_K() {
                let precision := mload(320)
                let steps := mload(352)

                let d_minus_c := mload(384)
                let d_minus_q := mload(416)
                
                cdf_dm_K_exp_r_T()
                let K_exp_r_T_c := mload(384)
                let K_exp_r_T_q := mload(416)

                let cdf_dm_c, cdf_dm_q := CDF(d_minus_c, d_minus_q)
                let cdf_dm_K_c, cdf_dm_K_q := dec_mul(cdf_dm_c, cdf_dm_q, K_exp_r_T_c, K_exp_r_T_q, precision)
                
                mstore(384, cdf_dm_K_c)
                mstore(416, cdf_dm_K_q)
            }
            function callprice() -> ac, aq {
                let precision := mload(320)
                
                d_plus()
                d_minus()
                cdf_dp_S()
                cdf_dm_K()

                let cdf_dm_K_c := mload(384)
                let cdf_dm_K_q := mload(416)
                let cdf_dp_S_c := mload(448)
                let cdf_dp_S_q := mload(480)

                ac, aq := dec_sub(cdf_dp_S_c, cdf_dp_S_q, cdf_dm_K_c, cdf_dm_K_q, precision)
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
