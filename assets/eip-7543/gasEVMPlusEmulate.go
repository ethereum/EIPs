// THE BELOW CODE IS ADDED TO core/vm/gas_table.go

// emulate op for EVMPlus gas
// double estimate gas for actual run
// gas emulation cost
type GasOpFunc func(inputs []int256, gas *uint64)
func gasEVMPlusEmulate(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64, nStack int, op GasOpFunc) (uint64, error) {

	inputs := make([]int256, nStack)
	for i := 0; i < nStack; i++ {
		inputs[i] = stack.pop()
	}
	gas := uint64(0)
	op(inputs, &gas)
	for i := nStack - 1; 0 <= i ; i-- {
		stack.push(&inputs[i])
	}

	return 2*gas, nil // double to account for emulation plus actual compute
}
func gasEVMPlusDECADD(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 5
	op := func(inputs []int256, gas *uint64) {DecAdd(&inputs[0], &inputs[1], &inputs[2], &inputs[3], &inputs[4], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
func gasEVMPlusDECNEG(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 2
	op := func(inputs []int256, gas *uint64) {DecNeg(&inputs[0], &inputs[1], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
func gasEVMPlusDECMUL(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 5
	op := func(inputs []int256, gas *uint64) {DecMul(&inputs[0], &inputs[1], &inputs[2], &inputs[3], &inputs[4], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
func gasEVMPlusDECINV(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 3
	op := func(inputs []int256, gas *uint64) {DecInv(&inputs[0], &inputs[1], &inputs[2], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
func gasEVMPlusDECEXP(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 4
	op := func(inputs []int256, gas *uint64) {DecExp(&inputs[0], &inputs[1], &inputs[2], &inputs[3], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
func gasEVMPlusDECLN(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 4
	op := func(inputs []int256, gas *uint64) {DecLn(&inputs[0], &inputs[1], &inputs[2], &inputs[3], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
func gasEVMPlusDECSIN(evm *EVM, contract *Contract, stack *Stack, mem *Memory, memorySize uint64) (uint64, error) {
	nStack := 4
	op := func(inputs []int256, gas *uint64) {DecSin(&inputs[0], &inputs[1], &inputs[2], &inputs[3], gas)}
	return gasEVMPlusEmulate(evm, contract, stack, mem, memorySize, nStack, op)
}
