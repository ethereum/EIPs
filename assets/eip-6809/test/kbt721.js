const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
  time,
} = require('@openzeppelin/test-helpers');
const { web3 } = require('@openzeppelin/test-helpers/src/setup');

const FirstKBT = artifacts.require("MyFirstKBT");

contract('FirstKBT', (accounts) => {

  let instance;

  before(async () => {
    instance = await FirstKBT.new();
  });

  const [deploymentAccount, accountHolder, secondAccountHolder, firstAccount, secondAccount,
    thirdAccount, fourthAccount, spenderAccount] = accounts;

  const tokenIds = [11, 22, 33, 34, 35];
  const secondTokenIds = [44, 55, 66];

  it('1. Check the MyFirstKBT after deployment', async () => {
    const name = await instance.name();
    assert.equal(name, name, 'Name should be "MyFirstKBT" after deployment');
  });

  it("2. accountHolder and secondAccountHolder should have 0 tokens", async function () {
    let balance = await instance.balanceOf(accountHolder);
    assert.equal(balance.toNumber(), 0, "accountHolder has more than 0");

    balance = await instance.balanceOf(secondAccountHolder);
    assert.equal(balance.toNumber(), 0, "secondAccountHolder has more than 0");
  });

  it("3. addBindings : CANNOT add secure wallets if balance is 0", async function () {
    await expectRevert(
      instance.addBindings(firstAccount, secondAccount, { from: accountHolder }),
      "[200] KBT721: Wallet is not a holder"
    );
    const accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "First account is not empty");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "Second account is not empty");
  });

  it("4. mint: Owner should be able to mint tokens for accountHolder", async function () {
    for (i = 0; i < tokenIds.length; i++) {
      let tokenId = tokenIds[i];
      const event = await instance.safeMint(accountHolder, tokenId, { from: deploymentAccount });
      printGasUsed(event, 'safeMint');

      let owner = await instance.ownerOf(tokenId);
      assert.equal(owner, accountHolder, "Owner should be able to mint.");

      const token = await instance.tokenOfOwnerByIndex(accountHolder, i);
      assert.equal(token.toNumber(), tokenId, "TokenId does not match");
    }

    const balance = await instance.balanceOf(accountHolder);
    assert.equal(balance.toNumber(), tokenIds.length, "accountHolder should have tokens");
  });

  it("5. transfer: CAN 1 token be transferred from accountHolder to secondAccountHolder", async function () {
    const tokenId = 11;
    const balanceAccountHolderOrig = await instance.balanceOf(accountHolder);
    const balanceSecondAccountHolderOrig = await instance.balanceOf(secondAccountHolder);

    const event = await instance.safeTransferFrom(accountHolder, secondAccountHolder, tokenId, { from: accountHolder });
    printGasUsed(event, 'safeTransferFrom');

    const balanceAccountHolder = await instance.balanceOf(accountHolder);
    assert.equal(balanceAccountHolder.toNumber(), balanceAccountHolderOrig.toNumber() - 1, "transfer failed: accountHolder balance is wrong");

    const balanceSecondAccountHolder = await instance.balanceOf(secondAccountHolder);
    assert.equal(balanceSecondAccountHolder.toNumber(), balanceSecondAccountHolderOrig.toNumber() + 1, "transfer failed: secondAccountHolder balance is wrong");

    const owner = await instance.ownerOf(tokenId);
    assert.equal(owner, secondAccountHolder, "transfer failed: new owner is not secondAccountHolder");
  });

  it("6. addBindings : CAN add secure wallets | EVENT: AccountSecured was emitted", async function () {
    emitted = await instance.addBindings(firstAccount, secondAccount, { from: accountHolder });
    printGasUsed(emitted, 'addBindings');
    balance = await instance.balanceOf(accountHolder);
    expectEvent(emitted, "AccountSecured", { _account: accountHolder, _noOfTokens: balance });

    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, firstAccount, "First account was not set as a secure wallet");
    assert.equal(accountHolderBindings.secondWallet, secondAccount, "Second account was not set as a secure wallet");
  });

  it("7. isSecureToken : Token 11 should not be secure, Token 22 should be secure", async function () {
    isSecure = await instance.isSecureToken(11);
    assert.isFalse(isSecure, "Token 11 is not a secure token");

    isSecure = await instance.isSecureToken(22);
    assert.isTrue(isSecure, "Token 22 is not a secure token");
  });

  it("8. addBindings : CANNOT add secure wallets a second time", async function () {
    expectRevert(
      instance.addBindings(thirdAccount, fourthAccount, { from: accountHolder }),
      "[201] KBT721: Key wallets are already filled"
    );
  });

  it("9. addBindings : CANNOT add secure wallets that are already secure wallets to another account", async function () {
    await mintTokensTmp(secondTokenIds, instance, secondAccountHolder, deploymentAccount);

    expectRevert(
      instance.addBindings(firstAccount, fourthAccount, { from: secondAccountHolder }),
      "[203] KBT721: Key wallet 1 is already registered"
    );
    expectRevert(
      instance.addBindings(thirdAccount, secondAccount, { from: secondAccountHolder }),
      "[204] KBT721: Key wallet 2 is already registered"
    );
  });

  it("10. addBindings : accountHolder is a secure wallet", function () {
    instance.isSecureWallet(accountHolder).then(function (result) {
      assert.equal(result, true, "accountHolder is not a secure wallet");
    });
  });

  it("11. addBindings : firstAccount is NOT a secure wallet", function () {
    instance.isSecureWallet(firstAccount).then(function (result) {
      assert.equal(result, false, "firstAccount is a secure wallet");
    });
  });

  it("12. transfer : accountHolder CANNOT transfer token 22 before allowTransfer", async function () {
    tokenId = 22;
    await expectRevert(instance.safeTransferFrom(accountHolder, secondAccountHolder, tokenId, { from: accountHolder }), "[100] KBT721: Owner is a secure wallet and doesn't have approval for the token");
  });

  it("13. allowTransfer : firstAccount CAN Unlock token 22 | EVENT: AccountEnabledTransfer", async function () {
    tokenId = 22;
    emitted = await instance.allowTransfer(tokenId, 0, constants.ZERO_ADDRESS, false, { from: firstAccount });
    printGasUsed(emitted, 'allowTransfer');
    expectEvent(emitted, "AccountEnabledTransfer", { _account: accountHolder, _tokenId: new BN(tokenId), _time: new BN(0), _to: constants.ZERO_ADDRESS, _anyToken: false });
    result = await instance.getTransferableFunds(accountHolder);
    assert.equal(result.tokenId, tokenId, "accountHolder does not have " + tokenId + " token unlocked");
    expectRevert(instance.allowTransfer(44, 0, constants.ZERO_ADDRESS, false, { from: firstAccount }), "[501] KBT721: Invalid tokenId.");
  });

  it("14. transfer : accountHolder CAN transfer token 22 to secondAccountHolder", async function () {
    tokenId = 22;
    initialBalance = (await instance.balanceOf(secondAccountHolder)).toNumber();

    await instance.safeTransferFrom(accountHolder, secondAccountHolder, tokenId, { from: accountHolder });

    balance = (await instance.balanceOf(secondAccountHolder)).toNumber();
    assert.equal(balance, initialBalance + 1, "transfer failed");
  });

  it("15. approve : account holder CAN'T approve (without Authorize Spending UNLOCKED)", async function () {
    tokenId = 34;
    expectRevert(instance.approve(spenderAccount, tokenId, { from: accountHolder }), "[101] KBT721: Spending of funds is not authorized.");
  });

  it("16. allowApproval : firstAccount CAN Authorize Spending | EVENT: AccountEnabledApproval ", async function () {
    tokenId = 34;
    numberOfTransfers = 1;

    emitted = await instance.allowApproval(tokenId, numberOfTransfers, { from: firstAccount });
    printGasUsed(emitted, 'allowApproval');
    forTime = new BN(await time.latest());
    forTime = forTime.add(new BN(tokenId));
    forNumberOfTransfers = new BN(numberOfTransfers);
    expectEvent(emitted, "AccountEnabledApproval", { _account: accountHolder, _time: forTime, _numberOfTransfers: forNumberOfTransfers });
    result = await instance.getApprovalConditions(accountHolder);
    assert.isAbove(Number(result.time), 0, "accountHolder does not have Authorize Spending");
  });

  it("17. transferFrom : spenderAccount CANNOT transferFrom accountHolder without Approval", function () {
    tokenId = 34;
    expectRevert(instance.transferFrom(accountHolder, secondAccountHolder, tokenId, { from: spenderAccount }), "ERC721: caller is not token owner or approved");
  });

  it("18. approve : account holder CAN approve spenderAccount", async function () {
    tokenId = 34;
    owner = await instance.ownerOf(tokenId);
    emitted = await instance.approve(spenderAccount, tokenId, { from: accountHolder });
    printGasUsed(emitted, 'approve');
    spender = await instance.getApproved(tokenId);
    assert.equal(spender, spenderAccount, "Approval didn't went as planned.")
  });

  it("19. transferFrom : spenderAccount CAN transferFrom accountHolder", async function () {
    tokenId = 34;
    emitted = await instance.transferFrom(accountHolder, secondAccountHolder, tokenId, { from: spenderAccount });
    printGasUsed(emitted, 'transferFrom');
  });

  it("20. transferFrom: spenderAccount CAN transferFrom accountHolder as much as they want", async function () {
    tempTokenIds = [101, 102, 103];
    i = 0;
    while (i < tempTokenIds.length) {
      await instance.safeMint(accountHolder, tempTokenIds[i], { from: deploymentAccount });
      i++;
    }

    await instance.allowApproval(100, tempTokenIds.length, { from: firstAccount });
    await instance.setApprovalForAll(spenderAccount, true, { from: accountHolder });
    i = 0;
    while (i < tempTokenIds.length) {
      emitted = await instance.transferFrom(accountHolder, secondAccountHolder, tempTokenIds[i], { from: spenderAccount });
      i++;
    }
  });

  it("21. transferFrom: spenderAccount CAN transferFrom accountHolder but no more than he's allowed", async function () {

    tempTokenIds = [104, 105, 106];
    i = 0;
    while (i < tempTokenIds.length) {
      await instance.safeMint(accountHolder, tempTokenIds[i], { from: deploymentAccount });
      i++;
    }

    await instance.allowApproval(100, tempTokenIds.length - 1, { from: firstAccount });
    await instance.setApprovalForAll(spenderAccount, true, { from: accountHolder });
    i = 0;
    while (i < tempTokenIds.length - 1) {
      emitted = await instance.transferFrom(accountHolder, secondAccountHolder, tempTokenIds[i], { from: spenderAccount });
      i++;
    }

    expectRevert(instance.transferFrom(accountHolder, secondAccountHolder, tempTokenIds[i], { from: spenderAccount }), "ERC721: caller is not token owner or approved");
  });

  it("22. transferFrom: when spenderAccount transfers ALL funds accountHolder becomes unsecure", async function () {
    tempTokenIds = await getTokenIds(instance, accountHolder);
    i = 0;
    while (i < tempTokenIds.length) {
      tempTokenId = tempTokenIds[i];

      await instance.allowTransfer(tempTokenId, 0, constants.ZERO_ADDRESS, false, { from: firstAccount });
      await instance.transferFrom(accountHolder, secondAccountHolder, tempTokenId, { from: accountHolder });
      i++;
    }
    const binding = await instance.getBindings(accountHolder);

    assert(binding.firstWallet === constants.ZERO_ADDRESS &&
      binding.secondWallet === constants.ZERO_ADDRESS,
      "accountHolder is still secure");

  });

  it("23. safeFallback : accountHolder becomes unsecure, other 2FA wallet has at least accountHolder funds | EVENT: SafeFallbackActivated", async function () {
    const tokenId = 7;
    await instance.safeMint(accountHolder, tokenId, { from: deploymentAccount });
    expectRevert(instance.safeFallback({ from: firstAccount }), "[400] KBT721: Key authorization failure");
    await instance.addBindings(firstAccount, secondAccount, { from: accountHolder });

    balance = (await instance.balanceOf(accountHolder)).toNumber();
    emitted = await instance.safeFallback({ from: firstAccount });
    printGasUsed(emitted, 'safeFallback');
    expectEvent(emitted, "SafeFallbackActivated", { _account: accountHolder });

    secondAccountBalance = (await instance.balanceOf(secondAccount)).toNumber();
    assert.isAtLeast(secondAccountBalance, balance, "second account doesn't have the full amount from account holder");

    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
  });

  it("24. resetBindings : accountHolder becomes unsecure | EVENT: AccountResetBinding", async function () {
    await instance.safeMint(accountHolder, 100, { from: deploymentAccount });
    await instance.addBindings(firstAccount, secondAccount, { from: accountHolder });

    emitted = await instance.resetBindings({ from: firstAccount });
    printGasUsed(emitted, 'resetBindings');
    expectEvent(emitted, "AccountResetBinding", { _account: accountHolder });

    accountHolderBindings = await instance.getBindings(accountHolder);
    assert.equal(accountHolderBindings.firstWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
    assert.equal(accountHolderBindings.secondWallet, constants.ZERO_ADDRESS, "accountHolder is still secure");
  });

});

async function mintTokensTmp(tokenIds, instance, accountHolder, deploymentAccount) {
  for (i = 0; i < tokenIds.length; i++) {
    let tokenId = tokenIds[i];
    await instance.safeMint(accountHolder, tokenId, { from: deploymentAccount });
  }
}

async function listTokens(instance, accountHolder) {
  const noOfTokens = (await instance.balanceOf(accountHolder)).toNumber();
  let i = 0;
  while (i < noOfTokens) {
    let tempToken = (await instance.tokenOfOwnerByIndex(accountHolder, i)).toNumber();
    console.log(i + ": " + tempToken);
    i++;
  }
}

async function getTokenIds(instance, accountHolder) {
  const noOfTokens = (await instance.balanceOf(accountHolder)).toNumber();
  let tokenIds = [];
  let i = 0;
  while (i < noOfTokens) {
    let tempToken = (await instance.tokenOfOwnerByIndex(accountHolder, i)).toNumber();
    tokenIds.push(tempToken);
    i++;
  }

  return tokenIds;
}

function printGasUsed(event, methodName) {
  const gasUsed = event.receipt.gasUsed;
  console.log(`GasUsed: ${gasUsed.toLocaleString()} for '${methodName}'`);
}
