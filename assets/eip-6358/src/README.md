# Example implementation of EIP-6358

## Prerequisites
- node >= v18.12.1
- npm >= 8.19.2
- npx >= 8.19.2

## Installation
```
npm install
```

## Compilation
```
touch .secret
npx truffle compile
```

## Unit test
### Launch local testnet
```
npx ganache -s 0
```

### Test
Open another terminate

```
npm truffle test
```