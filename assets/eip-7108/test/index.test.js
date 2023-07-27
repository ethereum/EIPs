const {expect} = require("chai");
const {addr0} = require("./helpers");

describe.only("ClusteredNFT", function () {
  let ClusteredNFT, clusteredNFT,
      ClusteredNFTEnumerable, clusteredNFTEnumerable,
      owner, owner2, owner3, owner4, bob, alice, fred, john;

  beforeEach(async function () {

    [owner, owner2, owner3, owner4, bob, alice, fred, john] = await ethers.getSigners();

    ClusteredNFT = await ethers.getContractFactory("ClusteredNFT");
    clusteredNFT = await ClusteredNFT.deploy("ClusteredNFT", "cNFT");
    await clusteredNFT.deployed();

    expect(await clusteredNFT.getInterfaceId()).equal("0xf777e584");

    ClusteredNFTEnumerable = await ethers.getContractFactory("ClusteredNFTEnumerable");
    clusteredNFTEnumerable = await ClusteredNFTEnumerable.deploy("ClusteredNFT", "cNFT");
    await clusteredNFTEnumerable.deployed();

    expect(await clusteredNFTEnumerable.getInterfaceId()).equal("0x3c5640f2");
  });

  describe("ClusteredNFT", async function () {

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
      expect(await clusteredNFT.normalizedTokenId(2224)).equal(2);
      expect(await clusteredNFT.normalizedTokenId(2225)).equal(3);

      expect(await clusteredNFT.tokenURI(2224)).equal("https://bud-token.cc/meta/2");

      // verify that the binary search works as expected

      let k = (await clusteredNFT.rangeOf(1))[1].toNumber();
      let k0 = k;
      let l = 2;
      for (let i =0, j=1000;i< 79; i++, j += 33) {
        let owner = i % 2 ? owner2 : owner3;
        await clusteredNFT.connect(owner3).addCluster("Some Token", "ST", "https://some-token.cc/meta/", j, owner.address)
        let v = k + j - 10
        const result = await clusteredNFT.clusterOf(v);
        expect(result).equal(i + 2);
        k += j - 1;
      }

      k = k0;
      j = 1000;
      for (let i =0, j=1000;i< 79; i++, j += 33) {
        let v = k + j - 10
        const result = await clusteredNFT.clusterOf(v);
        // console.log(v, result, i + 2);
        expect(result).equal(i + 2);
        k += j - 1;
      }

      let myClusters = (await clusteredNFT.clustersByOwner(owner3.address)).map(e => e.toNumber());
      expect(myClusters.length).equal(41);
      expect(myClusters[10]).equal(20);

      myClusters = (await clusteredNFT.clustersByOwner(owner2.address)).map(e => e.toNumber());
      expect(myClusters.length).equal(40);
      expect(myClusters[10]).equal(21);


    });

  });

  describe("ClusteredNFTEnumerable", async function () {

    it("Deploys contracts, mints tokens and checks ownerships", async function () {
      for (let i =0;i<3;i++) {
        let owner = i > 1 ? owner3 : i ? owner2 : owner4;
        await expect(
            clusteredNFTEnumerable.connect(owner).addCluster("Token"+i, "T"+i, `https://token${i}.cc/meta/`, 10000, owner.address)
        )
            .to.emit(clusteredNFTEnumerable, "ClusterAdded")
            .withArgs(i, "Token"+i, "T"+i, `https://token${i}.cc/meta/`, 10000, owner.address);
      }

      for (let i =1; i <= 15; i++) {
        let owner = i > 9 ? owner3 : i > 4 ? owner2 : owner4;
        let expected =  i > 9 ? 20000 + i - 9 :i > 4 ? 10000 + i - 4 : i;
        await expect(clusteredNFTEnumerable.connect(owner).mint(i > 9 ? 2 : i > 4 ? 1 : 0, bob.address))
            .emit(clusteredNFTEnumerable, "Transfer")
            .withArgs(addr0, bob.address, expected);
      }

      for (let i =1; i <= 15; i++) {
        let owner = i > 9 ? owner3 : i > 4 ? owner2 : owner4;
        await clusteredNFTEnumerable.connect(owner).mint(i > 9 ? 2 : i > 4 ? 1 : 0, bob.address)
      }

      expect(await clusteredNFTEnumerable.balanceOfWithin(bob.address, 0)).equal(8);
      expect(await clusteredNFTEnumerable.balanceOfWithin(bob.address, 1)).equal(10);
      expect(await clusteredNFTEnumerable.balanceOfWithin(bob.address, 2)).equal(12);

    });
  });
});
