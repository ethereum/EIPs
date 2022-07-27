import {
    DebondERC3475Instance, ProgressCalculatorInstance
} from "../types/truffle-contracts";

const DebondBond = artifacts.require("DebondERC3475");
const ProgressCalculator = artifacts.require("ProgressCalculator");


interface Transaction {
    classId: number | BN | string;
    nonceId: number | BN | string;
    amount: number | BN | string;
}

interface Metadata {
    title: string;
    types: string;
    description: string;
}

interface Value {
    stringValue: string;
    uintValue: number | BN | string;
    addressValue: string;
    boolValue: boolean;
}

const defaultValue: Value = {
    stringValue: "",
    uintValue: 0,
    addressValue: "0x0000000000000000000000000000000000000000",
    boolValue: false
}

contract('Bond', async (accounts: string[]) => {

    let bondContract: DebondERC3475Instance
    let progressCalculatorContract: ProgressCalculatorInstance

    const DBIT_FIX_6MTH_CLASS_ID = 0;
    const [governance, bank, user1, user2, operator, spender, DBITAddress] = accounts;

    const now = parseInt(Date.now().toString().substring(-3));
    const classMetadatas: Metadata[] = [
        {title: "symbol", types: "string", description: "the collateral token's symbol"},
        {title: "token address", types: "address", description: "the collateral token's address"},
        {title: "interest rate type", types: "int", description: "the interest rate type"},
        {title: "period", types: "int", description: "the base period for the class"},
    ]

    const nonceMetadatas: Metadata[] = [
        {title: "issuance Date", types: "int", description: "the issuance date"},
        {title: "maturity Date", types: "int", description: "the maturity date"}
    ]

    it('Initialisation', async () => {
        bondContract = await DebondBond.deployed();
        progressCalculatorContract = await ProgressCalculator.deployed();

    })

    it('Should create set of metadatas for classes, only the Bank can do that action', async () => {
        let metadataIds: number[] = [];
        for (const metadata of classMetadatas) {
            const index = classMetadatas.indexOf(metadata);
            metadataIds.push(index)
        }
        await bondContract.createClassMetadataBatch(metadataIds, classMetadatas, {from: bank})
        const metadata = await bondContract.classMetadata(0);
        assert.isTrue(metadata.title == classMetadatas[0].title);
        assert.isTrue(metadata.types == classMetadatas[0].types);
        assert.isTrue(metadata.description == classMetadatas[0].description);
    })

    it('Should create a new class, only the Bank can do that action', async () => {
        const values: Value[] = [
            {...defaultValue, stringValue: "DBIT"},
            {...defaultValue, addressValue: DBITAddress},
            {...defaultValue, uintValue: 0},
            {...defaultValue, uintValue: 3600 * 24 * 180 }, // 6 months
        ]
        await bondContract.createClass(DBIT_FIX_6MTH_CLASS_ID, classMetadatas.map(metadata => classMetadatas.indexOf(metadata)), values, {from: bank});
        const classExists = await bondContract.classExists(DBIT_FIX_6MTH_CLASS_ID)
        const classTokenAddress = (await bondContract.classValues(DBIT_FIX_6MTH_CLASS_ID, 1)).addressValue
        assert.isTrue(classExists);
        assert.isTrue(classTokenAddress == DBITAddress);
    })

    it('Should create set of metadatas for a class nonces, only the Bank can do that action', async () => {
        let metadataIds: number[] = [];
        for (const metadata of nonceMetadatas) {
            const index = nonceMetadatas.indexOf(metadata);
            metadataIds.push(index)
        }
        await bondContract.createNonceMetadataBatch(DBIT_FIX_6MTH_CLASS_ID, metadataIds, nonceMetadatas, {from: bank})
        const metadata = await bondContract.nonceMetadata(DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(metadata.title == nonceMetadatas[0].title);
        assert.isTrue(metadata.types == nonceMetadatas[0].types);
        assert.isTrue(metadata.description == nonceMetadatas[0].description);
    })

    it('Should create a new nonce for a given class, only the Bank can do that action', async () => {
        const values: Value[] = [
            {...defaultValue, uintValue: now},
            {...defaultValue, uintValue: now }, // 6 months
        ]
        await bondContract.createNonce(DBIT_FIX_6MTH_CLASS_ID, 0, nonceMetadatas.map(metadata => nonceMetadatas.indexOf(metadata)), values, {from: bank});
        const nonceExists = await bondContract.nonceExists(DBIT_FIX_6MTH_CLASS_ID, 0)
        const nonceIssuanceDate = (await bondContract.nonceValues(DBIT_FIX_6MTH_CLASS_ID, 0, 0)).uintValue
        console.log(nonceIssuanceDate, now)
        assert.isTrue(nonceExists);
        assert.isTrue(nonceIssuanceDate == now);
    })

    it('Should update last nonce created, only the Bank can do that action', async () => {
        await bondContract.updateLastNonce(DBIT_FIX_6MTH_CLASS_ID, 0, now, {from: bank});
        const lastCreatedNonceDate = await bondContract.getLastNonceCreated(DBIT_FIX_6MTH_CLASS_ID);
        assert.isTrue(lastCreatedNonceDate["1"] == now);
    })

    it('Should Issue bonds to an account, only the Bank can do that action', async () => {
        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('5000')}
        ]
        await bondContract.issue(user1, transactions, {from: bank});
        const buyerBalance = await bondContract.balanceOf(user1, DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(web3.utils.toWei('5000') == buyerBalance.toString())

    })

    it('Should transfer bonds', async () => {
        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('1500')}
        ]
        await bondContract.transferFrom(user1, user2, transactions, {from: user1});
        const user1Balance = await bondContract.balanceOf(user1, DBIT_FIX_6MTH_CLASS_ID, 0);
        const user2Balance = await bondContract.balanceOf(user2, DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(web3.utils.toWei('3500') == user1Balance.toString())
        assert.isTrue(web3.utils.toWei('1500') == user2Balance.toString())
    })

    it('Should setApproval for an operator', async () => {
        await bondContract.setApprovalFor(operator, true,{from: user1});
        await bondContract.setApprovalFor(operator, true,{from: user2});
        const isApproved = await bondContract.isApprovedFor(user1, operator);
        assert.isTrue(isApproved)
    })

    it('Should be able for operator to transfer bonds from user to an other', async () => {
        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('1500')}
        ]
        await bondContract.transferFrom(user1, user2, transactions, {from: operator});
        const user1Balance = await bondContract.balanceOf(user1, DBIT_FIX_6MTH_CLASS_ID, 0);
        const user2Balance = await bondContract.balanceOf(user2, DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(web3.utils.toWei('2000') == user1Balance.toString())
        assert.isTrue(web3.utils.toWei('3000') == user2Balance.toString())
    })

    it('Should add allowance for a spender', async () => {
        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('2000')}
        ]
        await bondContract.approve(spender, transactions,{from: user1});
        await bondContract.approve(spender, transactions,{from: user2});
        const spenderAllowanceOnUser1 = await bondContract.allowance(user1, spender, DBIT_FIX_6MTH_CLASS_ID, 0);
        const spenderAllowanceOnUser2 = await bondContract.allowance(user2, spender, DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(spenderAllowanceOnUser1.toString() == web3.utils.toWei('2000'))
        assert.isTrue(spenderAllowanceOnUser2.toString() == web3.utils.toWei('2000'))
    })

    it('Should be able for spender to transfer allowance bonds from a user to an other', async () => {
        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('2000')}
        ]
        await bondContract.transferAllowanceFrom(user1, user2, transactions, {from: spender});
        const user1Balance = await bondContract.balanceOf(user1, DBIT_FIX_6MTH_CLASS_ID, 0);
        const user2Balance = await bondContract.balanceOf(user2, DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue('0' == user1Balance.toString())
        assert.isTrue(web3.utils.toWei('5000') == user2Balance.toString())
    })

    it('Should be able to burn bonds from user, only bank can do this action', async () => {

        // we need to set bank as operator for user
        await bondContract.setApprovalFor(bank, true,{from: user2});

        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('1000')}
        ]
        await bondContract.burn(user2, transactions, {from: bank});
        const user2Balance = await bondContract.balanceOf(user2, DBIT_FIX_6MTH_CLASS_ID, 0);
        const burnedSupply = await bondContract.burnedSupply(DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(web3.utils.toWei('4000') == user2Balance.toString())
        assert.isTrue(web3.utils.toWei('1000') == burnedSupply.toString())
    })

    it('Should be able to redeem bonds from user, only bank can do this action', async () => {

        const transactions: Transaction[] = [
            {classId: DBIT_FIX_6MTH_CLASS_ID, nonceId: 0, amount: web3.utils.toWei('1000')}
        ]
        // progressCalculator is bank
        await bondContract.setBankAddress(progressCalculatorContract.address);
        await progressCalculatorContract.redeem(user2, transactions);
        const user2Balance = await bondContract.balanceOf(user2, DBIT_FIX_6MTH_CLASS_ID, 0);
        const redeemedSupply = await bondContract.redeemedSupply(DBIT_FIX_6MTH_CLASS_ID, 0);
        assert.isTrue(web3.utils.toWei('3000') == user2Balance.toString())
        assert.isTrue(web3.utils.toWei('1000') == redeemedSupply.toString())
        await bondContract.setBankAddress(bank);

    })

    it('Should give all the nonces per class for a given address', async () => {
        async function getUser1AllToTransactions(event: string): Promise<Transaction[]> {
            return (await bondContract.getPastEvents(event,
                {
                    filter: {
                        _to: user1
                    },
                    fromBlock: 0
                }
            )).map(e => {
                return e.returnValues._transactions as Transaction[];
            }).flat();
        }
        const t = await Promise.all([
            getUser1AllToTransactions('Issue'),
            getUser1AllToTransactions('Transfer')
        ]).then((res: Awaited<Transaction[]>[]) => {
            return res.flat()
        })

        console.log(t);
    })
});
