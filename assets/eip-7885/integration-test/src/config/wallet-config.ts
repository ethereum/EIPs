import { config } from 'dotenv';
import { createWalletClient, createPublicClient, http, type Hex, defineChain, type WalletClient, type PublicClient } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

// Load environment variables
config();

// Get configuration from environment
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const RPC_URL = process.env.RPC_URL || 'http://34.29.49.47:8545';

if (!PRIVATE_KEY) {
  throw new Error(
    'PRIVATE_KEY environment variable is required for transaction tests'
  );
}

// Ensure private key has 0x prefix
const formattedPrivateKey = PRIVATE_KEY.startsWith('0x')
  ? (PRIVATE_KEY as Hex)
  : (`0x${PRIVATE_KEY}` as Hex);

// Define custom chain for NTT precompile testing
export const nttTestChain = defineChain({
  id: process.env.CHAIN_ID ? Number(process.env.CHAIN_ID) : 788484,
  name: 'NTT Precompile Test Network',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: [RPC_URL],
    },
  },
});

// Create account from private key
export const privateKeyAccount = privateKeyToAccount(formattedPrivateKey);

// Create wallet client for sending transactions
export const walletClient: WalletClient = createWalletClient({
  account: privateKeyAccount,
  chain: nttTestChain,
  transport: http(RPC_URL, {
    timeout: 30000,
    retryCount: 3,
    retryDelay: 1000,
  }),
});

// Create public client for reading transaction results
export const txPublicClient: PublicClient = createPublicClient({
  chain: nttTestChain,
  transport: http(RPC_URL, {
    timeout: 30000,
    retryCount: 3,
    retryDelay: 1000,
  }),
});

export const WALLET_CONFIG = {
  rpcUrl: RPC_URL,
  address: privateKeyAccount.address,
  hasPrivateKey: !!PRIVATE_KEY,
  chain: nttTestChain,
} as const;
