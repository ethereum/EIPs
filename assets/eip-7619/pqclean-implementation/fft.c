// Based on PQClean https://github.com/PQClean/PQClean/tree/master/crypto_sign/falcon-512/clean
/*
 * FFT code.
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

#include "inner.h"

/*
 * Rules for complex number macros:
 * --------------------------------
 *
 * Operand order is: destination, source1, source2...
 *
 * Each operand is a real and an imaginary part.
 *
 * All overlaps are allowed.
 */

/*
 * Addition of two complex numbers (d = a + b).
 */
#define FPC_ADD(d_re, d_im, a_re, a_im, b_re, b_im)   do { \
        fpr fpct_re, fpct_im; \
        fpct_re = fpr_add(a_re, b_re); \
        fpct_im = fpr_add(a_im, b_im); \
        (d_re) = fpct_re; \
        (d_im) = fpct_im; \
    } while (0)

/*
 * Subtraction of two complex numbers (d = a - b).
 */
#define FPC_SUB(d_re, d_im, a_re, a_im, b_re, b_im)   do { \
        fpr fpct_re, fpct_im; \
        fpct_re = fpr_sub(a_re, b_re); \
        fpct_im = fpr_sub(a_im, b_im); \
        (d_re) = fpct_re; \
        (d_im) = fpct_im; \
    } while (0)

/*
 * Multplication of two complex numbers (d = a * b).
 */
#define FPC_MUL(d_re, d_im, a_re, a_im, b_re, b_im)   do { \
        fpr fpct_a_re, fpct_a_im; \
        fpr fpct_b_re, fpct_b_im; \
        fpr fpct_d_re, fpct_d_im; \
        fpct_a_re = (a_re); \
        fpct_a_im = (a_im); \
        fpct_b_re = (b_re); \
        fpct_b_im = (b_im); \
        fpct_d_re = fpr_sub( \
                             fpr_mul(fpct_a_re, fpct_b_re), \
                             fpr_mul(fpct_a_im, fpct_b_im)); \
        fpct_d_im = fpr_add( \
                             fpr_mul(fpct_a_re, fpct_b_im), \
                             fpr_mul(fpct_a_im, fpct_b_re)); \
        (d_re) = fpct_d_re; \
        (d_im) = fpct_d_im; \
    } while (0)

/*
 * Squaring of a complex number (d = a * a).
 */
#define FPC_SQR(d_re, d_im, a_re, a_im)   do { \
        fpr fpct_a_re, fpct_a_im; \
        fpr fpct_d_re, fpct_d_im; \
        fpct_a_re = (a_re); \
        fpct_a_im = (a_im); \
        fpct_d_re = fpr_sub(fpr_sqr(fpct_a_re), fpr_sqr(fpct_a_im)); \
        fpct_d_im = fpr_double(fpr_mul(fpct_a_re, fpct_a_im)); \
        (d_re) = fpct_d_re; \
        (d_im) = fpct_d_im; \
    } while (0)

/*
 * Inversion of a complex number (d = 1 / a).
 */
#define FPC_INV(d_re, d_im, a_re, a_im)   do { \
        fpr fpct_a_re, fpct_a_im; \
        fpr fpct_d_re, fpct_d_im; \
        fpr fpct_m; \
        fpct_a_re = (a_re); \
        fpct_a_im = (a_im); \
        fpct_m = fpr_add(fpr_sqr(fpct_a_re), fpr_sqr(fpct_a_im)); \
        fpct_m = fpr_inv(fpct_m); \
        fpct_d_re = fpr_mul(fpct_a_re, fpct_m); \
        fpct_d_im = fpr_mul(fpr_neg(fpct_a_im), fpct_m); \
        (d_re) = fpct_d_re; \
        (d_im) = fpct_d_im; \
    } while (0)

/*
 * Division of complex numbers (d = a / b).
 */
