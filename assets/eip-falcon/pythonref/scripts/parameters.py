# This Python file uses the following encoding: utf-8

"""
This script computes parameters and security estimates for Falcon.

References:
- [BDGL16]: ia.cr/2015/1128
- [DLP14]: ia.cr/2014/794
- [Duc18]:ia.cr/2017/999
- [Falcon20]: https://falcon-sign.info
- [HPRR20]: ia.cr/2019/1411
- [Laa16]: https://pure.tue.nl/ws/files/14673128/20160216_Laarhoven.pdf
- [Lyu12]: ia.cr/2011/537
- [MR07]: https://cims.nyu.edu/~regev/papers/average.pdf
- [MW16]: ia.cr/2015/1123
- [NIST]: https://csrc.nist.gov/CSRC/media/Projects/Post-Quantum-Cryptography
          /documents/call-for-proposals-final-dec-2016.pdf
- [Pre17]: ia.cr/2017/480
"""
from Crypto.Util.number import isPrime
from math import sqrt, exp, log, pi, floor, log

import sys
# For debugging purposes
if sys.version_info >= (3, 4):
    from importlib import reload  # Python 3.4+ only.


# This is the maximal acceptable standard deviation for
# the individual Gaussians over Z, lifted from [HPRR20]
sigmax = 1.8205


def smooth(eps, n, normalized=True):
    """
    Compute the smoothing parameter eta_epsilon(Z^n).
    - if normalized is True, take the definition from [Pre17,Falcon]
    - if normalized is False, take the definition from [MR07]
    """
    rep = sqrt(log(2 * n * (1 + 1 / eps)) / pi)
    if normalized is True:
        return rep / sqrt(2 * pi)
    else:
        return rep


def dimensionsforfree(B):
    """
    d in [Duc18].
    """
    return round(B * log(4 / 3) / log(B / (2 * pi * exp(1))))


