const { expect } = require("chai");
const { ethers } = require("hardhat");

// Test no 1 : Buy an NFT on chain with no third-parties and with royalties transfer
// Test no 2 : Check if NFTContract support IERC721Buyable

// =========================== \\
// ******* Test no 1/2 ******* \\
// ============================\\

describe("Buy an NFT on chain with no third-parties and with royalties transfer", () => {
  before(async () => {
    [this.owner, this.addr1, this.addr2] = await ethers.getSigners();
  });

  it("should deploy contract", async () => {
    this.Contract = await hre.ethers.getContractFactory("NFTContract");
    this.contract = await this.Contract.deploy();
  });

  it("should mint tokens", async () => {
    await this.contract.mint();
    await this.contract.connect(this.addr1).mint();
  });

  it("should get correct default royalty info", async () => {
    let roy;
    let denominator;
    await this.contract.royaltyInfo().then((res) => {
      roy = res[0].toNumber();
      denominator = res[1].toNumber();
    });

    expect(roy).to.equal(1000);
    expect(denominator).to.equal(10000);
  });

  it("should NOT allow royalty update above 100%", async () => {
    let denominator;
    await this.contract.royaltyInfo().then((res) => {
      denominator = res[1].toNumber();
    });

    let newRoy = 101; // %
    newRoy = (newRoy * denominator) / 100;
    await expect(this.contract.setRoyalty(newRoy)).to.be.revertedWith(
      "Royalty must be between 0 and _royaltyDenominator"
    );
  });

  it("should NOT allow royalty update higher than current level", async () => {
    let roy;
    let denominator;
    await this.contract.royaltyInfo().then((res) => {
      roy = res[0].toNumber();
      denominator = res[1].toNumber();
    });

    let newRoy = roy + 1;
    await expect(this.contract.setRoyalty(newRoy)).to.be.revertedWith(
      "New royalty must be lower than previous one"
    );
  });

  it("should NOT allow royalty update by non-owner", async () => {
    await expect(
      this.contract.connect(this.addr1).setRoyalty(0)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("should NOT allow token price update or removal for a non owned token", async () => {
    await expect(
      this.contract.connect(this.addr1).setPrice(1, 0)
    ).to.be.revertedWith("You don't own this token");
    await expect(
      this.contract.connect(this.addr1).removeTokenSale(1)
    ).to.be.revertedWith("You don't own this token");
  });

  it("should set token for sale with new price", async () => {
    let weiTokenPrice = ethers.utils.parseEther("5");
    await this.contract.setPrice(1, weiTokenPrice);

    let getTokenPrice = await this.contract.prices(1);
    expect(getTokenPrice).to.equal(weiTokenPrice);
  });

  it("should FAIL to purchase token with insufficient funds", async () => {
    await expect(
      this.contract
        .connect(this.addr1)
        .buyToken(1, { value: ethers.utils.parseEther("4") })
    ).to.be.revertedWith("Insufficient funds to purchase this token");
  });

  it("should succeed to purchase token from owner with balance update", async () => {
    let oldOwnerBalance = await this.owner.getBalance();
    let oldAddr1Balance = await this.addr1.getBalance();

    await this.contract
      .connect(this.addr1)
      .buyToken(1, { value: ethers.utils.parseEther("5") });
    expect(this.addr1.address).to.equal(await this.contract.ownerOf(1));

    expect(oldOwnerBalance.add(ethers.utils.parseEther("5"))).to.equal(
      await this.owner.getBalance()
    );
    expect(oldAddr1Balance).gt(await this.addr1.getBalance());
  });

  it("should NOT be for sale anymore after transfer", async () => {
    await expect(
      this.contract.buyToken(1, { value: ethers.utils.parseEther("5") })
    ).to.be.revertedWith("Token is not for sale");
  });

  it("should transfer royalties after buying a token from a non-owner of the contract", async () => {
    let weiTokenPrice = ethers.utils.parseEther("10");
    await this.contract.connect(this.addr1).setPrice(1, weiTokenPrice);

    let oldOwnerBalance = await this.owner.getBalance();
    let oldAddr1Balance = await this.addr1.getBalance();
    let oldAddr2Balance = await this.addr2.getBalance();

    await this.contract
      .connect(this.addr2)
      .buyToken(1, { value: weiTokenPrice });
    expect(this.addr2.address).to.equal(await this.contract.ownerOf(1));

    expect(oldOwnerBalance.add(ethers.utils.parseEther("1"))).to.equal(
      await this.owner.getBalance()
    ); // 10%
    expect(oldAddr1Balance.add(ethers.utils.parseEther("9"))).to.equal(
      await this.addr1.getBalance()
    ); // 90%
    expect(oldAddr2Balance).gt(await this.addr2.getBalance());
  });

  it("should update royalty to zero and not transfer any to owner", async () => {
    await this.contract.setRoyalty(0);

    let weiTokenPrice = ethers.utils.parseEther("10");
    await this.contract.connect(this.addr1).setPrice(2, weiTokenPrice);

    let oldOwnerBalance = await this.owner.getBalance();
    let oldAddr1Balance = await this.addr1.getBalance();
    let oldAddr2Balance = await this.addr2.getBalance();

    await this.contract
      .connect(this.addr2)
      .buyToken(2, { value: weiTokenPrice });
    expect(this.addr2.address).to.equal(await this.contract.ownerOf(2));

    expect(oldOwnerBalance).to.equal(await this.owner.getBalance()); // 0%
    expect(oldAddr1Balance.add(ethers.utils.parseEther("10"))).to.equal(
      await this.addr1.getBalance()
    ); // 100%
    expect(oldAddr2Balance).gt(await this.addr2.getBalance());
  });
});

// =========================== \\
// ******* Test no 2/2 ******* \\
// ============================\\

describe("Check if NFTContracts support IERC721Buyable", () => {
  function getInterfaceID(contractInterface) {
    let interfaceID = ethers.constants.Zero;
    const functions = Object.keys(contractInterface.functions);
    for (let i = 0; i < functions.length; i++) {
      interfaceID = interfaceID.xor(contractInterface.getSighash(functions[i]));
    }
    return interfaceID;
  }

  it("should deploy contracts checker", async () => {
    this.InterfaceChecker = await hre.ethers.getContractFactory(
      "InterfaceChecker"
    );
    this.interfaceChecker = await this.InterfaceChecker.deploy();

    // const interfaceId = await this.interfaceChecker.interfaceId();
    // console.log("Interface ID:", interfaceId) // => '0x8ce7e09d'
  });

  it("should get right interface id => '0x8ce7e09d'", async () => {
    const NFTContractInterface = new ethers.utils.Interface([
      "event Purchase(address indexed buyer, address indexed seller, uint indexed amount)",
      "event UpdatePrice(uint indexed tokenId, uint indexed price)",
      "event RemoveFromSale(uint indexed tokenId)",
      "event UpdateRoyalty(uint indexed royalty)",

      "function setPrice(uint _tokenId, uint _price) external",
      "function removeTokenSale(uint _tokenId) external",
      "function buyToken(uint _tokenId) external payable",
      "function royaltyInfo() external view returns(uint, uint)",
      "function setRoyalty(uint _newRoyalty) external",
    ]);

    const NFTContractInterfaceID = getInterfaceID(NFTContractInterface);
    const interfaceId = NFTContractInterfaceID.toNumber().toString(16);
    expect(interfaceId).to.equal((0x8ce7e09d).toString(16));
  });

  it("should support ERC721Buyable interface", async () => {
    Contract = await hre.ethers.getContractFactory("NFTContract");
    contract = await Contract.deploy();

    const support = await this.interfaceChecker.callStatic.isERCBuyable(
      contract.address
    );
    expect(support).to.equal(true);
    const supportId = await this.interfaceChecker.callStatic.isIDERCBuyable(
      contract.address
    );
    expect(supportId).to.equal(true);

    const supportBuyableId = await contract.supportsInterface(0x8ce7e09d);
    expect(supportBuyableId).to.equal(true);
    const support721Id = await contract.supportsInterface(0x80ac58cd);
    expect(support721Id).to.equal(true);
    const support165Id = await contract.supportsInterface(0x01ffc9a7);
    expect(support165Id).to.equal(true);
    const supportEnumerableId = await contract.supportsInterface(0x780e9d63);
    expect(supportEnumerableId).to.equal(false);
  });

  it("should NOT support ERC721Buyable interface", async () => {
    Contract = await hre.ethers.getContractFactory("NFTContractNONBuyable");
    contract = await Contract.deploy();

    const support = await this.interfaceChecker.callStatic.isERCBuyable(
      contract.address
    );
    expect(support).to.equal(false);
    const supportId = await this.interfaceChecker.callStatic.isIDERCBuyable(
      contract.address
    );
    expect(supportId).to.equal(false);

    const supportBuyableId = await contract.supportsInterface(0x8ce7e09d);
    expect(supportBuyableId).to.equal(false);
    const support721Id = await contract.supportsInterface(0x80ac58cd);
    expect(support721Id).to.equal(true);
    const support165Id = await contract.supportsInterface(0x01ffc9a7);
    expect(support165Id).to.equal(true);
    const supportEnumerableId = await contract.supportsInterface(0x780e9d63);
    expect(supportEnumerableId).to.equal(false);
  });
});
