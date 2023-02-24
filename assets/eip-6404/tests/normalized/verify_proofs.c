// Only one proof is verified at a time - create with `create_proofs.py`

// TRANSACTION, AMOUNT, SENDER, INFO
#define PROOF_TYPE INFO
// 0, 1, 2, 3, 4
#define PROOF_INDEX 4

/*******************************************************************************

prj.conf:
CONFIG_NRF_OBERON=y
CONFIG_TIMING_FUNCTIONS=y

CMakeLists.txt:
target_link_libraries(app PRIVATE nrfxlib_crypto)

*******************************************************************************/

#include <stdint.h>
#include <string.h>

#include <zephyr/kernel.h>
#include <zephyr/timing/timing.h>

#include <ocrypto_sha256.h>

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
    {0}
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
    const ExecutionConfig *cfg,
    const Root *transactions_root,
    const Root *expected_tx_hash)
{
    Root root;

    // payload_root
    const Root *payload_root = proof;
    if (num_proof_bytes < sizeof *payload_root) return 1;
    if (memcmp(payload_root, expected_tx_hash, sizeof *payload_root)) return 1;
    consume(sizeof *payload_root);

    // tx_hash
    const Root *tx_hash = proof;
    if (num_proof_bytes < sizeof *tx_hash) return 1;
    consume(sizeof *tx_hash);

    // transaction_root
    hash_combine(&root, payload_root, tx_hash);

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
    hash_combine(&root, &root, &cfg->chain_id);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    if (num_proof_bytes) return 1;
    return 0;
}

__attribute__((warn_unused_result))
static int verify_amount_proof(
    const void *proof,
    size_t num_proof_bytes,
    const ExecutionConfig *cfg,
    const Root *transactions_root,
    const ExecutionAddress *expected_tx_to,
    const Bytes32 *expected_tx_value_min)
{
    Root root, scratch[2];

    // tx_from
    const ExecutionAddress *tx_from = proof;
    if (num_proof_bytes < sizeof *tx_from) return 1;
    consume(sizeof *tx_from);

    // nonce
    const uint64_t *nonce = proof;
    if (num_proof_bytes < sizeof *nonce) return 1;
    consume(sizeof *nonce);

    // tx_to.destination_type
    const uint8_t *destination_type = proof;
    if (num_proof_bytes < sizeof *destination_type) return 1;
    if (*destination_type != DESTINATION_TYPE_REGULAR) return 1;
    consume(sizeof *destination_type);

    // tx_to.address
    const ExecutionAddress *addr = proof;
    if (num_proof_bytes < sizeof *addr) return 1;
    if (memcmp(addr, expected_tx_to, sizeof *addr)) return 1;
    consume(sizeof *addr);

    // tx_value
    const Bytes32 *tx_value = proof;
    if (num_proof_bytes < sizeof *tx_value) return 1;
    for (int i = sizeof *tx_value - 1; i >= 0; i--) {
        if ((*tx_value)[i] > (*expected_tx_value_min)[i]) break;
        if ((*tx_value)[i] < (*expected_tx_value_min)[i]) return 1;
    }
    consume(sizeof *tx_value);

    // multi_branch
    const Root *multi_branch = proof;
    if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
    consume(2 * sizeof *multi_branch);

    // payload_root
    /* 16 */ memcpy(&root[0], tx_from, 20); memset(&root[20], 0, 12);
    /* 17 */ memcpy(&scratch[0][0], nonce, 8); memset(&scratch[0][8], 0, 24);
    /*  8 */ hash_combine(&root, &root, &scratch[0]);
    /* 36 */ scratch[0][0] = DESTINATION_TYPE_REGULAR;
    /*    */ memset(&scratch[0][1], 0, 31);
    /* 37 */ memcpy(&scratch[1][0], addr, 20); memset(&scratch[1][20], 0, 12);
    /* 18 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
    /*  9 */ hash_combine(&scratch[0], &scratch[0], tx_value);
    /*  4 */ hash_combine(&root, &root, &scratch[0]);
    /*  2 */ hash_combine(&root, &root, &multi_branch[0]);
    /*  1 */ hash_combine(&root, &root, &multi_branch[1]);

    // tx_hash
    const Root *tx_hash = proof;
    if (num_proof_bytes < sizeof *tx_hash) return 1;
    consume(sizeof *tx_hash);

    // transaction_root
    hash_combine(&root, &root, tx_hash);

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
    hash_combine(&root, &root, &cfg->chain_id);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    if (num_proof_bytes) return 1;
    return 0;
}

