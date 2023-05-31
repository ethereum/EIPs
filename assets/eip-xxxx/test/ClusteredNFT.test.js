const {expect} = require("chai");
const {addr0} = require("./helpers");

describe.only("ClusteredNFT", function () {
  let ClusteredNFT, clusteredNFT, owner, owner2, owner3, bob, alice, fred, john;

  beforeEach(async function () {
    ClusteredNFT = await ethers.getContractFactory("ClusteredNFT");

    [owner, owner2, owner3, bob, alice, fred, john] = await ethers.getSigners();

    clusteredNFT = await ClusteredNFT.deploy("ClusteredNFT", "cNFT");
    await clusteredNFT.deployed();
  });

  it("Deploys contracts, mints tokens and checks ownerships", async function () {
    await expect(
      clusteredNFT.connect(owner2).addCluster("Jolly Token", "JT", "https://jolly-token.cc/meta/", 1000, addr0)
    ).revertedWith("ZeroAddress()");

    await expect(
      clusteredNFT.connect(owner2).addCluster("Jolly Token", "JT", "https://jolly-token.cc/meta/", 100000, owner2.address)
    ).revertedWith("SizeTooLarge()");

    await expect(
      clusteredNFT.connect(owner2).addCluster("Jolly Token", "JT", "https://jolly-token.cc/meta/", 2222, owner2.address)
    )
      .to.emit(clusteredNFT, "ClusterAdded")
      .withArgs(0, "Jolly Token", "JT", "https://jolly-token.cc/meta/", 2222, owner2.address);

    await expect(clusteredNFT.connect(owner3).addCluster("Bud Token", "BT", "https://bud-token.cc/meta/", 5000, owner3.address))
      .to.emit(clusteredNFT, "ClusterAdded")
      .withArgs(1, "Bud Token", "BT", "https://bud-token.cc/meta/", 5000, owner3.address);

    await expect(clusteredNFT.connect(owner2).mint(0, bob.address))
      .emit(clusteredNFT, "Transfer")
      .withArgs(addr0, bob.address, 1);

    await expect(clusteredNFT.connect(owner3).mint(1, alice.address))
      .emit(clusteredNFT, "Transfer")
      .withArgs(addr0, alice.address, 2223);

    await expect(clusteredNFT.connect(owner3).mint(1, fred.address))
      .emit(clusteredNFT, "Transfer")
      .withArgs(addr0, fred.address, 2224);

    await expect(clusteredNFT.connect(owner3).mint(1, john.address))
      .emit(clusteredNFT, "Transfer")
      .withArgs(addr0, john.address, 2225);

    await expect(clusteredNFT.connect(owner2).mint(1, bob.address)).revertedWith("NotClusterOwner()");

    await expect(clusteredNFT.connect(owner2).mint(3, bob.address)).revertedWith("ClusterNotFound()");

    expect(await clusteredNFT.clusterOf(2223)).equal(1);

    const range = await clusteredNFT.rangeOf(0);

    expect(range[0]).equal(1);
    expect(range[1]).equal(2222);

    expect(await clusteredNFT.normalizedTokenId(1)).equal(1);
    expect(await clusteredNFT.normalizedTokenId(2223)).equal(1);
    expect(await clusteredNFT.normalizedTokenId(2225)).equal(3);
  });
});