class FalconParam:
    """
    This class stores an object with all the parameters for Falcon.
    See also Section 2.6 - "Summary of Parameters" in [Falcon20].
    """

    def __init__(self, n, target_bitsec):
        """
        Initialize a FalconParam object

        Input:
        - a ring degree n
        - a target bit-security target_bitsec

        Output:
        - a FalconParam object with:
          - the ring degree n
          - the integer modulus q
          - the Gram-Schmidt norm gs_norm
          - the signature standard deviation sigma
          - the tailcut rate and rejection rate
          - For key-recovery and forgery:
            - the required BKZ blocksize
            - the classical Core-SVP hardness
            - the quantum Core-SVP hardness
        """

        # n is the degree of the ring Z[x]/(x^n + 1)
        self.n = n

        # The maximal number of queries is limited to 2 ** 64 as per [NIST]
        self.nb_queries = 2 ** 64

        # Due to the NTT, the integer modulus q must verify two constraints:
        # - q is a prime number
        # - (q - 1) is a multiple of 2 * n
        self.q = 1024 * 12 + 1
        assert isPrime(self.q)
        assert ((self.q - 1) % (2 * self.n) == 0)

        # gs_norm is the Gram-Schmidt norm of the NTRU lattice
        # Security is maximized when gs_norm is minimized.
        # For NTRU lattices, [DLP14, Section 3] shows that
        # one can achieve gs_norm =< 1.17 * sqrt(q) in practice.
        self.gs_norm = 1.17 * sqrt(self.q)

        # sigma is the standard deviation of the signatures:
        # - On one hand, we require sigma small to make forgery harder.
        # - On the other hand, we want sigma large so that the signatures'
        #   distribution is indistinguishable from an ideal Gaussian.
        # We set sigma according to [Pre17], so that we lose
        # O(1) bits of security compared to the ideal case.
        self.eps = 1 / sqrt(target_bitsec * self.nb_queries)
        self.smoothz2n = smooth(self.eps, 2 * self.n, normalized=True)
        self.sigma = self.smoothz2n * self.gs_norm

        # sigmin and sigmax are the minimum and maximum standard deviations
        # for the Gaussian sampler over the *integers* SamplerZ.
        self.sigmin = self.sigma / self.gs_norm
        # sigmax is hardcoded, but it is important for security and correctness
        # that Falcon never calls SamplerZ with a standard deviation > sigmax
        self.sigmax = sigmax
        sigmax_in_practice = self.sigmin * 1.17 * 1.17
        assert(sigmax_in_practice <= self.sigmax)

        # The tailcut rate intervenes during the signing procedure.
        # The expected value of the signature norm is sigma * sqrt(2 * n).
        # If the signature norm is larger than its expected value by more than
        # a factor tailcut_rate, it is rejected and the procedure restarts.
        # The max squared signature norm is now called ⌊\beta^2⌋ in [Falcon20].
        # The rejection rate is given by [Lyu12, Lemma 4.4].
        self.tailcut_rate = 1.1
        tau = self.tailcut_rate
        m = 2 * self.n
        aux = tau * sqrt(m) * self.sigma
        self.max_sig_norm = floor(aux)
        self.sq_max_sig_norm = floor(aux ** 2)
        self.rejection_rate = (tau ** m) * exp(m * (1 - tau ** 2) / 2)

        # !!! Legacy values !!!
        # These are the values used in the v1.1 of Falcon.
        # They are not used anymore.
        self.leg_n = self.n
        self.leg_q = 12289
        # Sigma used to be the same across all parameter sets.
        self.leg_sigma = 1.55 * sqrt(self.leg_q)
        leg_sigmin = {512: 1.291500756233514568549480827642,
            1024: 1.311734375905083682667395805765}
        try:
            self.leg_sigmin = leg_sigmin[self.n]
        except KeyError:
            self.leg_sigmin = 0
        self.leg_sigmax = sigmax
        self.leg_gs_norm = sqrt(16822.4121)
        self.leg_tailcut_rate = 1.2
        self.leg_sq_max_sig_norm = 7085 * 12289 * self.leg_n >> 10

        # Signature bytesize (hardcoded)
        # These include s2 (compressed), the nonce and a header byte
        sig_bytesize = {
            2: 44,
            4: 47,
            8: 52,
            16: 63,
            32: 82,
            64: 122,
            128: 200,
            256: 356,
            512: 666,
            1024: 1280,
        }
        try:
            self.sig_bytesize = sig_bytesize[self.n]
        except KeyError:
            self.sig_bytesize = 0

        # Security metrics
        # This is the targeted bit-security.
        self.target_bitsec = target_bitsec

        # We compute the BKZ blocksize necessary to forge a signature.
        # This is the minimal blocksize B such that the left term in
        # equation (2.3) of [Falcon20] is larger than the right term.
        B = 100
        e = exp(1)
        # See line 1 in NTRUGen [Falcon20]
        sigma_fg = self.gs_norm / sqrt(2 * self.n)
        while(1):
            left = (B / (2 * pi * e)) ** (1 - n / B) * sqrt(self.q)
            right = sqrt(3 * B / 4) * sigma_fg
            if left > right:
                break
            else:
                B += 1
        # This is the smallest B which suffices to recover the private key.
        self.keyrec_blocksize = B
        self.keyrec_blocksize_opt = B - dimensionsforfree(B)
        # We deduce the classic and quantum CoreSVP security for key recovery.
        # Constants are lifted from [BDGL16] and [Laa16].
        self.keyrec_coresvp_c = floor(self.keyrec_blocksize * 0.292)
        self.keyrec_coresvp_q = floor(self.keyrec_blocksize * 0.265)
        self.keyrec_coresvp_opt_c = floor(self.keyrec_blocksize_opt * 0.292)
        self.keyrec_coresvp_opt_q = floor(self.keyrec_blocksize_opt * 0.265)

        # We compute the BKZ blocksize necessary to forge a signature.
        # This is done by embedding the signature in the lattice and applying
        # DBKZ. Subsequently, we apply [MW16, Corollary 1] with:
        # - k in the paper => B in this script
        # - n in the paper => 2 * n in our case
        # - det(B) in the paper => q ** n in our case
        # This gives the formule used to control the while loop below.
        # See also equation (2.4) in [Falcon20].
        B = 100
        sq = sqrt(self.q)
        while ((B / (2 * pi * e)) ** (self.n / B)) * sq > self.max_sig_norm:
            B += 1
        # This is the smallest B which suffices to break EF-CMA security.
        self.forgery_blocksize = B
        self.forgery_blocksize_opt = B - dimensionsforfree(B)
        # We deduce the classic and quantum Core-SVP security for key recovery.
        # Constants are lifted from [BDGL16] and [Laa16].
        self.forgery_coresvp_c = floor(self.forgery_blocksize * 0.292)
        self.forgery_coresvp_q = floor(self.forgery_blocksize * 0.265)
        self.forgery_coresvp_opt_c = floor(self.forgery_blocksize_opt * 0.292)
        self.forgery_coresvp_opt_q = floor(self.forgery_blocksize_opt * 0.265)


    def __repr__(self):
        """
        Print a FalconParam object.
        """
        rep = "\nParameters:\n"
        rep += "==========\n"
        rep += "- The degree of the ring ring Z[x]/(x^n + 1) is n.\n"
        rep += "- The integer modulus is q.\n"
        rep += "- The Gram-Schmidt norm is gs_norm"
        rep += "- The standard deviation of the signatures is sigma.\n"
        rep += "- The minimal std dev for sampling over Z is sigmin.\n"
        rep += "- The maximal std dev for sampling over Z is sigmax.\n"
        rep += "- The tailcut rate for signatures is tailcut.\n"
        rep += "- Signatures are rejected whenever ||(s1, s2)||^2 > β^2.\n"
        rep += "\n"
        rep += "n       = " + str(self.n) + "\n"
        rep += "q       = " + str(self.q) + "\n"
        rep += "gs_norm = " + str(self.gs_norm) + "\n"
        rep += "sigma   = " + str(self.sigma) + "\n"
        rep += "sigmin  = " + str(self.sigmin) + "\n"
        rep += "sigmax  = " + str(self.sigmax) + "\n"
        rep += "tailcut = " + str(self.tailcut_rate) + "\n"
        rep += "⌊β⌋     = " + str(self.max_sig_norm) + "\n"
        rep += "⌊β^2⌋   = " + str(self.sq_max_sig_norm) + "\n"
        rep += "\n\n"

        rep += "Metrics:\n"
        rep += "========\n"
        rep += "- The maximal number of signing queries is nb_queries.\n"
        rep += "- The signing rejection rate is rejection_rate.\n"
        rep += "- The maximal size of signatures is sig_bytesize (HARDCODED).\n"
        rep += "\n"
        rep += "nb_queries     = 2^" + str(int(log(self.nb_queries, 2))) + "\n"
        rep += "rejection_rate = " + str(self.rejection_rate) + "\n"
        rep += "sig_bytesize   = " + str(int(self.sig_bytesize)) + "\n"
        rep += "\n\n"

        rep += "Security:\n"
        rep += "=========\n"
        rep += "- The targeted security level is target_bitsec.\n"
        rep += "- For x in {keyrec, forgery} (i.e. key recovery or forgery):\n"
        rep += "  - The BKZ blocksize required to achieve x is x_blocksize.\n"
        rep += "  - The classic CoreSVP hardness of x is x_coresvp_c.\n"
        rep += "  - The quantum CoreSVP hardness of x is x_coresvp_q.\n"
        rep += "  Values in parenthesis use the [Duc18] optimization.\n"
        rep += "\n"
        rep += "target_bitsec     = " + str(self.target_bitsec) + "\n"
        rep += "keyrec_blocksize  = " + str(self.keyrec_blocksize)
        rep += " (" + str(self.keyrec_blocksize_opt) + ")\n"
        rep += "keyrec_coresvp_c  = " + str(self.keyrec_coresvp_c)
        rep += " (" + str(self.keyrec_coresvp_opt_c) + ")\n"
        rep += "keyrec_coresvp_q  = " + str(self.keyrec_coresvp_q)
        rep += " (" + str(self.keyrec_coresvp_opt_q) + ")\n"
        rep += "forgery_blocksize = " + str(self.forgery_blocksize)
        rep += " (" + str(self.forgery_blocksize_opt) + ")\n"
        rep += "forgery_coresvp_c = " + str(self.forgery_coresvp_c)
        rep += " (" + str(self.forgery_coresvp_opt_c) + ")\n"
        rep += "forgery_coresvp_q = " + str(self.forgery_coresvp_q)
        rep += " (" + str(self.forgery_coresvp_opt_q) + ")\n"
        return rep


Falcon = {}
for k in range(1, 11):
    n = 1 << k
    Falcon[n] = FalconParam(n, max(2, n >> 2))