__attribute__((warn_unused_result))
static int verify_sender_proof(
    const void *proof,
    size_t num_proof_bytes,
    const ExecutionConfig *cfg,
    const Root *transactions_root,
    const ExecutionAddress *expected_tx_to,
    const Bytes32 *expected_tx_value_min,
    ExecutionAddress *tx_from)
{
    Root root, scratch[2];

    // tx_from
    const ExecutionAddress *tx_from_ = proof;
    if (num_proof_bytes < sizeof *tx_from_) return 1;
    memcpy(tx_from, tx_from_, sizeof *tx_from_);
    consume(sizeof *tx_from_);

    // nonce
    const uint64_t *nonce = proof;
    if (num_proof_bytes < sizeof *nonce) return 1;
    consume(sizeof *nonce);

    // tx_to.destination_type
    const uint8_t *destination_type = proof;
    if (num_proof_bytes < sizeof *destination_type) return 1;
    if (*destination_type != DESTINATION_TYPE_REGULAR) return 1;
    consume(sizeof *destination_type);

    // tx_to.address
    const ExecutionAddress *addr = proof;
    if (num_proof_bytes < sizeof *addr) return 1;
    if (memcmp(addr, expected_tx_to, sizeof *addr)) return 1;
    consume(sizeof *addr);

    // tx_value
    const Bytes32 *tx_value = proof;
    if (num_proof_bytes < sizeof *tx_value) return 1;
    for (int i = sizeof *tx_value - 1; i >= 0; i--) {
        if ((*tx_value)[i] > (*expected_tx_value_min)[i]) break;
        if ((*tx_value)[i] < (*expected_tx_value_min)[i]) return 1;
    }
    consume(sizeof *tx_value);

    // multi_branch
    const Root *multi_branch = proof;
    if (num_proof_bytes < 2 * sizeof *multi_branch) return 1;
    consume(2 * sizeof *multi_branch);

    // payload_root
    /* 16 */ memcpy(&root[0], tx_from, 20); memset(&root[20], 0, 12);
    /* 17 */ memcpy(&scratch[0][0], nonce, 8); memset(&scratch[0][8], 0, 24);
    /*  8 */ hash_combine(&root, &root, &scratch[0]);
    /* 36 */ scratch[0][0] = DESTINATION_TYPE_REGULAR;
    /*    */ memset(&scratch[0][1], 0, 31);
    /* 37 */ memcpy(&scratch[1][0], addr, 20); memset(&scratch[1][20], 0, 12);
    /* 18 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
    /*  9 */ hash_combine(&scratch[0], &scratch[0], tx_value);
    /*  4 */ hash_combine(&root, &root, &scratch[0]);
    /*  2 */ hash_combine(&root, &root, &multi_branch[0]);
    /*  1 */ hash_combine(&root, &root, &multi_branch[1]);

    // tx_hash
    const Root *tx_hash = proof;
    if (num_proof_bytes < sizeof *tx_hash) return 1;
    consume(sizeof *tx_hash);

    // transaction_root
    hash_combine(&root, &root, tx_hash);

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
    hash_combine(&root, &root, &cfg->chain_id);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    if (num_proof_bytes) return 1;
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

    Root root, scratch[2];

    // tx_from
    const ExecutionAddress *tx_from = proof;
    if (num_proof_bytes < sizeof *tx_from) return 1;
    memcpy(info->tx_from, tx_from, sizeof *tx_from);
    consume(sizeof *tx_from);

    // nonce
    const uint64_t *nonce = proof;
    if (num_proof_bytes < sizeof *nonce) return 1;
    info->nonce = *nonce;
    consume(sizeof *nonce);

    // tx_to.destination_type
    const uint8_t *destination_type = proof;
    if (num_proof_bytes < sizeof *destination_type) return 1;
    if (*destination_type > 1) return 1;
    info->tx_to.destination_type = *destination_type;
    consume(sizeof *destination_type);

    // tx_to.address
    const ExecutionAddress *addr = proof;
    if (num_proof_bytes < sizeof *addr) return 1;
    memcpy(info->tx_to.address, addr, sizeof *addr);
    consume(sizeof *addr);

    // tx_value
    const Bytes32 *tx_value = proof;
    if (num_proof_bytes < sizeof *tx_value) return 1;
    memcpy(info->tx_value, tx_value, sizeof *tx_value);
    consume(sizeof *tx_value);

    // limits.max_priority_fee_per_gas
    const Bytes32 *max_prio = proof;
    if (num_proof_bytes < sizeof *max_prio) return 1;
    memcpy(info->limits.max_priority_fee_per_gas, max_prio, sizeof *max_prio);
    consume(sizeof *max_prio);

    // limits.max_fee_per_gas
    const Bytes32 *max_fee = proof;
    if (num_proof_bytes < sizeof *max_fee) return 1;
    memcpy(info->limits.max_fee_per_gas, max_fee, sizeof *max_fee);
    consume(sizeof *max_fee);

    // limits.gas
    const uint64_t *gas = proof;
    if (num_proof_bytes < sizeof *gas) return 1;
    info->limits.gas = *gas;
    consume(sizeof *gas);

    // multi_branch
    const Root *multi_branch = proof;
    if (num_proof_bytes < 3 * sizeof *multi_branch) return 1;
    consume(3 * sizeof *multi_branch);

    // payload_root
    /* 16 */ memcpy(&root[0], tx_from, 20); memset(&root[20], 0, 12);
    /* 17 */ memcpy(&scratch[0][0], nonce, 8); memset(&scratch[0][8], 0, 24);
    /*  8 */ hash_combine(&root, &root, &scratch[0]);
    /* 36 */ scratch[0][0] = *destination_type;
    /*    */ memset(&scratch[0][1], 0, 31);
    /* 37 */ memcpy(&scratch[1][0], addr, 20); memset(&scratch[1][20], 0, 12);
    /* 18 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
    /*  9 */ hash_combine(&scratch[0], &scratch[0], tx_value);
    /*  4 */ hash_combine(&root, &root, &scratch[0]);
    /* 42 */ hash_combine(&scratch[0], max_prio, max_fee);
    /* 86 */ memcpy(&scratch[1][0], gas, 8); memset(&scratch[1][8], 0, 24);
    /* 43 */ hash_combine(&scratch[1], &scratch[1], &zero_hash[0]);
    /* 21 */ hash_combine(&scratch[0], &scratch[0], &scratch[1]);
    /* 10 */ hash_combine(&scratch[0], &multi_branch[0], &scratch[0]);
    /*  5 */ hash_combine(&scratch[0], &scratch[0], &multi_branch[1]);
    /*  2 */ hash_combine(&root, &root, &scratch[0]);
    /*  1 */ hash_combine(&root, &root, &multi_branch[2]);

    // tx_hash
    const Root *tx_hash = proof;
    if (num_proof_bytes < sizeof *tx_hash) return 1;
    memcpy(info->tx_hash, tx_hash, sizeof *tx_hash);
    consume(sizeof *tx_hash);

    // transaction_root
    hash_combine(&root, &root, &info->tx_hash);

    // tx_index
    const uint32_t *tx_index = proof;
    if (num_proof_bytes < sizeof *tx_index) return 1;
    if (*tx_index >= MAX_TRANSACTIONS_PER_PAYLOAD) return 1;
    info->tx_index = *tx_index;
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
    hash_combine(&root, &root, &cfg->chain_id);
    if (memcmp(&root, transactions_root, sizeof root)) return 1;
    consume((1 + TX_DEPTH) * sizeof *tx_branch);

    if (num_proof_bytes) return 1;
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

    printk("Normalized %s_%s (%zu bytes)\n",
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
