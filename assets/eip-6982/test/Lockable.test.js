const {expect} = require("chai");
const { deployContractUpgradeable, deployContract} = require("./helpers");

describe("ERC721Lockable", function () {
  let myToken;
  let myLocker;

  let owner, holder, holder2;

  before(async function () {
    [owner, holder, holder2] = await ethers.getSigners();
  });

  beforeEach(async function () {
    // myPool = await deployContract("MyPlayer");
    myToken = await deployContract("ERC721LockableMock", "My token", "NFT");
    myLocker = await deployContract("MyLocker")
  });

  it("should verify the flow", async function () {

    expect(await myToken.supportsInterface("0x2e4e0d27")).equal(true);

    await myToken.mint(holder.address, 5);

    await myToken.setLocker(myLocker.address);
    expect(await myToken.isLocker(myLocker.address)).equal(true);

    await expect(myLocker.lock(myToken.address, 2)).revertedWith("Locker not approved");

    await myToken.connect(holder).approve(myLocker.address, 2);
    await myLocker.lock(myToken.address, 2);

    expect(await myToken.locked(2)).equal(true);

    await expect(myToken.connect(holder).transferFrom(holder.address, holder2.address, 2)).revertedWith("Token is locked");

    await expect(myToken.connect(holder).transferFrom(holder.address, holder2.address, 3)).emit(myToken, "Transfer").withArgs(holder.address, holder2.address, 3);

  });

});
