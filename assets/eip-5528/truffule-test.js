const EscrowContractAccount = artifacts.require('./EscrowContractAccount')
const ERC20Mockup = artifacts.require('./ERC20Mockup')

const util = require('util')
contract('ERCEscrowMockup', accounts => {
    const [userCreator, userSeller, userBuyer01, userBuyer02, ...others] = accounts

    let contracts

    const BNConst = {
        totalFund: 100,
        user1: 10,
        user2: 33,
        zero: 0,
        DigOne: 1,
        DigTwo: 2,
    }

    before(async () => {
        const seller = await ERC20Mockup.new(userCreator, 10000)
        await seller.transfer(userSeller, 1000, {from: userCreator})

        const buyer = await ERC20Mockup.new(userCreator, 10000)
        await buyer.transfer(userBuyer01, 1000, {from: userCreator})
        await buyer.transfer(userBuyer02, 1000, {from: userCreator})

        const escrow = await EscrowContractAccount.new(BNConst.totalFund, seller.address, buyer.address, {from: userSeller})

        contracts = {
            escrow,
            seller,
            buyer,
        }
        for (const key in BNConst) {
            const v = BNConst[key]
            BNConst[key] = {
                origin: v,
                bn: await escrow.helper_bigInt256(v),
            }
        }
        //console.log('-check point-1-', util.inspect(contracts, false, null, true))
    })

    it('escrow start', async () => {
        const result = await contracts.seller.escrowFund(contracts.escrow.address, BNConst.totalFund.origin, {
            from: userSeller,
        })
        const [buyer, seller] = await contracts.escrow.escrowBalanceOf(userSeller)
        const state = await contracts.escrow.escrowStatus()
        //console.log('---check00000', state)
        //console.log('-check point-1-', util.inspect(result, false, null, true))
        //console.log('--balance---', {buyer, seller, bigNumberPrefix})
        assert(buyer.eq(BNConst.zero.bn))
        assert(seller.eq(BNConst.totalFund.bn))
    })

    it('purchase first buyer', async () => {
        await contracts.buyer.escrowFund(contracts.escrow.address, BNConst.user1.origin, {from: userBuyer01})
        const [buyer, seller] = await contracts.escrow.escrowBalanceOf(userBuyer01)
    })
    it('first buyer refund and purchase', async () => {
        await contracts.buyer.escrowRefund(contracts.escrow.address, BNConst.user1.origin, {from: userBuyer01})
        let result = await contracts.escrow.helper_numberOfBuyers()
        //console.log('-----1----', result)
        assert(result.eq(BNConst.zero.bn))

        await contracts.buyer.escrowFund(contracts.escrow.address, BNConst.user1.origin, {from: userBuyer01})
        result = await contracts.escrow.helper_numberOfBuyers()
        //console.log('-----1----', result)
        assert(result.eq(BNConst.DigOne.bn))
    })
    it('send buyer purchase can finialize fund', async () => {
        await contracts.buyer.escrowFund(contracts.escrow.address, BNConst.user2.origin, {from: userBuyer02})
        let result = await contracts.escrow.helper_numberOfBuyers()
        //console.log('-----1----', result)
        assert(result.eq(BNConst.DigTwo.bn))
        result = await contracts.escrow.escrowStatus()
        //console.log('-----2----', result)
        assert(result === 'Success')
    })
    it('check balance of seller and buyer', async () => {
        const balance = {
            sellerToken: {
                issuer: await contracts.seller.balanceOf(userSeller),
                b01: await contracts.seller.balanceOf(userBuyer01),
                b02: await contracts.seller.balanceOf(userBuyer02),
            },
            buyerToken: {
                issuer: await contracts.buyer.balanceOf(userSeller),
                b01: await contracts.buyer.balanceOf(userBuyer01),
                b02: await contracts.buyer.balanceOf(userBuyer02),
            },
        }
        //console.log('-check point-1-', util.inspect(balance, false, null, true))
    })

    it('check balance after withdraw', async () => {
        await contracts.escrow.escrowWithdraw({from: userSeller})
        await contracts.escrow.escrowWithdraw({from: userBuyer01})
        await contracts.escrow.escrowWithdraw({from: userBuyer02})
        const balance = {
            sellerToken: {
                issuer: await contracts.seller.balanceOf(userSeller),
                b01: await contracts.seller.balanceOf(userBuyer01),
                b02: await contracts.seller.balanceOf(userBuyer02),
            },
            buyerToken: {
                issuer: await contracts.buyer.balanceOf(userSeller),
                b01: await contracts.buyer.balanceOf(userBuyer01),
                b02: await contracts.buyer.balanceOf(userBuyer02),
            },
        }
        //console.log('-check point-1-', util.inspect(balance, false, null, true))
    })
})
