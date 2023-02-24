// Only one proof is verified at a time - create with `create_proofs.py`

// TRANSACTION, AMOUNT, SENDER, INFO
#define PROOF_TYPE INFO
// 0, 1, 2, 3, 4
#define PROOF_INDEX 4

/*******************************************************************************

prj.conf:
CONFIG_MAIN_STACK_SIZE=6144
CONFIG_NRF_OBERON=y
CONFIG_TIMING_FUNCTIONS=y

CMakeLists.txt:
zephyr_get_compile_definitions_for_lang_as_string(C definitions)
zephyr_get_compile_options_for_lang_as_string(C options)
zephyr_get_include_directories_for_lang_as_string(C includes)
zephyr_get_system_include_directories_for_lang_as_string(C system_includes)
string(CONCAT external_project_cflags
    "${definitions} ${options} ${includes} ${system_includes} "
    "-specs=nosys.specs")
include(ExternalProject)
set(secp256k1_prefix ${CMAKE_CURRENT_BINARY_DIR}/libsecp256k1)
ExternalProject_Add(
    libsecp256k1
    PREFIX ${secp256k1_prefix}
    SOURCE_DIR ${secp256k1_srcdir}
    DOWNLOAD_COMMAND cd ${secp256k1_srcdir} && git clean -dfX &&
        ${secp256k1_srcdir}/autogen.sh
    CONFIGURE_COMMAND ${secp256k1_srcdir}/configure
        CFLAGS=${external_project_cflags}
        --srcdir=${secp256k1_srcdir}
        --prefix=${secp256k1_prefix}
        --host=arm-zephyr-eabi
        --disable-shared
        --enable-static
        --disable-benchmark
        --enable-experimental
        --enable-module-recovery
        --with-asm=arm
        --with-ecmult-window=8
        --with-ecmult-gen-precision=2
    BUILD_COMMAND make
    INSTALL_COMMAND make install
    BUILD_BYPRODUCTS ${secp256k1_prefix}/lib/libsecp256k1.a)
add_library(secp256k1 STATIC IMPORTED GLOBAL)
add_dependencies(secp256k1 libsecp256k1)
file(MAKE_DIRECTORY ${secp256k1_prefix}/include)
set_target_properties(secp256k1 PROPERTIES
    IMPORTED_LOCATION ${secp256k1_prefix}/lib/libsecp256k1.a
    INTERFACE_INCLUDE_DIRECTORIES ${secp256k1_prefix}/include)
target_link_libraries(app PRIVATE nrfxlib_crypto secp256k1)

*******************************************************************************/

#include <stdint.h>
#include <string.h>

#include <zephyr/kernel.h>
#include <zephyr/timing/timing.h>

#include <ocrypto_sha256.h>
#include <secp256k1_recovery.h>
#include <sha3.h>

#if DEBUG
#define debug(...) printk(__VA_ARGS__)
#else
#define debug(...) (void) 0
#endif

#define array_count(array) ((size_t)(sizeof(array) / sizeof((array)[0])))

#define TX_DEPTH (20)
#define MAX_TRANSACTIONS_PER_PAYLOAD ((uint32_t) 1 << TX_DEPTH)

typedef uint8_t Bytes20[20];
typedef uint8_t Bytes32[32];
typedef Bytes20 ExecutionAddress;
typedef Bytes32 Hash32;
typedef Bytes32 Root;

typedef enum __attribute__((packed)) {
    DESTINATION_TYPE_REGULAR = 0x00,
    DESTINATION_TYPE_CREATE = 0x01
} DestinationType;

typedef struct {
    DestinationType destination_type;
    ExecutionAddress address;
} DestinationAddress;

typedef struct {
    Bytes32 max_priority_fee_per_gas;
    Bytes32 max_fee_per_gas;
    uint64_t gas;
} TransactionLimits;

typedef struct {
    uint32_t tx_index;
    Hash32 tx_hash;
    ExecutionAddress tx_from;
    uint64_t nonce;
    DestinationAddress tx_to;
    Bytes32 tx_value;
    TransactionLimits limits;
} TransactionInfo;

static const Root zero_hash[] = {
    {0},
    {
        0xf5, 0xa5, 0xfd, 0x42, 0xd1, 0x6a, 0x20, 0x30,
        0x27, 0x98, 0xef, 0x6e, 0xd3, 0x09, 0x97, 0x9b,
        0x43, 0x00, 0x3d, 0x23, 0x20, 0xd9, 0xf0, 0xe8,
        0xea, 0x98, 0x31, 0xa9, 0x27, 0x59, 0xfb, 0x4b
    }
};

typedef struct {
    Bytes32 chain_id;
} ExecutionConfig;

static void hash_combine(Root *root, const Root *a, const Root *b)
{
    ocrypto_sha256_ctx ctx;
    ocrypto_sha256_init(&ctx);
    ocrypto_sha256_update(&ctx, &(*a)[0], sizeof *a);
    ocrypto_sha256_update(&ctx, &(*b)[0], sizeof *b);
    ocrypto_sha256_final(&ctx, &(*root)[0]);
}

#define consume(n) \
    do { \
        proof = (const uint8_t *) proof + (n); \
        num_proof_bytes -= (n); \
    } while (0)

__attribute__((warn_unused_result))
static int verify_transaction_proof(
    const void *proof,
    size_t num_proof_bytes,
    const ExecutionConfig *cfg __attribute__((unused)),
    const Root *transactions_root,
    const Root *expected_tx_hash)
{
    Root root;

    // tx_root
    const Root *tx_root = proof;
    if (num_proof_bytes < sizeof *tx_root) return 1;
    if (memcmp(tx_root, expected_tx_hash, sizeof *tx_root)) return 1;
    consume(sizeof *tx_root);

    // tx_selector
    const uint8_t *tx_selector = proof;
    if (num_proof_bytes < sizeof *tx_selector) return 1;
    consume(sizeof *tx_selector);

    // transaction_root
    /*  3 */ root[0] = *tx_selector; memset(&root[1], 0, 31);
    /*  1 */ hash_combine(&root, tx_root, &root);

    // tx_index
    const uint32_t *tx_index = proof;
    if (num_proof_bytes < sizeof *tx_index) return 1;
    if (*tx_index >= MAX_TRANSACTIONS_PER_PAYLOAD) return 1;
    consume(sizeof *tx_index);

    // transactions_root
    const Root *tx_branch = proof;
    if (num_proof_bytes < (1 + TX_DEPTH) * sizeof *tx_branch) return 1;
    for (int i = 0; i < TX_DEPTH; i++) {
        if (*tx_index & ((uint32_t) 1 << i))
            hash_combine(&root, tx_branch, &root);
        else
            hash_combine(&root, &root, tx_branch);
        tx_branch++;
    }
    hash_combine(&root, &root, tx_branch);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    if (num_proof_bytes) return 1;
    return 0;
}