#define FPC_DIV(d_re, d_im, a_re, a_im, b_re, b_im)   do { \
        fpr fpct_a_re, fpct_a_im; \
        fpr fpct_b_re, fpct_b_im; \
        fpr fpct_d_re, fpct_d_im; \
        fpr fpct_m; \
        fpct_a_re = (a_re); \
        fpct_a_im = (a_im); \
        fpct_b_re = (b_re); \
        fpct_b_im = (b_im); \
        fpct_m = fpr_add(fpr_sqr(fpct_b_re), fpr_sqr(fpct_b_im)); \
        fpct_m = fpr_inv(fpct_m); \
        fpct_b_re = fpr_mul(fpct_b_re, fpct_m); \
        fpct_b_im = fpr_mul(fpr_neg(fpct_b_im), fpct_m); \
        fpct_d_re = fpr_sub( \
                             fpr_mul(fpct_a_re, fpct_b_re), \
                             fpr_mul(fpct_a_im, fpct_b_im)); \
        fpct_d_im = fpr_add( \
                             fpr_mul(fpct_a_re, fpct_b_im), \
                             fpr_mul(fpct_a_im, fpct_b_re)); \
        (d_re) = fpct_d_re; \
        (d_im) = fpct_d_im; \
    } while (0)

/*
 * Let w = exp(i*pi/N); w is a primitive 2N-th root of 1. We define the
 * values w_j = w^(2j+1) for all j from 0 to N-1: these are the roots
 * of X^N+1 in the field of complex numbers. A crucial property is that
 * w_{N-1-j} = conj(w_j) = 1/w_j for all j.
 *
 * FFT representation of a polynomial f (taken modulo X^N+1) is the
 * set of values f(w_j). Since f is real, conj(f(w_j)) = f(conj(w_j)),
 * thus f(w_{N-1-j}) = conj(f(w_j)). We thus store only half the values,
 * for j = 0 to N/2-1; the other half can be recomputed easily when (if)
 * needed. A consequence is that FFT representation has the same size
 * as normal representation: N/2 complex numbers use N real numbers (each
 * complex number is the combination of a real and an imaginary part).
 *
 * We use a specific ordering which makes computations easier. Let rev()
 * be the bit-reversal function over log(N) bits. For j in 0..N/2-1, we
 * store the real and imaginary parts of f(w_j) in slots:
 *
 *    Re(f(w_j)) -> slot rev(j)/2
 *    Im(f(w_j)) -> slot rev(j)/2+N/2
 *
 * (Note that rev(j) is even for j < N/2.)
 */

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_FFT(fpr *f, unsigned logn) {
    /*
     * FFT algorithm in bit-reversal order uses the following
     * iterative algorithm:
     *
     *   t = N
     *   for m = 1; m < N; m *= 2:
     *       ht = t/2
     *       for i1 = 0; i1 < m; i1 ++:
     *           j1 = i1 * t
     *           s = GM[m + i1]
     *           for j = j1; j < (j1 + ht); j ++:
     *               x = f[j]
     *               y = s * f[j + ht]
     *               f[j] = x + y
     *               f[j + ht] = x - y
     *       t = ht
     *
     * GM[k] contains w^rev(k) for primitive root w = exp(i*pi/N).
     *
     * In the description above, f[] is supposed to contain complex
     * numbers. In our in-memory representation, the real and
     * imaginary parts of f[k] are in array slots k and k+N/2.
     *
     * We only keep the first half of the complex numbers. We can
     * see that after the first iteration, the first and second halves
     * of the array of complex numbers have separate lives, so we
     * simply ignore the second part.
     */

    unsigned u;
    size_t t, n, hn, m;

    /*
     * First iteration: compute f[j] + i * f[j+N/2] for all j < N/2
     * (because GM[1] = w^rev(1) = w^(N/2) = i).
     * In our chosen representation, this is a no-op: everything is
     * already where it should be.
     */

    /*
     * Subsequent iterations are truncated to use only the first
     * half of values.
     */
    n = (size_t)1 << logn;
    hn = n >> 1;
    t = hn;
    for (u = 1, m = 2; u < logn; u ++, m <<= 1) {
        size_t ht, hm, i1, j1;

        ht = t >> 1;
        hm = m >> 1;
        for (i1 = 0, j1 = 0; i1 < hm; i1 ++, j1 += t) {
            size_t j, j2;

            j2 = j1 + ht;
            fpr s_re, s_im;

            s_re = fpr_gm_tab[((m + i1) << 1) + 0];
            s_im = fpr_gm_tab[((m + i1) << 1) + 1];
            for (j = j1; j < j2; j ++) {
                fpr x_re, x_im, y_re, y_im;

                x_re = f[j];
                x_im = f[j + hn];
                y_re = f[j + ht];
                y_im = f[j + ht + hn];
                FPC_MUL(y_re, y_im, y_re, y_im, s_re, s_im);
                FPC_ADD(f[j], f[j + hn],
                        x_re, x_im, y_re, y_im);
                FPC_SUB(f[j + ht], f[j + ht + hn],
                        x_re, x_im, y_re, y_im);
            }
        }
        t = ht;
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_iFFT(fpr *f, unsigned logn) {
    /*
     * Inverse FFT algorithm in bit-reversal order uses the following
     * iterative algorithm:
     *
     *   t = 1
     *   for m = N; m > 1; m /= 2:
     *       hm = m/2
     *       dt = t*2
     *       for i1 = 0; i1 < hm; i1 ++:
     *           j1 = i1 * dt
     *           s = iGM[hm + i1]
     *           for j = j1; j < (j1 + t); j ++:
     *               x = f[j]
     *               y = f[j + t]
     *               f[j] = x + y
     *               f[j + t] = s * (x - y)
     *       t = dt
     *   for i1 = 0; i1 < N; i1 ++:
     *       f[i1] = f[i1] / N
     *
     * iGM[k] contains (1/w)^rev(k) for primitive root w = exp(i*pi/N)
     * (actually, iGM[k] = 1/GM[k] = conj(GM[k])).
     *
     * In the main loop (not counting the final division loop), in
     * all iterations except the last, the first and second half of f[]
     * (as an array of complex numbers) are separate. In our chosen
     * representation, we do not keep the second half.
     *
     * The last iteration recombines the recomputed half with the
     * implicit half, and should yield only real numbers since the
     * target polynomial is real; moreover, s = i at that step.
     * Thus, when considering x and y:
     *    y = conj(x) since the final f[j] must be real
     *    Therefore, f[j] is filled with 2*Re(x), and f[j + t] is
     *    filled with 2*Im(x).
     * But we already have Re(x) and Im(x) in array slots j and j+t
     * in our chosen representation. That last iteration is thus a
     * simple doubling of the values in all the array.
     *
     * We make the last iteration a no-op by tweaking the final
     * division into a division by N/2, not N.
     */
    size_t u, n, hn, t, m;

    n = (size_t)1 << logn;
    t = 1;
    m = n;
    hn = n >> 1;
    for (u = logn; u > 1; u --) {
        size_t hm, dt, i1, j1;

        hm = m >> 1;
        dt = t << 1;
        for (i1 = 0, j1 = 0; j1 < hn; i1 ++, j1 += dt) {
            size_t j, j2;

            j2 = j1 + t;
            fpr s_re, s_im;

            s_re = fpr_gm_tab[((hm + i1) << 1) + 0];
            s_im = fpr_neg(fpr_gm_tab[((hm + i1) << 1) + 1]);
            for (j = j1; j < j2; j ++) {
                fpr x_re, x_im, y_re, y_im;

                x_re = f[j];
                x_im = f[j + hn];
                y_re = f[j + t];
                y_im = f[j + t + hn];
                FPC_ADD(f[j], f[j + hn],
                        x_re, x_im, y_re, y_im);
                FPC_SUB(x_re, x_im, x_re, x_im, y_re, y_im);
                FPC_MUL(f[j + t], f[j + t + hn],
                        x_re, x_im, s_re, s_im);
            }
        }
        t = dt;
        m = hm;
    }

    /*
     * Last iteration is a no-op, provided that we divide by N/2
     * instead of N. We need to make a special case for logn = 0.
     */
    if (logn > 0) {
        fpr ni;

        ni = fpr_p2_tab[logn];
        for (u = 0; u < n; u ++) {
            f[u] = fpr_mul(f[u], ni);
        }
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_add(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, u;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        a[u] = fpr_add(a[u], b[u]);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_sub(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, u;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        a[u] = fpr_sub(a[u], b[u]);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_neg(fpr *a, unsigned logn) {
    size_t n, u;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        a[u] = fpr_neg(a[u]);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_adj_fft(fpr *a, unsigned logn) {
    size_t n, u;

    n = (size_t)1 << logn;
    for (u = (n >> 1); u < n; u ++) {
        a[u] = fpr_neg(a[u]);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_mul_fft(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr a_re, a_im, b_re, b_im;

        a_re = a[u];
        a_im = a[u + hn];
        b_re = b[u];
        b_im = b[u + hn];
        FPC_MUL(a[u], a[u + hn], a_re, a_im, b_re, b_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_muladj_fft(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr a_re, a_im, b_re, b_im;

        a_re = a[u];
        a_im = a[u + hn];
        b_re = b[u];
        b_im = fpr_neg(b[u + hn]);
        FPC_MUL(a[u], a[u + hn], a_re, a_im, b_re, b_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_mulselfadj_fft(fpr *a, unsigned logn) {
    /*
     * Since each coefficient is multiplied with its own conjugate,
     * the result contains only real values.
     */
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr a_re, a_im;

        a_re = a[u];
        a_im = a[u + hn];
        a[u] = fpr_add(fpr_sqr(a_re), fpr_sqr(a_im));
        a[u + hn] = fpr_zero;
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_mulconst(fpr *a, fpr x, unsigned logn) {
    size_t n, u;

    n = (size_t)1 << logn;
    for (u = 0; u < n; u ++) {
        a[u] = fpr_mul(a[u], x);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_div_fft(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr a_re, a_im, b_re, b_im;

        a_re = a[u];
        a_im = a[u + hn];
        b_re = b[u];
        b_im = b[u + hn];
        FPC_DIV(a[u], a[u + hn], a_re, a_im, b_re, b_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_invnorm2_fft(fpr *d,
        const fpr *a, const fpr *b, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr a_re, a_im;
        fpr b_re, b_im;

        a_re = a[u];
        a_im = a[u + hn];
        b_re = b[u];
        b_im = b[u + hn];
        d[u] = fpr_inv(fpr_add(
                           fpr_add(fpr_sqr(a_re), fpr_sqr(a_im)),
                           fpr_add(fpr_sqr(b_re), fpr_sqr(b_im))));
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_add_muladj_fft(fpr *d,
        const fpr *F, const fpr *G,
        const fpr *f, const fpr *g, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr F_re, F_im, G_re, G_im;
        fpr f_re, f_im, g_re, g_im;
        fpr a_re, a_im, b_re, b_im;

        F_re = F[u];
        F_im = F[u + hn];
        G_re = G[u];
        G_im = G[u + hn];
        f_re = f[u];
        f_im = f[u + hn];
        g_re = g[u];
        g_im = g[u + hn];

        FPC_MUL(a_re, a_im, F_re, F_im, f_re, fpr_neg(f_im));
        FPC_MUL(b_re, b_im, G_re, G_im, g_re, fpr_neg(g_im));
        d[u] = fpr_add(a_re, b_re);
        d[u + hn] = fpr_add(a_im, b_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_mul_autoadj_fft(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        a[u] = fpr_mul(a[u], b[u]);
        a[u + hn] = fpr_mul(a[u + hn], b[u]);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_div_autoadj_fft(
    fpr *a, const fpr *b, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr ib;

        ib = fpr_inv(b[u]);
        a[u] = fpr_mul(a[u], ib);
        a[u + hn] = fpr_mul(a[u + hn], ib);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_LDL_fft(
    const fpr *g00,
    fpr *g01, fpr *g11, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr g00_re, g00_im, g01_re, g01_im, g11_re, g11_im;
        fpr mu_re, mu_im;

        g00_re = g00[u];
        g00_im = g00[u + hn];
        g01_re = g01[u];
        g01_im = g01[u + hn];
        g11_re = g11[u];
        g11_im = g11[u + hn];
        FPC_DIV(mu_re, mu_im, g01_re, g01_im, g00_re, g00_im);
        FPC_MUL(g01_re, g01_im, mu_re, mu_im, g01_re, fpr_neg(g01_im));
        FPC_SUB(g11[u], g11[u + hn], g11_re, g11_im, g01_re, g01_im);
        g01[u] = mu_re;
        g01[u + hn] = fpr_neg(mu_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_LDLmv_fft(
    fpr *d11, fpr *l10,
    const fpr *g00, const fpr *g01,
    const fpr *g11, unsigned logn) {
    size_t n, hn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    for (u = 0; u < hn; u ++) {
        fpr g00_re, g00_im, g01_re, g01_im, g11_re, g11_im;
        fpr mu_re, mu_im;

        g00_re = g00[u];
        g00_im = g00[u + hn];
        g01_re = g01[u];
        g01_im = g01[u + hn];
        g11_re = g11[u];
        g11_im = g11[u + hn];
        FPC_DIV(mu_re, mu_im, g01_re, g01_im, g00_re, g00_im);
        FPC_MUL(g01_re, g01_im, mu_re, mu_im, g01_re, fpr_neg(g01_im));
        FPC_SUB(d11[u], d11[u + hn], g11_re, g11_im, g01_re, g01_im);
        l10[u] = mu_re;
        l10[u + hn] = fpr_neg(mu_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_split_fft(
    fpr *f0, fpr *f1,
    const fpr *f, unsigned logn) {
    /*
     * The FFT representation we use is in bit-reversed order
     * (element i contains f(w^(rev(i))), where rev() is the
     * bit-reversal function over the ring degree. This changes
     * indexes with regards to the Falcon specification.
     */
    size_t n, hn, qn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    qn = hn >> 1;

    /*
     * We process complex values by pairs. For logn = 1, there is only
     * one complex value (the other one is the implicit conjugate),
     * so we add the two lines below because the loop will be
     * skipped.
     */
    f0[0] = f[0];
    f1[0] = f[hn];

    for (u = 0; u < qn; u ++) {
        fpr a_re, a_im, b_re, b_im;
        fpr t_re, t_im;

        a_re = f[(u << 1) + 0];
        a_im = f[(u << 1) + 0 + hn];
        b_re = f[(u << 1) + 1];
        b_im = f[(u << 1) + 1 + hn];

        FPC_ADD(t_re, t_im, a_re, a_im, b_re, b_im);
        f0[u] = fpr_half(t_re);
        f0[u + qn] = fpr_half(t_im);

        FPC_SUB(t_re, t_im, a_re, a_im, b_re, b_im);
        FPC_MUL(t_re, t_im, t_re, t_im,
                fpr_gm_tab[((u + hn) << 1) + 0],
                fpr_neg(fpr_gm_tab[((u + hn) << 1) + 1]));
        f1[u] = fpr_half(t_re);
        f1[u + qn] = fpr_half(t_im);
    }
}

/* see inner.h */
void
PQCLEAN_FALCON512_CLEAN_poly_merge_fft(
    fpr *f,
    const fpr *f0, const fpr *f1, unsigned logn) {
    size_t n, hn, qn, u;

    n = (size_t)1 << logn;
    hn = n >> 1;
    qn = hn >> 1;

    /*
     * An extra copy to handle the special case logn = 1.
     */
    f[0] = f0[0];
    f[hn] = f1[0];

    for (u = 0; u < qn; u ++) {
        fpr a_re, a_im, b_re, b_im;
        fpr t_re, t_im;

        a_re = f0[u];
        a_im = f0[u + qn];
        FPC_MUL(b_re, b_im, f1[u], f1[u + qn],
                fpr_gm_tab[((u + hn) << 1) + 0],
                fpr_gm_tab[((u + hn) << 1) + 1]);
        FPC_ADD(t_re, t_im, a_re, a_im, b_re, b_im);
        f[(u << 1) + 0] = t_re;
        f[(u << 1) + 0 + hn] = t_im;
        FPC_SUB(t_re, t_im, a_re, a_im, b_re, b_im);
        f[(u << 1) + 1] = t_re;
        f[(u << 1) + 1 + hn] = t_im;
    }
}
