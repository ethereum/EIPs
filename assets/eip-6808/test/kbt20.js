const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time,
} = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

const FirstKBT = artifacts.require("MyFirstKBT");

contract('FirstKBT', function (accounts) {

  let instance;

  before(async () => {
    instance = await FirstKBT.new();
  });

  const [deploymentAccount, accountHolder, secondAccountHolder, firstAccount, secondAccount,
    thirdAccount, fourthAccount, spenderAccount] = accounts;

  it("1. deploy: should check the totalSupply to be 100_000_000", async function () {
    balance = await instance.totalSupply();
    assert.equal(balance.valueOf(), 100_000_000 * 10 ** 18, "100_000_000 * 10 ** 18 wasn't in the first account");
  });

  it("2. deploy: owner should have full amount", async function () {
    balance = await instance.balanceOf(deploymentAccount);
    assert.equal(balance.valueOf(), 100_000_000 * 10 ** 18, "100_000_000 * 10 ** 18 wasn't in the first account");
  });

  it("3. deploy: accountHolder should have 0 amount", async function () {
    balance = await instance.balanceOf(accountHolder);
    assert.equal(balance.valueOf(), 0, "accountHolder has more than 0");
  });

  it("4. addBindings : CANNOT add secure wallets if ballance is 0", async function () {
    await expectRevert(
      instance.addBindings(firstAccount, secondAccount, { from: accountHolder }),
      "[200] KBT20: Wallet is not a holder"
    );
    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "First account is not empty");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "Second account is not empty");
  });

  it("5. transfer: CAN 10 tokens be transferred to accountHolder", async function () {
    value = 10;
    emitted = await instance.transfer(accountHolder, value, { from: deploymentAccount });
    printGasUsed(emitted, 'transfer');
    balance = await instance.balanceOf(accountHolder);
    assert.equal(balance.toNumber(), value, "transfer failed");
  });

  it("6. addBindings : CAN add secure wallets | EVENT: AccountSecured was emitted", async function () {
    emitted = await instance.addBindings(firstAccount, secondAccount, { from: accountHolder });
    printGasUsed(emitted, 'addBindings');
    balance = await instance.balanceOf(accountHolder);
    expectEvent(emitted, "AccountSecured", { _account: accountHolder, _amount: balance });
    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, firstAccount, "First account was not set as a secure wallet");
    assert.equal(accountHolderBindings.secondWallet, secondAccount, "Second account was not set as a secure wallet");
  });

  it("7. addBindings : CANNOT add secure wallets a second time", async function () {
    expectRevert(
      instance.addBindings(thirdAccount, fourthAccount, { from: accountHolder }),
      "[201] KBT20: Key wallets are already filled"
    );
  });

  it("8. addBindings : CANNOT add secure wallets that are already secure wallets to another account", async function () {
    value = 10;
    await instance.transfer(secondAccountHolder, value, { from: deploymentAccount });
    expectRevert(
      instance.addBindings(firstAccount, fourthAccount, { from: secondAccountHolder }),
      "[203] KBT20: Key wallet 1 is already registered"
    );
    expectRevert(
      instance.addBindings(thirdAccount, secondAccount, { from: secondAccountHolder }),
      "[204] KBT20: Key wallet 2 is already registered"
    );
  });

  it("9. addBindings : accountHolder is a secure wallet", async function () {
    result = await instance.isSecureWallet(accountHolder);
    assert.equal(result, true, "accountHolder is not a secure wallet");
  });

  it("10. addBindings : firstAccount is NOT a secure wallet", async function () {
    result = await instance.isSecureWallet(firstAccount);
    assert.equal(result, false, "firstAccount is a secure wallet");
  });

  it("11. transfer: accountHolder CANNOT transfer 3 tokens before allowTransfer", async function () {
    value = 3;
    await expectRevert(instance.transfer(secondAccountHolder, value, { from: accountHolder }), "[100] KBT20: Sender is a secure wallet and doesn't have approval for the amount");
  });

  it("12. allowTransfer: firstAccount CAN Unlock 10 tokens | EVENT: AccountEnabledTransfer", async function () {
    value = 10;
    emitted = await instance.allowTransfer(value, 0, constants.ZERO_ADDRESS, false, { from: firstAccount });
    printGasUsed(emitted, 'allowTransfer');
    expectEvent(emitted, "AccountEnabledTransfer", { _account: accountHolder, _amount: new BN(value), _time: new BN(0), _to: constants.ZERO_ADDRESS, _allFunds: false });
    await instance.getTransferableFunds(accountHolder).then(function (result) {
      assert.equal(result.amount, value, "accountHolder does not have " + value + " tokens unlocked");
    });
    expectRevert(instance.allowTransfer(11, 0, constants.ZERO_ADDRESS, false, { from: firstAccount }), "[501] KBT20: Not enough tokens");
  });

  it("13. transfer: accountHolder CAN transfer 3 tokens to secondAccountHolder", async function () {
    value = 3;
    initialBalance = (await instance.balanceOf(secondAccountHolder)).toNumber();
    await instance.transfer(secondAccountHolder, value, { from: accountHolder });
    balance = await instance.balanceOf(secondAccountHolder);
    assert.equal(balance.toNumber(), initialBalance + value, "transfer failed");
  });

  it("14. approve: account holder CAN'T approve (without AllowApproval)", async function () {
    token = instance;

    expectRevert(instance.approve(spenderAccount, 10, { from: accountHolder }), "[101] KBT20: Spending of funds is not authorized.");
  });

  it("15. allowApproval: firstAccount CAN allowApproval for a time and numberOfTransfers | EVENT: AccountEnabledApproval ", async function () {
    tempTime = 100;
    numberOfTransfers = 2;

    emitted = await instance.allowApproval(tempTime, numberOfTransfers, { from: firstAccount });
    printGasUsed(emitted, 'allowApproval');
    forTime = new BN(await time.latest());
    forTime = forTime.add(new BN(tempTime));
    forNumberOfTokens = new BN(numberOfTransfers);
    expectEvent(emitted, "AccountEnabledApproval", { _account: accountHolder, _time: forTime, _numberOfTransfers: forNumberOfTokens });
    await instance.getApprovalConditions(accountHolder).then(function (result) {
      assert.isAbove(Number(result.time), 0, "accountHolder does not have allowApproval");
      assert.equal(Number(result.numberOfTransfers), numberOfTransfers, "accountHolder does not have allowApproval");
    });
  });

  it("16. transferFrom: spenderAccount CANNOT transferFrom accountHolder without Approval", async function () {
    value = 3;
    expectRevert(instance.transferFrom(accountHolder, secondAccountHolder, value, { from: spenderAccount }), "ERC20: insufficient allowance");
  });

  it("17. approve: account holder CAN approve spenderAccount", async function () {
    value = 3;
    emitted = await instance.approve(spenderAccount, value, { from: accountHolder });
    printGasUsed(emitted, 'approve');
    allowance = await instance.allowance(accountHolder, spenderAccount);
    assert.equal(value, allowance.toNumber(), "Approval didn't went as planned.");

    tempNumberOfTransfersAllowed = 2;
    noOfTransfersAllowed = await instance.getNumberOfTransfersAllowed(accountHolder, spenderAccount);
    assert.equal(tempNumberOfTransfersAllowed, noOfTransfersAllowed, "Approval didn't went as planned.");
  });

  it("18. transferFrom: spenderAccount CAN transferFrom accountHolder but no more than the numberOfTransfers", async function () {
    value = 1;
    emitted = await instance.transferFrom(accountHolder, secondAccountHolder, value, { from: spenderAccount });
    emitted = await instance.transferFrom(accountHolder, secondAccountHolder, value, { from: spenderAccount });
    printGasUsed(emitted, 'transferFrom');

    expectRevert(instance.transferFrom(accountHolder, secondAccountHolder, value, { from: spenderAccount }), "ERC20: insufficient allowance");
  });

  it("19. transferFrom: spenderAccount CAN transferFrom accountHolder as much as they want when numberOfTransfers is 0", async function () {
    value = 10;
    await instance.transfer(accountHolder, value, { from: deploymentAccount });
    await instance.allowApproval(100, 0, { from: firstAccount });
    await instance.approve(spenderAccount, value, { from: accountHolder });

    while (value > 0) {
      await instance.transferFrom(accountHolder, secondAccountHolder, 1, { from: spenderAccount });

      value--;
    }
  });

  it("20. transfer: when accountHolder transfers ALL funds, accountHolder becomes unsecure", async function () {
    value = 5;
    emitted = await instance.allowTransfer(value, 0, constants.ZERO_ADDRESS, false, { from: firstAccount });
    printGasUsed(emitted, 'allowTransfer');
    await instance.transfer(secondAccountHolder, value, { from: accountHolder });

    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
  });

  it("21. safeFallback: accountHolder becomes unsecure, other 2FA wallet has at least accountHolder funds | EVENT: SafeFallbackActivated", async function () {
    value = 100;
    await instance.transfer(accountHolder, value, { from: deploymentAccount });
    expectRevert(instance.safeFallback({ from: firstAccount }), "[400] KBT20: Key authorization failure");
    await instance.addBindings(firstAccount, secondAccount, { from: accountHolder });

    emitted = await instance.safeFallback({ from: firstAccount });
    printGasUsed(emitted, 'safeFallback');
    expectEvent(emitted, "SafeFallbackActivated", { _account: accountHolder });

    secondAccountBalance = (await instance.balanceOf(secondAccount)).toNumber();
    assert.isAtLeast(secondAccountBalance, value, "second account doesn't have the full amount from account holder");

    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
  });

  it("22. resetBindings: accountHolder becomes unsecure | EVENT: AccountResetBinding", async function () {
    value = 100;

    await instance.transfer(accountHolder, value, { from: deploymentAccount });
    await instance.addBindings(firstAccount, secondAccount, { from: accountHolder });

    emitted = await instance.resetBindings({ from: firstAccount });
    printGasUsed(emitted, 'resetBindings');
    expectEvent(emitted, "AccountResetBinding", { _account: accountHolder });

    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
  });
});

function printGasUsed(event, methodName) {
  const gasUsed = event.receipt.gasUsed;
  console.log(`GasUsed: ${gasUsed.toLocaleString()} for '${methodName}'`);
}