__attribute__((warn_unused_result))
static int verify_amount_proof(
    const void *proof,
    size_t num_proof_bytes,
    const ExecutionConfig *cfg __attribute__((unused)),
    const Root *transactions_root,
    const ExecutionAddress *expected_tx_to,
    const Bytes32 *expected_tx_value_min)
{
    Root root, scratch;

    // &tx_proof
    const uint32_t *tx_proof_offset = proof;
    if (num_proof_bytes < sizeof *tx_proof_offset) return 1;
    if (*tx_proof_offset != 680) return 1;
    consume(sizeof *tx_proof_offset);

    // tx_index
    const uint32_t *tx_index = proof;
    if (num_proof_bytes < sizeof *tx_index) return 1;
    if (*tx_index >= MAX_TRANSACTIONS_PER_PAYLOAD) return 1;
    consume(sizeof *tx_index);

    // tx_branch
    const Root *tx_branch = proof;
    if (num_proof_bytes < (1 + TX_DEPTH) * sizeof *tx_branch) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    // tx_selector
    const uint8_t *tx_selector = proof;
    if (num_proof_bytes < sizeof *tx_selector) return 1;
    consume(sizeof *tx_selector);

    // tx_root
    switch (*tx_selector) {
        case 3: {
            // gas
            const uint64_t *gas = proof;
            if (num_proof_bytes < sizeof *gas) return 1;
            consume(sizeof *gas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 172) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            for (int i = sizeof *value - 1; i >= 0; i--) {
                if ((*value)[i] > (*expected_tx_value_min)[i]) break;
                if ((*value)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 3 * sizeof *multi_branch) return 1;
            consume(3 * sizeof *multi_branch);

            // signature_root
            const Root *signature_root = proof;
            if (num_proof_bytes < sizeof *signature_root) return 1;
            consume(sizeof *signature_root);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            const ExecutionAddress *to = proof;
            if (num_proof_bytes < sizeof *to) return 1;
            if (memcmp(to, expected_tx_to, sizeof *to)) return 1;
            consume(sizeof *to);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 42 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
            /* 43 */ scratch[0] = 1; memset(&scratch[1], 0, 31);
            /* 21 */ hash_combine(&scratch, &root, &scratch);
            /* 20 */ memcpy(&root[0], gas, 8); memset(&root[8], 0, 24);
            /* 10 */ hash_combine(&root, &root, &scratch);
            /* 11 */ hash_combine(&scratch, value, &multi_branch[0]);
            /*  5 */ hash_combine(&root, &root, &scratch);
            /*  2 */ hash_combine(&root, &multi_branch[1], &root);
            /*  1 */ hash_combine(&root, &root, &multi_branch[2]);

            // tx_root
            hash_combine(&root, &root, signature_root);
        } break;
        case 2: {
            // gas_limit
            const uint64_t *gas_limit = proof;
            if (num_proof_bytes < sizeof *gas_limit) return 1;
            consume(sizeof *gas_limit);

            // &destination
            const uint32_t *destination_offset = proof;
            if (num_proof_bytes < sizeof *destination_offset) return 1;
            if (*destination_offset != 172) return 1;
            consume(sizeof *destination_offset);

            // amount
            const Bytes32 *amount = proof;
            if (num_proof_bytes < sizeof *amount) return 1;
            for (int i = sizeof *amount - 1; i >= 0; i--) {
                if ((*amount)[i] > (*expected_tx_value_min)[i]) break;
                if ((*amount)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *amount);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 3 * sizeof *multi_branch) return 1;
            consume(3 * sizeof *multi_branch);

            // signature_root
            const Root *signature_root = proof;
            if (num_proof_bytes < sizeof *signature_root) return 1;
            consume(sizeof *signature_root);

            // destination_selector
            const uint8_t *destination_selector = proof;
            if (num_proof_bytes < sizeof *destination_selector) return 1;
            if (*destination_selector != 1) return 1;
            consume(sizeof *destination_selector);

            // destination
            const ExecutionAddress *dest = proof;
            if (num_proof_bytes < sizeof *dest) return 1;
            if (memcmp(dest, expected_tx_to, sizeof *dest)) return 1;
            consume(sizeof *dest);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 42 */ memcpy(&root[0], dest, 20); memset(&root[20], 0, 12);
            /* 43 */ scratch[0] = 1; memset(&scratch[1], 0, 31);
            /* 21 */ hash_combine(&scratch, &root, &scratch);
            /* 20 */ memcpy(&root[0], gas_limit, 8); memset(&root[8], 0, 24);
            /* 10 */ hash_combine(&root, &root, &scratch);
            /* 11 */ hash_combine(&scratch, amount, &multi_branch[0]);
            /*  5 */ hash_combine(&root, &root, &scratch);
            /*  2 */ hash_combine(&root, &multi_branch[1], &root);
            /*  1 */ hash_combine(&root, &root, &multi_branch[2]);

            // tx_root
            hash_combine(&root, &root, signature_root);
        } break;
        case 1: {
            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 132) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            for (int i = sizeof *value - 1; i >= 0; i--) {
                if ((*value)[i] > (*expected_tx_value_min)[i]) break;
                if ((*value)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
            consume(2 * sizeof *multi_branch);

            // signature_root
            const Root *signature_root = proof;
            if (num_proof_bytes < sizeof *signature_root) return 1;
            consume(sizeof *signature_root);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            const ExecutionAddress *to = proof;
            if (num_proof_bytes < sizeof *to) return 1;
            if (memcmp(to, expected_tx_to, sizeof *to)) return 1;
            consume(sizeof *to);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 24 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
            /* 25 */ scratch[0] = 1; memset(&scratch[1], 0, 31);
            /* 12 */ hash_combine(&root, &root, &scratch);
            /*  6 */ hash_combine(&root, &root, value);
            /*  3 */ hash_combine(&root, &root, &multi_branch[0]);
            /*  1 */ hash_combine(&root, &multi_branch[1], &root);

            // tx_root
            hash_combine(&root, &root, signature_root);
        } break;
        case 0: {
            // startgas
            const uint64_t *startgas = proof;
            if (num_proof_bytes < sizeof *startgas) return 1;
            consume(sizeof *startgas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 140) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            for (int i = sizeof *value - 1; i >= 0; i--) {
                if ((*value)[i] > (*expected_tx_value_min)[i]) break;
                if ((*value)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
            consume(2 * sizeof *multi_branch);

            // signature_root
            const Root *signature_root = proof;
            if (num_proof_bytes < sizeof *signature_root) return 1;
            consume(sizeof *signature_root);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            const ExecutionAddress *to = proof;
            if (num_proof_bytes < sizeof *to) return 1;
            if (memcmp(to, expected_tx_to, sizeof *to)) return 1;
            consume(sizeof *to);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 22 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
            /* 23 */ scratch[0] = 1; memset(&scratch[1], 0, 31);
            /* 11 */ hash_combine(&scratch, &root, &scratch);
            /* 10 */ memcpy(&root[0], startgas, 8); memset(&root[8], 0, 24);
            /*  5 */ hash_combine(&root, &root, &scratch);
            /*  6 */ hash_combine(&scratch, value, &multi_branch[0]);
            /*  3 */ hash_combine(&scratch, &scratch, &zero_hash[1]);
            /*  2 */ hash_combine(&root, &multi_branch[1], &root);
            /*  1 */ hash_combine(&root, &root, &scratch);

            // tx_root
            hash_combine(&root, &root, signature_root);
        } break;
        default: return 1;
    }

    // transaction_root
    /*  3 */ scratch[0] = *tx_selector; memset(&scratch[1], 0, 31);
    /*  1 */ hash_combine(&root, &root, &scratch);

    // transactions_root
    for (int i = 0; i < TX_DEPTH; i++) {
        if (*tx_index & ((uint32_t) 1 << i))
            hash_combine(&root, tx_branch, &root);
        else
            hash_combine(&root, &root, tx_branch);
        tx_branch++;
    }
    hash_combine(&root, &root, tx_branch);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;

    return 0;
}

__attribute__((warn_unused_result))
static int verify_sender_proof(
    const void *proof,
    size_t num_proof_bytes,
    const ExecutionConfig *cfg __attribute__((unused)),
    const Root *transactions_root,
    const ExecutionAddress *expected_tx_to,
    const Bytes32 *expected_tx_value_min,
    ExecutionAddress *tx_from)
{
    uint8_t y;
    Root root, scratch[2];

    // &tx_proof
    const uint32_t *tx_proof_offset = proof;
    if (num_proof_bytes < sizeof *tx_proof_offset) return 1;
    if (*tx_proof_offset != 680) return 1;
    consume(sizeof *tx_proof_offset);

    // tx_index
    const uint32_t *tx_index = proof;
    if (num_proof_bytes < sizeof *tx_index) return 1;
    if (*tx_index >= MAX_TRANSACTIONS_PER_PAYLOAD) return 1;
    consume(sizeof *tx_index);

    // tx_branch
    const Root *tx_branch = proof;
    if (num_proof_bytes < (1 + TX_DEPTH) * sizeof *tx_branch) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    // tx_selector
    const uint8_t *tx_selector = proof;
    if (num_proof_bytes < sizeof *tx_selector) return 1;
    consume(sizeof *tx_selector);

    // tx_root
    const uint8_t *y_parity;
    const Bytes32 *r;
    const Bytes32 *s;
    switch (*tx_selector) {
        case 3: {
            // gas
            const uint64_t *gas = proof;
            if (num_proof_bytes < sizeof *gas) return 1;
            consume(sizeof *gas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 205) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            for (int i = sizeof *value - 1; i >= 0; i--) {
                if ((*value)[i] > (*expected_tx_value_min)[i]) break;
                if ((*value)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 3 * sizeof *multi_branch) return 1;
            consume(3 * sizeof *multi_branch);

            // signature.y_parity
            y_parity = proof;
            if (num_proof_bytes < sizeof *y_parity) return 1;
            if (*y_parity > 1) return 1;
            consume(sizeof *y_parity);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            const ExecutionAddress *to = proof;
            if (num_proof_bytes < sizeof *to) return 1;
            if (memcmp(to, expected_tx_to, sizeof *to)) return 1;
            consume(sizeof *to);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 42 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
            /* 43 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
            /* 21 */ hash_combine(&scratch[0], &root, &scratch[0]);
            /* 20 */ memcpy(&root[0], gas, 8); memset(&root[8], 0, 24);
            /* 10 */ hash_combine(&root, &root, &scratch[0]);
            /* 11 */ hash_combine(&scratch[0], value, &multi_branch[0]);
            /*  5 */ hash_combine(&root, &root, &scratch[0]);
            /*  2 */ hash_combine(&root, &multi_branch[1], &root);
            /*  1 */ hash_combine(&root, &root, &multi_branch[2]);

            // signature_root
            /*  4 */ scratch[0][0] = *y_parity; memset(&scratch[0][1], 0, 31);
            /*  2 */ hash_combine(&scratch[0], &scratch[0], r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        case 2: {
            // gas_limit
            const uint64_t *gas_limit = proof;
            if (num_proof_bytes < sizeof *gas_limit) return 1;
            consume(sizeof *gas_limit);

            // &destination
            const uint32_t *destination_offset = proof;
            if (num_proof_bytes < sizeof *destination_offset) return 1;
            if (*destination_offset != 205) return 1;
            consume(sizeof *destination_offset);

            // amount
            const Bytes32 *amount = proof;
            if (num_proof_bytes < sizeof *amount) return 1;
            for (int i = sizeof *amount - 1; i >= 0; i--) {
                if ((*amount)[i] > (*expected_tx_value_min)[i]) break;
                if ((*amount)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *amount);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 3 * sizeof *multi_branch) return 1;
            consume(3 * sizeof *multi_branch);

            // signature.y_parity
            y_parity = proof;
            if (num_proof_bytes < sizeof *y_parity) return 1;
            if (*y_parity > 1) return 1;
            consume(sizeof *y_parity);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // destination_selector
            const uint8_t *destination_selector = proof;
            if (num_proof_bytes < sizeof *destination_selector) return 1;
            if (*destination_selector != 1) return 1;
            consume(sizeof *destination_selector);

            // destination
            const ExecutionAddress *dest = proof;
            if (num_proof_bytes < sizeof *dest) return 1;
            if (memcmp(dest, expected_tx_to, sizeof *dest)) return 1;
            consume(sizeof *dest);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 42 */ memcpy(&root[0], dest, 20); memset(&root[20], 0, 12);
            /* 43 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
            /* 21 */ hash_combine(&scratch[0], &root, &scratch[0]);
            /* 20 */ memcpy(&root[0], gas_limit, 8); memset(&root[8], 0, 24);
            /* 10 */ hash_combine(&root, &root, &scratch[0]);
            /* 11 */ hash_combine(&scratch[0], amount, &multi_branch[0]);
            /*  5 */ hash_combine(&root, &root, &scratch[0]);
            /*  2 */ hash_combine(&root, &multi_branch[1], &root);
            /*  1 */ hash_combine(&root, &root, &multi_branch[2]);

            // signature_root
            /*  4 */ scratch[0][0] = *y_parity; memset(&scratch[0][1], 0, 31);
            /*  2 */ hash_combine(&scratch[0], &scratch[0], r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        case 1: {
            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 165) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            for (int i = sizeof *value - 1; i >= 0; i--) {
                if ((*value)[i] > (*expected_tx_value_min)[i]) break;
                if ((*value)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
            consume(2 * sizeof *multi_branch);

            // signature.y_parity
            y_parity = proof;
            if (num_proof_bytes < sizeof *y_parity) return 1;
            if (*y_parity > 1) return 1;
            consume(sizeof *y_parity);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            const ExecutionAddress *to = proof;
            if (num_proof_bytes < sizeof *to) return 1;
            if (memcmp(to, expected_tx_to, sizeof *to)) return 1;
            consume(sizeof *to);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 24 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
            /* 25 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
            /* 12 */ hash_combine(&root, &root, &scratch[0]);
            /*  6 */ hash_combine(&root, &root, value);
            /*  3 */ hash_combine(&root, &root, &multi_branch[0]);
            /*  1 */ hash_combine(&root, &multi_branch[1], &root);

            // signature_root
            /*  4 */ scratch[0][0] = *y_parity; memset(&scratch[0][1], 0, 31);
            /*  2 */ hash_combine(&scratch[0], &scratch[0], r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        case 0: {
            // startgas
            const uint64_t *startgas = proof;
            if (num_proof_bytes < sizeof *startgas) return 1;
            consume(sizeof *startgas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 204) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            for (int i = sizeof *value - 1; i >= 0; i--) {
                if ((*value)[i] > (*expected_tx_value_min)[i]) break;
                if ((*value)[i] < (*expected_tx_value_min)[i]) return 1;
            }
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
            consume(2 * sizeof *multi_branch);

            // signature.v
            const Bytes32 *v = proof;
            if (num_proof_bytes < sizeof *v) return 1;
            y = (((*v)[0] & 0x1) == 0);
            y_parity = &y;
            consume(sizeof *v);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            const ExecutionAddress *to = proof;
            if (num_proof_bytes < sizeof *to) return 1;
            if (memcmp(to, expected_tx_to, sizeof *to)) return 1;
            consume(sizeof *to);

            // sig_root
            if (num_proof_bytes) return 1;
            /* 22 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
            /* 23 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
            /* 11 */ hash_combine(&scratch[0], &root, &scratch[0]);
            /* 10 */ memcpy(&root[0], startgas, 8); memset(&root[8], 0, 24);
            /*  5 */ hash_combine(&root, &root, &scratch[0]);
            /*  6 */ hash_combine(&scratch[0], value, &multi_branch[0]);
            /*  3 */ hash_combine(&scratch[0], &scratch[0], &zero_hash[1]);
            /*  2 */ hash_combine(&root, &multi_branch[1], &root);
            /*  1 */ hash_combine(&root, &root, &scratch[0]);

            // signature_root
            /*  2 */ hash_combine(&scratch[0], v, r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        default: return 1;
    }

    // tx_from
    uint8_t ser_sig[64];
    for (size_t i = 0; i < 32; i++) {
        ser_sig[i] = (*r)[31 - i];
        ser_sig[i + 32] = (*s)[31 - i];
    }
    secp256k1_ecdsa_recoverable_signature recover_sig;
    if (!secp256k1_ecdsa_recoverable_signature_parse_compact(
        secp256k1_context_static, &recover_sig, ser_sig, *y_parity))
    {
        return 1;
    }
    secp256k1_pubkey public_key;
    if (!secp256k1_ecdsa_recover(
        secp256k1_context_static, &public_key, &recover_sig, &root[0]))
    {
        return 1;
    }
    uint8_t uncompressed[65];
    size_t n = sizeof uncompressed;
    if (!secp256k1_ec_pubkey_serialize(
        secp256k1_context_static, uncompressed, &n,
        &public_key, SECP256K1_EC_UNCOMPRESSED))
    {
        debug("secp256k1_ec_pubkey_serialize failed\n");
    }
    if (n != sizeof uncompressed)
        debug("secp256k1_ec_pubkey_serialize failed: Length %zu\n", n);
    sha3_context ctx;
    if (sha3_Init(&ctx, 256))
        debug("sha3_Init failed\n");
    if (sha3_SetFlags(&ctx, SHA3_FLAGS_KECCAK) != SHA3_FLAGS_KECCAK)
        debug("sha3_SetFlags failed\n");
    sha3_Update(&ctx, uncompressed, sizeof uncompressed);
    memcpy(tx_from, &((const uint8_t *) sha3_Finalize(&ctx))[12], 20);

    // tx_root
    hash_combine(&root, &root, &scratch[0]);

    // transaction_root
    /*  3 */ scratch[0][0] = *tx_selector; memset(&scratch[0][1], 0, 31);
    /*  1 */ hash_combine(&root, &root, &scratch[0]);

    // transactions_root
    for (int i = 0; i < TX_DEPTH; i++) {
        if (*tx_index & ((uint32_t) 1 << i))
            hash_combine(&root, tx_branch, &root);
        else
            hash_combine(&root, &root, tx_branch);
        tx_branch++;
    }
    hash_combine(&root, &root, tx_branch);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;

    return 0;
}

__attribute__((warn_unused_result))
static int verify_info_proof(
    const void *proof,
    size_t num_proof_bytes,
    const ExecutionConfig *cfg,
    const Root *transactions_root,
    TransactionInfo *info)
{
    memset(info, 0, sizeof *info);

    uint8_t y;
    Root root, scratch[2];

    // &tx_proof
    const uint32_t *tx_proof_offset = proof;
    if (num_proof_bytes < sizeof *tx_proof_offset) return 1;
    if (*tx_proof_offset != 680) return 1;
    consume(sizeof *tx_proof_offset);

    // tx_index
    const uint32_t *tx_index = proof;
    if (num_proof_bytes < sizeof *tx_index) return 1;
    if (*tx_index >= MAX_TRANSACTIONS_PER_PAYLOAD) return 1;
    info->tx_index = *tx_index;
    consume(sizeof *tx_index);

    // tx_branch
    const Root *tx_branch = proof;
    if (num_proof_bytes < (1 + TX_DEPTH) * sizeof *tx_branch) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    // tx_selector
    const uint8_t *tx_selector = proof;
    if (num_proof_bytes < sizeof *tx_selector) return 1;
    consume(sizeof *tx_selector);

    // tx_root
    const uint8_t *y_parity;
    const Bytes32 *r;
    const Bytes32 *s;
    switch (*tx_selector) {
        case 3: {
            // nonce
            const uint64_t *nonce = proof;
            if (num_proof_bytes < sizeof *nonce) return 1;
            info->nonce = *nonce;
            consume(sizeof *nonce);

            // max_priority_fee_per_gas
            const Bytes32 *prio = proof;
            if (num_proof_bytes < sizeof *prio) return 1;
            memcpy(info->limits.max_priority_fee_per_gas, prio, sizeof *prio);
            consume(sizeof *prio);

            // max_fee_per_gas
            const Bytes32 *max_fee = proof;
            if (num_proof_bytes < sizeof *max_fee) return 1;
            memcpy(info->limits.max_fee_per_gas, max_fee, sizeof *max_fee);
            consume(sizeof *max_fee);

            // gas
            const uint64_t *gas = proof;
            if (num_proof_bytes < sizeof *gas) return 1;
            info->limits.gas = *gas;
            consume(sizeof *gas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 245) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            memcpy(info->tx_value, value, sizeof *value);
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
            consume(2 * sizeof *multi_branch);

            // signature.y_parity
            y_parity = proof;
            if (num_proof_bytes < sizeof *y_parity) return 1;
            if (*y_parity > 1) return 1;
            consume(sizeof *y_parity);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            consume(sizeof *to_selector);

            // to
            switch (*to_selector) {
                case 0: {
                    info->tx_to.destination_type = DESTINATION_TYPE_CREATE;

                    if (num_proof_bytes) return 1;
                    /* 21 */ memcpy(&scratch[0], &zero_hash[1], 32);
                } break;
                case 1: {
                    info->tx_to.destination_type = DESTINATION_TYPE_REGULAR;

                    const ExecutionAddress *to = proof;
                    if (num_proof_bytes < sizeof *to) return 1;
                    memcpy(info->tx_to.address, to, sizeof *to);
                    consume(sizeof *to);

                    if (num_proof_bytes) return 1;
                    /* 42 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
                    /* 43 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
                    /* 21 */ hash_combine(&scratch[0], &root, &scratch[0]);
                } break;
                default: return 1;
            }

            // sig_root
            /* 20 */ memcpy(&root[0], gas, 8); memset(&root[8], 0, 24);
            /* 10 */ hash_combine(&root, &root, &scratch[0]);
            /* 11 */ hash_combine(&scratch[0], value, &multi_branch[0]);
            /*  5 */ hash_combine(&scratch[0], &root, &scratch[0]);
            /* 17 */ memcpy(&root[0], nonce, 8); memset(&root[8], 0, 24);
            /*  8 */ hash_combine(&root, &cfg->chain_id, &root);
            /*  9 */ hash_combine(&scratch[1], prio, max_fee);
            /*  4 */ hash_combine(&root, &root, &scratch[1]);
            /*  2 */ hash_combine(&root, &root, &scratch[0]);
            /*  1 */ hash_combine(&root, &root, &multi_branch[1]);

            // signature_root
            /*  4 */ scratch[0][0] = *y_parity; memset(&scratch[0][1], 0, 31);
            /*  2 */ hash_combine(&scratch[0], &scratch[0], r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        case 2: {
            // nonce
            const uint64_t *nonce = proof;
            if (num_proof_bytes < sizeof *nonce) return 1;
            info->nonce = *nonce;
            consume(sizeof *nonce);

            // max_priority_fee_per_gas
            const Bytes32 *prio = proof;
            if (num_proof_bytes < sizeof *prio) return 1;
            memcpy(info->limits.max_priority_fee_per_gas, prio, sizeof *prio);
            consume(sizeof *prio);

            // max_fee_per_gas
            const Bytes32 *max_fee = proof;
            if (num_proof_bytes < sizeof *max_fee) return 1;
            memcpy(info->limits.max_fee_per_gas, max_fee, sizeof *max_fee);
            consume(sizeof *max_fee);

            // gas_limit
            const uint64_t *gas_limit = proof;
            if (num_proof_bytes < sizeof *gas_limit) return 1;
            info->limits.gas = *gas_limit;
            consume(sizeof *gas_limit);

            // &destination
            const uint32_t *destination_offset = proof;
            if (num_proof_bytes < sizeof *destination_offset) return 1;
            if (*destination_offset != 245) return 1;
            consume(sizeof *destination_offset);

            // amount
            const Bytes32 *amount = proof;
            if (num_proof_bytes < sizeof *amount) return 1;
            memcpy(info->tx_value, amount, sizeof *amount);
            consume(sizeof *amount);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
            consume(2 * sizeof *multi_branch);

            // signature.y_parity
            y_parity = proof;
            if (num_proof_bytes < sizeof *y_parity) return 1;
            if (*y_parity > 1) return 1;
            consume(sizeof *y_parity);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // destination_selector
            const uint8_t *destination_selector = proof;
            if (num_proof_bytes < sizeof *destination_selector) return 1;
            if (*destination_selector != 1) return 1;
            consume(sizeof *destination_selector);

            // destination
            switch (*destination_selector) {
                case 0: {
                    info->tx_to.destination_type = DESTINATION_TYPE_CREATE;

                    if (num_proof_bytes) return 1;
                    /* 21 */ memcpy(&scratch[0], &zero_hash[1], 32);
                } break;
                case 1: {
                    info->tx_to.destination_type = DESTINATION_TYPE_REGULAR;

                    const ExecutionAddress *d = proof;
                    if (num_proof_bytes < sizeof *d) return 1;
                    memcpy(info->tx_to.address, d, sizeof *d);
                    consume(sizeof *d);

                    if (num_proof_bytes) return 1;
                    /* 42 */ memcpy(&root[0], d, 20); memset(&root[20], 0, 12);
                    /* 43 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
                    /* 21 */ hash_combine(&scratch[0], &root, &scratch[0]);
                } break;
                default: return 1;
            }

            // sig_root
            /* 20 */ memcpy(&root[0], gas_limit, 8); memset(&root[8], 0, 24);
            /* 10 */ hash_combine(&root, &root, &scratch[0]);
            /* 11 */ hash_combine(&scratch[0], amount, &multi_branch[0]);
            /*  5 */ hash_combine(&scratch[0], &root, &scratch[0]);
            /* 17 */ memcpy(&root[0], nonce, 8); memset(&root[8], 0, 24);
            /*  8 */ hash_combine(&root, &cfg->chain_id, &root);
            /*  9 */ hash_combine(&scratch[1], prio, max_fee);
            /*  4 */ hash_combine(&root, &root, &scratch[1]);
            /*  2 */ hash_combine(&root, &root, &scratch[0]);
            /*  1 */ hash_combine(&root, &root, &multi_branch[1]);

            // signature_root
            /*  4 */ scratch[0][0] = *y_parity; memset(&scratch[0][1], 0, 31);
            /*  2 */ hash_combine(&scratch[0], &scratch[0], r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        case 1: {
            // nonce
            const uint64_t *nonce = proof;
            if (num_proof_bytes < sizeof *nonce) return 1;
            info->nonce = *nonce;
            consume(sizeof *nonce);

            // gas_price
            const Bytes32 *price = proof;
            if (num_proof_bytes < sizeof *price) return 1;
            memcpy(info->limits.max_priority_fee_per_gas, price, sizeof *price);
            memcpy(info->limits.max_fee_per_gas, price, sizeof *price);
            consume(sizeof *price);

            // gas
            const uint64_t *gas = proof;
            if (num_proof_bytes < sizeof *gas) return 1;
            info->limits.gas = *gas;
            consume(sizeof *gas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 181) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            memcpy(info->tx_value, value, sizeof *value);
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 1 * sizeof *multi_branch) return 1;
            consume(1 * sizeof *multi_branch);

            // signature.y_parity
            y_parity = proof;
            if (num_proof_bytes < sizeof *y_parity) return 1;
            if (*y_parity > 1) return 1;
            consume(sizeof *y_parity);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            switch (*to_selector) {
                case 0: {
                    info->tx_to.destination_type = DESTINATION_TYPE_CREATE;

                    if (num_proof_bytes) return 1;
                    /* 12 */ memcpy(&root, &zero_hash[1], 32);
                } break;
                case 1: {
                    info->tx_to.destination_type = DESTINATION_TYPE_REGULAR;

                    const ExecutionAddress *to = proof;
                    if (num_proof_bytes < sizeof *to) return 1;
                    memcpy(info->tx_to.address, to, sizeof *to);
                    consume(sizeof *to);

                    if (num_proof_bytes) return 1;
                    /* 24 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
                    /* 25 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
                    /* 12 */ hash_combine(&root, &root, &scratch[0]);
                } break;
                default: return 1;
            }

            // sig_root
            /*  6 */ hash_combine(&scratch[1], &root, value);
            /* 11 */ memcpy(&root[0], gas, 8); memset(&root[8], 0, 24);
            /*  5 */ hash_combine(&scratch[0], price, &root);
            /*  9 */ memcpy(&root[0], nonce, 8); memset(&root[8], 0, 24);
            /*  4 */ hash_combine(&root, &cfg->chain_id, &root);
            /*  2 */ hash_combine(&root, &root, &scratch[0]);
            /*  3 */ hash_combine(&scratch[0], &scratch[1], &multi_branch[0]);
            /*  1 */ hash_combine(&root, &root, &scratch[0]);

            // signature_root
            /*  4 */ scratch[0][0] = *y_parity; memset(&scratch[0][1], 0, 31);
            /*  2 */ hash_combine(&scratch[0], &scratch[0], r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        case 0: {
            // nonce
            const uint64_t *nonce = proof;
            if (num_proof_bytes < sizeof *nonce) return 1;
            info->nonce = *nonce;
            consume(sizeof *nonce);

            // gasprice
            const Bytes32 *price = proof;
            if (num_proof_bytes < sizeof *price) return 1;
            memcpy(info->limits.max_priority_fee_per_gas, price, sizeof *price);
            memcpy(info->limits.max_fee_per_gas, price, sizeof *price);
            consume(sizeof *price);

            // startgas
            const uint64_t *startgas = proof;
            if (num_proof_bytes < sizeof *startgas) return 1;
            info->limits.gas = *startgas;
            consume(sizeof *startgas);

            // &to
            const uint32_t *to_offset = proof;
            if (num_proof_bytes < sizeof *to_offset) return 1;
            if (*to_offset != 212) return 1;
            consume(sizeof *to_offset);

            // value
            const Bytes32 *value = proof;
            if (num_proof_bytes < sizeof *value) return 1;
            memcpy(info->tx_value, value, sizeof *value);
            consume(sizeof *value);

            // multi_branch
            const Root *multi_branch = proof;
            if (num_proof_bytes < 1 * sizeof *multi_branch) return 1;
            consume(1 * sizeof *multi_branch);

            // signature.v
            const Bytes32 *v = proof;
            if (num_proof_bytes < sizeof *v) return 1;
            y = (((*v)[0] & 0x1) == 0);
            y_parity = &y;
            consume(sizeof *v);

            // signature.r
            r = proof;
            if (num_proof_bytes < sizeof *r) return 1;
            consume(sizeof *r);

            // signature.s
            s = proof;
            if (num_proof_bytes < sizeof *s) return 1;
            consume(sizeof *s);

            // to_selector
            const uint8_t *to_selector = proof;
            if (num_proof_bytes < sizeof *to_selector) return 1;
            if (*to_selector != 1) return 1;
            consume(sizeof *to_selector);

            // to
            switch (*to_selector) {
                case 0: {
                    info->tx_to.destination_type = DESTINATION_TYPE_CREATE;

                    if (num_proof_bytes) return 1;
                    /* 11 */ memcpy(&scratch[0], &zero_hash[1], 32);
                } break;
                case 1: {
                    info->tx_to.destination_type = DESTINATION_TYPE_REGULAR;

                    const ExecutionAddress *to = proof;
                    if (num_proof_bytes < sizeof *to) return 1;
                    memcpy(info->tx_to.address, to, sizeof *to);
                    consume(sizeof *to);

                    if (num_proof_bytes) return 1;
                    /* 22 */ memcpy(&root[0], to, 20); memset(&root[20], 0, 12);
                    /* 23 */ scratch[0][0] = 1; memset(&scratch[0][1], 0, 31);
                    /* 11 */ hash_combine(&scratch[0], &root, &scratch[0]);
                } break;
                default: return 1;
            }

            // sig_root
            /* 10 */ memcpy(&root[0], startgas, 8); memset(&root[8], 0, 24);
            /*  5 */ hash_combine(&scratch[0], &root, &scratch[0]);
            /*  6 */ hash_combine(&scratch[1], value, &multi_branch[0]);
            /*  3 */ hash_combine(&scratch[1], &scratch[1], &zero_hash[1]);
            /*  8 */ memcpy(&root[0], nonce, 8); memset(&root[8], 0, 24);
            /*  4 */ hash_combine(&root, &root, price);
            /*  2 */ hash_combine(&root, &root, &scratch[0]);
            /*  1 */ hash_combine(&root, &root, &scratch[1]);

            // signature_root
            /*  2 */ hash_combine(&scratch[0], v, r);
            /*  3 */ hash_combine(&scratch[1], s, &zero_hash[0]);
            /*  1 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
        } break;
        default: return 1;
    }

    // tx_from
    uint8_t ser_sig[64];
    for (size_t i = 0; i < 32; i++) {
        ser_sig[i] = (*r)[31 - i];
        ser_sig[i + 32] = (*s)[31 - i];
    }
    secp256k1_ecdsa_recoverable_signature recover_sig;
    if (!secp256k1_ecdsa_recoverable_signature_parse_compact(
        secp256k1_context_static, &recover_sig, ser_sig, *y_parity))
    {
        return 1;
    }
    secp256k1_pubkey public_key;
    if (!secp256k1_ecdsa_recover(
        secp256k1_context_static, &public_key, &recover_sig, &root[0]))
    {
        return 1;
    }
    uint8_t uncompressed[65];
    size_t n = sizeof uncompressed;
    if (!secp256k1_ec_pubkey_serialize(
        secp256k1_context_static, uncompressed, &n,
        &public_key, SECP256K1_EC_UNCOMPRESSED))
    {
        debug("secp256k1_ec_pubkey_serialize failed\n");
    }
    if (n != sizeof uncompressed)
        debug("secp256k1_ec_pubkey_serialize failed: Length %zu\n", n);
    sha3_context ctx;
    if (sha3_Init(&ctx, 256))
        debug("sha3_Init failed\n");
    if (sha3_SetFlags(&ctx, SHA3_FLAGS_KECCAK) != SHA3_FLAGS_KECCAK)
        debug("sha3_SetFlags failed\n");
    sha3_Update(&ctx, uncompressed, sizeof uncompressed);
    memcpy(info->tx_from, &((const uint8_t *) sha3_Finalize(&ctx))[12], 20);

    // tx_to.address
    switch (info->tx_to.destination_type) {
        case DESTINATION_TYPE_REGULAR: break;
        case DESTINATION_TYPE_CREATE: {
            ExecutionAddress *address = &info->tx_to.address;
            uint8_t n = 0;
            uint8_t rlp_data[30];
            rlp_data[0] = 0x80 + 20;
            memcpy(&rlp_data[1], info->tx_from, 20);
            if (info->nonce <= 0x7f)
                rlp_data[21] = (uint8_t) info->nonce;
            else {
                for (int i = 64 - 8; i >= 0; i -= 8) {
                    uint8_t b = (uint8_t) (info->nonce >> i);
                    if (b || n)
                        rlp_data[22 + n++] = b;
                }
                rlp_data[21] = 0x80 + n;
            }
            n += 22;
            if (sha3_Init(&ctx, 256))
                debug("sha3_Init failed\n");
            if (sha3_SetFlags(&ctx, SHA3_FLAGS_KECCAK) != SHA3_FLAGS_KECCAK)
                debug("sha3_SetFlags failed\n");
            sha3_Update(&ctx, rlp_data, n);
            memcpy(address, &((const uint8_t *) sha3_Finalize(&ctx))[12], 20);
        } break;
    }

    // tx_root
    hash_combine(&info->tx_hash, &root, &scratch[0]);

    // transaction_root
    /*  3 */ scratch[0][0] = *tx_selector; memset(&scratch[0][1], 0, 31);
    /*  1 */ hash_combine(&root, &info->tx_hash, &scratch[0]);

    // transactions_root
    for (int i = 0; i < TX_DEPTH; i++) {
        if (*tx_index & ((uint32_t) 1 << i))
            hash_combine(&root, tx_branch, &root);
        else
            hash_combine(&root, &root, tx_branch);
        tx_branch++;
    }
    hash_combine(&root, &root, tx_branch);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;

    return 0;
}

////////////////////////////////////////////////////////////////////////////////

#define STR(x) #x
#define QUOTE(x) STR(x)
__asm__ (
    ".section .rodata\n"
    ".global transactions_root\n"
    "transactions_root:\n"
    ".incbin \"proofs/transactions_root.bin\"\n"
    ".global proof\n"
    "proof:\n"
    ".incbin \"proofs/" QUOTE(PROOF_TYPE) "_" QUOTE(PROOF_INDEX) ".bin\"\n"
    ".global num_proof_bytes\n"
    ".set num_proof_bytes, . - proof\n"
    ".section .text\n"
);
extern const uint8_t transactions_root[];
extern const uint8_t proof[];
extern const uint8_t num_proof_bytes[];

const ExecutionConfig cfg = {
    .chain_id = {
        0x39, 0x05
    }
};

typedef enum {
    NIL,
    TRANSACTION,
    AMOUNT,
    SENDER,
    INFO
} proof_type;

void main(void)
{
    k_msleep(1000);

    printk("Union      %s_%s (%zu bytes)\n",
        QUOTE(PROOF_TYPE), QUOTE(PROOF_INDEX), (size_t) num_proof_bytes);

    timing_init();
    timing_start();
    timing_t start_time, end_time;
    switch (PROOF_TYPE) {
        case NIL: {
        } break;
        case TRANSACTION: {
            const Root *expected_tx_hash = (const Root *) &proof[0];
            start_time = timing_counter_get();
            if (verify_transaction_proof(
                proof, (size_t) num_proof_bytes,
                &cfg, (const Root *) transactions_root,
                expected_tx_hash))
            {
                printk("ERROR\n");
                break;
            }
            end_time = timing_counter_get();
            printk("tx_index = %u\n", proof[64]);
        } break;
        case AMOUNT: {
            const ExecutionAddress expected_tx_to = {
                0xd8, 0xda, 0x6b, 0xf2, 0x69, 0x64, 0xaf, 0x9d, 0x7e, 0xed,
                0x9e, 0x03, 0xe5, 0x34, 0x15, 0xd3, 0x7a, 0xa9, 0x60, 0x45,
            };
            const Bytes32 expected_tx_value_min = {
                0x00, 0xca, 0x9a, 0x3b
            };
            start_time = timing_counter_get();
            if (verify_amount_proof(
                proof, (size_t) num_proof_bytes,
                &cfg, (const Root *) transactions_root,
                &expected_tx_to, &expected_tx_value_min))
            {
                printk("ERROR\n");
                break;
            }
            end_time = timing_counter_get();
            printk("OK\n");
        } break;
        case SENDER: {
            const ExecutionAddress expected_tx_to = {
                0xd8, 0xda, 0x6b, 0xf2, 0x69, 0x64, 0xaf, 0x9d, 0x7e, 0xed,
                0x9e, 0x03, 0xe5, 0x34, 0x15, 0xd3, 0x7a, 0xa9, 0x60, 0x45,
            };
            const Bytes32 expected_tx_value_min = {
                0x00, 0xca, 0x9a, 0x3b
            };
            ExecutionAddress tx_from;
            start_time = timing_counter_get();
            if (verify_sender_proof(
                proof, (size_t) num_proof_bytes,
                &cfg, (const Root *) transactions_root,
                &expected_tx_to, &expected_tx_value_min,
                &tx_from))
            {
                printk("ERROR\n");
                break;
            }
            end_time = timing_counter_get();
            printk("tx_from = 0x");
            for (size_t i = 0; i < sizeof tx_from; i++)
                printk("%02x", tx_from[i]);
            printk("\n");
        } break;
        case INFO: {
            TransactionInfo info;
            start_time = timing_counter_get();
            if (verify_info_proof(
                proof, (size_t) num_proof_bytes,
                &cfg, (const Root *) transactions_root,
                &info))
            {
                printk("ERROR\n");
                break;
            }
            end_time = timing_counter_get();
            printk("info = {\n");
            printk("  tx_index = %lu\n", (unsigned long) info.tx_index);
            printk("  tx_hash = 0x");
            for (size_t i = 0; i < sizeof info.tx_hash; i++)
                printk("%02x", info.tx_hash[i]);
            printk("\n");
            printk("  tx_from = 0x");
            for (size_t i = 0; i < sizeof info.tx_from; i++)
                printk("%02x", info.tx_from[i]);
            printk("\n");
            printk("  nonce = %llu\n", (unsigned long long) info.nonce);
            printk("  tx_to = {\n");
            printk("    destination_type = %u\n", info.tx_to.destination_type);
            printk("    address = 0x");
            for (size_t i = 0; i < sizeof info.tx_to.address; i++)
                printk("%02x", info.tx_to.address[i]);
            printk("\n");
            printk("  }\n");
            printk("  tx_value = 0x");
            for (int i = sizeof info.tx_value - 1; i >= 0; i--)
                printk("%02x", info.tx_value[i]);
            printk("\n");
            printk("  limits = {\n");
            printk("    max_priority_fee_per_gas = 0x");
            for (int i = sizeof (Bytes32) - 1; i >= 0; i--)
                printk("%02x", info.limits.max_priority_fee_per_gas[i]);
            printk("\n");
            printk("    max_fee_per_gas = 0x");
            for (int i = sizeof (Bytes32) - 1; i >= 0; i--)
                printk("%02x", info.limits.max_fee_per_gas[i]);
            printk("\n");
            printk("    gas = %llu\n", (unsigned long long) info.limits.gas);
            printk("  }\n");
            printk("}\n");
        } break;
    }
    uint64_t total_cycles = timing_cycles_get(&start_time, &end_time);
    uint64_t total_ns = timing_cycles_to_ns(total_cycles);
    printk("cycles = %llu (%llu.%06llu ms)\n",
        (unsigned long long) total_cycles,
        (unsigned long long) (total_ns / 1000000),
        (unsigned long long) (total_ns % 1000000));
    timing_stop();
}
