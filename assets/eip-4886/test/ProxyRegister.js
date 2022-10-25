const { expect } = require("chai")
const registerFee = 0.005;
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
const tokenURI = "https://arweave.net/_Kk3lIGmZTnwT6Q67UOTlNG2biZq1F8F9jmoH3EaA14/{id}.json"

describe("Genesis1155", function () {
  let hardhatProxyRegister
  let owner
  let addr1
  let addr2
  let addr3
  let treasury
  let addrs

  beforeEach(async function () {
    ;[owner, addr1, addr2, addr3, treasury, ...addrs] = await ethers.getSigners()

    const ProxyRegister = await ethers.getContractFactory("ProxyRegister")
    hardhatProxyRegister = await ProxyRegister.deploy(
      ethers.utils.parseEther(registerFee.toString()),
      treasury.address,
    )

    const mockERC721 = await ethers.getContractFactory("mockERC721")
    hardhatBoredApes = await mockERC721.deploy()
    hardhatLazyLions = await mockERC721.deploy()
    hardhatLoomlockNFT = await mockERC721.deploy()

    const EPSGenOne = await ethers.getContractFactory("EPSGenesis")
    hardhatEPSGenOne = await EPSGenOne.deploy(
      hardhatProxyRegister.address,
      hardhatBoredApes.address,
      hardhatLazyLions.address,
      hardhatLoomlockNFT.address,
      tokenURI
    )

  })

  context("Non-proxy addresses", function () {
    describe("Minting", function () {
      it("Cannot mint both NFTs", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr1).mintEPSGenesis(true, true),
        ).to.be.revertedWith("Only a proxy address can mint this token - go to app.epsproxy.com")       

      })
      it("Cannot mint open NFT", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr1).mintEPSGenesis(true, false),
        ).to.be.revertedWith("Only a proxy address can mint this token - go to app.epsproxy.com")   
      })
      it("Cannot mint gated NFT", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr1).mintEPSGenesis(false, true),
        ).to.be.revertedWith("Only a proxy address can mint this token - go to app.epsproxy.com")   
      })
    })

  });

  context("Proxy address", function () {
    beforeEach(async function () {
      var tx1 = await hardhatProxyRegister
      .connect(addr1)
      .makeNomination( addr2.address, 1,  {
        value: ethers.utils.parseEther(registerFee.toString()),
      })
      expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

      var tx2 = await hardhatProxyRegister
      .connect(addr2)
      .acceptNomination( addr1.address, addr3.address, 1)
      expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")
    })
    
    describe("Nominator Minting", function () {
      it("Cannot mint both NFTs", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr1).mintEPSGenesis(true, true),
        ).to.be.revertedWith("Only a proxy address can mint this token - go to app.epsproxy.com")       

      })
      it("Cannot mint open NFT", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr1).mintEPSGenesis(true, false),
        ).to.be.revertedWith("Only a proxy address can mint this token - go to app.epsproxy.com")   
      })
      it("Cannot mint gated NFT", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr1).mintEPSGenesis(false, true),
        ).to.be.revertedWith("Only a proxy address can mint this token - go to app.epsproxy.com")   
      })
    })

    describe("Proxy Minting - no eligible token", function () {
      it("Cannot mint both NFTs", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr2).mintEPSGenesis(true, true),
        ).to.be.revertedWith("Must hold an eligible token for this mint")       

      })
      it("CAN mint open NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, false)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)
      })
      it("Cannot mint gated NFT", async () => {
        await expect(
          hardhatEPSGenOne.connect(addr2).mintEPSGenesis(false, true),
        ).to.be.revertedWith("Must hold an eligible token for this mint")   
      })
    })

    describe("Proxy Minting - eligible token 1", function () {
      beforeEach(async function () {
        var tx1 = await hardhatBoredApes
        .connect(addr1)
        .safeMint()

      })

      it("CAN mint both NFTs", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)  

      })
      it("CAN mint open NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, false)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)
      })
      it("CAN mint gated NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(false, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(1)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)
      })
    })

    describe("Proxy Minting - eligible token 2", function () {
      beforeEach(async function () {
        var tx1 = await hardhatLazyLions
        .connect(addr1)
        .safeMint()

      })

      it("CAN mint both NFTs", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)  

      })
      it("CAN mint open NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, false)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)
      })
      it("CAN mint gated NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(false, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(1)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)
      })
    })

    describe("Proxy Minting - eligible token 3", function () {
      beforeEach(async function () {
        var tx1 = await hardhatLoomlockNFT
        .connect(addr1)
        .safeMint()

      })

      it("CAN mint both NFTs", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)  

      })
      it("CAN mint open NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, false)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)
      })
      it("CAN mint gated NFT", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(false, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(1)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)
      })
    })

    describe("Proxy Minting - eligible token, cannot mint 2 of either", function () {
      beforeEach(async function () {
        var tx1 = await hardhatBoredApes
        .connect(addr1)
        .safeMint()

      })

      it("Cannot mint 2 on call to both", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)  

        await expect(
          hardhatEPSGenOne.connect(addr2).mintEPSGenesis(true, true),
        ).to.be.revertedWith("Address has already minted in open mint, allocation exhausted") 

      })
      it("Cannot mint 2 open", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(true, false)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(0)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 0)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 0)).to.equal(1)

        await expect(
          hardhatEPSGenOne.connect(addr2).mintEPSGenesis(true, false),
        ).to.be.revertedWith("Address has already minted in open mint, allocation exhausted") 
      })
      it("Cannot mint 2 gated", async () => {
        var tx1 = await hardhatEPSGenOne
        .connect(addr2)
        .mintEPSGenesis(false, true)
        expect(tx1).to.emit(hardhatEPSGenOne, "TransferSingle")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.to).to.equal(addr3.address)  
        expect(receipt.events[0].args.id).to.equal(1)  
        expect(receipt.events[0].args.value).to.equal(1)  

        expect(await hardhatEPSGenOne.balanceOf(addr1.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr2.address, 1)).to.equal(0)
        expect(await hardhatEPSGenOne.balanceOf(addr3.address, 1)).to.equal(1)

        await expect(
          hardhatEPSGenOne.connect(addr2).mintEPSGenesis(false, true),
        ).to.be.revertedWith("Address has already minted in gated mint, allocation exhausted") 
      })
    })
  });
});

describe("ProxyRegister", function () {
  let hardhatProxyRegister
  let owner
  let addr1
  let addr2
  let addr3
  let treasury
  let addrs

  beforeEach(async function () {
    ;[owner, addr1, addr2, addr3, treasury, ...addrs] = await ethers.getSigners()

    const ProxyRegister = await ethers.getContractFactory("ProxyRegister")
    hardhatProxyRegister = await ProxyRegister.deploy(
      ethers.utils.parseEther(registerFee.toString()),
      treasury.address,
    )
  })

  context("Contract Setup", function () {
    describe("Constructor", function () {
      it("Has a contract balance of 0", async () => {
        const contractBalance = await ethers.provider.getBalance(
          hardhatProxyRegister.address,
        )
        expect(contractBalance).to.equal(0)
      })
    })
  });

  context("Owner Only Functions", function () {
    describe("Owner can execute", function () {

      it("Set registerFee", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(owner)
          .setRegisterFee(ethers.utils.parseEther("0.01"))
        expect(tx1).to.emit(hardhatProxyRegister, "RegisterFeeSet")
        var receipt = await tx1.wait()
        expect(receipt.events[0].args.registerFee).to.equal(BigInt(ethers.utils.parseEther("0.01")))

        const registerFeeParameter = await hardhatProxyRegister.getRegisterFee()
        expect(registerFeeParameter).to.equal(ethers.utils.parseEther("0.01"))
      })

      it("Set treasuryAddress", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(owner)
          .setTreasuryAddress(addr3.address)
        expect(tx1).to.emit(hardhatProxyRegister, "TreasuryAddressSet")
        var receipt = await tx1.wait()
        expect(receipt.events[0].args.treasuryAddress).to.equal(addr3.address)

        const treasuryAddressParameter = await hardhatProxyRegister.getTreasuryAddress()
        expect(treasuryAddressParameter).to.equal(addr3.address)
      })
    })

    describe("Non-owner cannot execute", function () {
      it("Set registerFee", async () => {
        await expect(
          hardhatProxyRegister.connect(addr1).setRegisterFee(ethers.utils.parseEther("0.01")),
        ).to.be.revertedWith("Ownable: caller is not the owner")
      })

      it("Set treasuryAddress", async () => {
        await expect(
          hardhatProxyRegister.connect(addr1).setTreasuryAddress(addr3.address),
        ).to.be.revertedWith("Ownable: caller is not the owner")
      })
    })

    describe("Withdraw", async () => {

      beforeEach(async function () {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
      })

      it("fails if not owner", async () => {
        await expect(
          hardhatProxyRegister.connect(addr1).withdraw(ethers.utils.parseEther(registerFee.toString())),
        ).to.be.revertedWith("Ownable: caller is not the owner")
      })

      it("allows owner to withdraw to the treasury", async () => {
        const withdrawalAmount = ethers.utils.parseEther(registerFee.toString())
        
        expect(
          await ethers.provider.getBalance(hardhatProxyRegister.address),
        ).to.equal(withdrawalAmount)
     
        const initialTreasuryBalance = await ethers.provider.getBalance(
          treasury.address,
        )
        tx = await hardhatProxyRegister.connect(owner).withdraw(withdrawalAmount)
        const receipt = await tx.wait()
        const finalTreasuryBalance = await ethers.provider.getBalance(
          treasury.address,
        )
        const finalContractBalance = await ethers.provider.getBalance(
          hardhatProxyRegister.address,
        )

        expect(finalTreasuryBalance).to.equal(
          initialTreasuryBalance.add(withdrawalAmount),
        )
        expect(finalContractBalance).to.equal(0)
      })
    })
  });

  context("Nominate a Proxy", function () {
    describe("Add a nomination", function () {
      it("New proxy nomination is added", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        var receipt = await tx1.wait()
        expect(receipt.events[0].args.nominator).to.equal(addr1.address)
        expect(receipt.events[0].args.proxy).to.equal(addr2.address)
        currentTime = (await ethers.provider.getBlock("latest")).timestamp
        expect(receipt.events[0].args.timestamp).to.equal(currentTime)

        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)
      })

      it("Duplicate proxy nomination not added", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        await expect(
        hardhatProxyRegister.connect(addr1).makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),})
        ).to.be.revertedWith("Address has an existing nomination")
      })

      it("Duplicate proxy nomination not added, even to a new proxy address", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        await expect(

        hardhatProxyRegister.connect(addr1).makeNomination( addr3.address, 1, {
          value: ethers.utils.parseEther(registerFee.toString()),})
        ).to.be.revertedWith("Address has an existing nomination")
      })

      it("Proxy nomination where nominator is an existing proxy not added", async () => {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        await expect(
          hardhatProxyRegister.connect(addr2).makeNomination( addr3.address, 1, {
            value: ethers.utils.parseEther(registerFee.toString()),})
          ).to.be.revertedWith("Address is already acting as a proxy")

      })

      it("Proxy nomination for an address that is already a proxy not added", async () => {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        await expect(
          hardhatProxyRegister.connect(addr3).makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),})
          ).to.be.revertedWith("Address is already acting as a proxy")
      })

      it("Address cannot be proxied to itself", async () => {
        await expect(
          hardhatProxyRegister.connect(addr1).makeNomination( addr1.address, 1, {
            value: ethers.utils.parseEther(registerFee.toString()),})
          ).to.be.revertedWith("Proxy address cannot be the same as Nominator address")
      })
    })
  })

  context("Accept a Nomination", function () {
    describe("Accept the Nomination", function () {

      it("Can do if valid", async () => {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        const registerEntry1 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry1[0]).to.equal(addr1.address)
        expect(registerEntry1[1]).to.equal(addr2.address)
        expect(registerEntry1[2]).to.equal(addr3.address)

        const registerEntry2 = await hardhatProxyRegister.connect(addr2).getProxyRecordForCaller()
        expect(registerEntry2[0]).to.equal(addr1.address)
        expect(registerEntry2[1]).to.equal(addr2.address)
        expect(registerEntry2[2]).to.equal(addr3.address)

      })

      it("Cannot do for non-existent nomination", async () => {
        await expect(
          hardhatProxyRegister.connect(addr2).acceptNomination( addr1.address, addr3.address, 1)
          ).to.be.revertedWith("Caller is not the nominated proxy for this nominator")
      })

      it("Cannot do for another address's nomination", async () => {
        var tx1 = await hardhatProxyRegister
        .connect(addr3)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        await expect(
          hardhatProxyRegister.connect(addr2).acceptNomination( addr1.address, addr3.address, 1)
          ).to.be.revertedWith("Caller is not the nominated proxy for this nominator")
      })

      it("Cannot do for a nominator that is now a proxy", async () => {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr3)
        .makeNomination( addr1.address, 1, {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx2).to.emit(hardhatProxyRegister, "NominationMade")

        var tx3 = await hardhatProxyRegister
        .connect(addr1)
        .acceptNomination( addr3.address, addr3.address, 1,)
        expect(tx3).to.emit(hardhatProxyRegister, "NominationAccepted")

        await expect(
          hardhatProxyRegister.connect(addr2).acceptNomination( addr1.address, addr3.address, 1)
          ).to.be.revertedWith("Address is already acting as a proxy")
      })

      it("Cannot do for address that is already a proxy", async () => {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr3)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx3 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr3.address, addr3.address, 1,)
        expect(tx3).to.emit(hardhatProxyRegister, "NominationAccepted")

        await expect(
          hardhatProxyRegister.connect(addr2).acceptNomination( addr1.address, addr3.address, 1)
          ).to.be.revertedWith("Address is already acting as a proxy")
      })
    })
  });


  context("Change a proxy entry", function () {
        
    describe("Change delivery address", function () {
      
      beforeEach(async function () {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        const registerEntry1 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry1[0]).to.equal(addr1.address)
        expect(registerEntry1[1]).to.equal(addr2.address)
        expect(registerEntry1[2]).to.equal(addr3.address)

        const registerEntry2 = await hardhatProxyRegister.connect(addr2).getProxyRecordForCaller()
        expect(registerEntry2[0]).to.equal(addr1.address)
        expect(registerEntry2[1]).to.equal(addr2.address)
        expect(registerEntry2[2]).to.equal(addr3.address)
      })

      it("Proxy Address can update delivery", async () => {
        const previousRegistryEntry = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(previousRegistryEntry[0]).to.equal(addr1.address)
        expect(previousRegistryEntry[1]).to.equal(addr2.address)
        expect(previousRegistryEntry[2]).to.equal(addr3.address)

        var tx1 = await hardhatProxyRegister
        .connect(addr2)
        .updateDeliveryAddress( addr1.address, 1,)
        expect(tx1).to.emit(hardhatProxyRegister, "DeliveryUpdated")

        var receipt = await tx1.wait()
        expect(receipt.events[0].args.nominator).to.equal(addr1.address)
        expect(receipt.events[0].args.proxy).to.equal(addr2.address)
        expect(receipt.events[0].args.delivery).to.equal(addr1.address)
        expect(receipt.events[0].args.oldDelivery).to.equal(addr3.address)
        currentTime = (await ethers.provider.getBlock("latest")).timestamp
        expect(receipt.events[0].args.timestamp).to.equal(currentTime)

        const newRegistryEntry = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(newRegistryEntry[0]).to.equal(addr1.address)
        expect(newRegistryEntry[1]).to.equal(addr2.address)
        expect(newRegistryEntry[2]).to.equal(addr1.address)
      })

      it("Nominator cannot edit an entry", async () => {
        const previousRegistryEntry = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(previousRegistryEntry[0]).to.equal(addr1.address)
        expect(previousRegistryEntry[1]).to.equal(addr2.address)
        expect(previousRegistryEntry[2]).to.equal(addr3.address)

        await expect(
          hardhatProxyRegister.connect(addr1).updateDeliveryAddress( addr1.address, 1,)
          ).to.be.revertedWith("Proxy entry does not exist")
      })

      it("Another address cannot edit an entry", async () => {
        const previousRegistryEntry = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(previousRegistryEntry[0]).to.equal(addr1.address)
        expect(previousRegistryEntry[1]).to.equal(addr2.address)
        expect(previousRegistryEntry[2]).to.equal(addr3.address)

        await expect(
          hardhatProxyRegister.connect(addr3).updateDeliveryAddress( addr1.address, 1,)
          ).to.be.revertedWith("Proxy entry does not exist")
      })
    })
  });

  context("Delete a proxy entry", function () {
    
    describe("Delete called from Nominator", function () {
      
      beforeEach(async function () {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        var receipt = await tx1.wait()
        expect(receipt.events[0].args.nominator).to.equal(addr1.address)
        expect(receipt.events[0].args.proxy).to.equal(addr2.address)
        currentTime = (await ethers.provider.getBlock("latest")).timestamp
        expect(receipt.events[0].args.timestamp).to.equal(currentTime)

        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)
      })

      it("Removes a nomination only", async () => {
        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)
        
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .deleteRecordByNominator(1,)
        expect(tx1).to.emit(hardhatProxyRegister, "NominationDeleted")

        const registerEntry2 = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry2).to.equal(ZERO_ADDRESS)
      })

      it("Doesn't remove a proxy entry that is for another nominator", async () => {
        // edge case test, but you can have two addresses both nominate a third address
        // as a proxy. This is OK. Let's say the proxy accepts the second nomination. If the 
        // first address (the nomination that wasn't accepted) deletes that nominoation we DON'T
        // want that to delete the second nominator's valud proxy entry, so let's check that 
        // doesn't happen
        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)

        // Now load a proxy up from address 3 to address 2:
        var tx1 = await hardhatProxyRegister
        .connect(addr3)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        var receipt = await tx1.wait()

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr3.address, addr1.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        // Verify that addr3 has the proxy with 2:
        const registerEntry1 = await hardhatProxyRegister.connect(addr3).getNominatorRecordForCaller()
        expect(registerEntry1[0]).to.equal(addr3.address)
        expect(registerEntry1[1]).to.equal(addr2.address)
        expect(registerEntry1[2]).to.equal(addr1.address)

        // Delete the nomination from address 1:  
        var tx3 = await hardhatProxyRegister
          .connect(addr1)
          .deleteRecordByNominator(1,)
        expect(tx3).to.emit(hardhatProxyRegister, "NominationDeleted")

        const registerEntry2 = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry2).to.equal(ZERO_ADDRESS)

        // Verify that addr3 has the proxy with 2:
        const registerEntry3 = await hardhatProxyRegister.connect(addr3).getNominatorRecordForCaller()
        expect(registerEntry3[0]).to.equal(addr3.address)
        expect(registerEntry3[1]).to.equal(addr2.address)
        expect(registerEntry3[2]).to.equal(addr1.address)
      })

      it("Removes nomination and proxy register Item", async () => {
        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)

        const proxyRecordExists = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false)

        const proxyEntryExists1 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists1).to.equal(false)

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        const registerEntry1 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry1[0]).to.equal(addr1.address)
        expect(registerEntry1[1]).to.equal(addr2.address)
        expect(registerEntry1[2]).to.equal(addr3.address)

        const proxyEntryExists2 = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyEntryExists2).to.equal(true)

        const proxyEntryExists3 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists3).to.equal(true)

        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .deleteRecordByNominator(1,)
        expect(tx1).to.emit(hardhatProxyRegister, "NominationDeleted")

        const registerEntry2 = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry2).to.equal(ZERO_ADDRESS)

        const proxyEntryExists4 = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyEntryExists4).to.equal(false)

        const proxyEntryExists5 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists5).to.equal(false)
      })
    })

    describe("Delete called from Proxy", function () {
      
      beforeEach(async function () {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        var receipt = await tx1.wait()
        expect(receipt.events[0].args.nominator).to.equal(addr1.address)
        expect(receipt.events[0].args.proxy).to.equal(addr2.address)
        currentTime = (await ethers.provider.getBlock("latest")).timestamp
        expect(receipt.events[0].args.timestamp).to.equal(currentTime)

        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)
      })

      it("Removes nomination and proxy register Item", async () => {
        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)

        const proxyRecordExists = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false)

        const proxyEntryExists1 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists1).to.equal(false)

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        const registerEntry1 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry1[0]).to.equal(addr1.address)
        expect(registerEntry1[1]).to.equal(addr2.address)
        expect(registerEntry1[2]).to.equal(addr3.address)

        const proxyEntryExists2 = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyEntryExists2).to.equal(true)

        const proxyEntryExists3 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists3).to.equal(true)

        var tx1 = await hardhatProxyRegister
          .connect(addr2)
          .deleteRecordByProxy(1,)
        expect(tx1).to.emit(hardhatProxyRegister, "NominationDeleted")

        const registerEntry2 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry2[0]).to.equal(ZERO_ADDRESS)
        expect(registerEntry2[1]).to.equal(ZERO_ADDRESS)
        expect(registerEntry2[2]).to.equal(ZERO_ADDRESS)

        const proxyEntryExists4 = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyEntryExists4).to.equal(false)

        const proxyEntryExists5 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists5).to.equal(false)
      })

      it("Call from Nominator does not work", async () => {
        const registerEntry = await hardhatProxyRegister.connect(addr1).getNominationForCaller()
        expect(registerEntry).to.equal(addr2.address)

        const proxyRecordExists = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false)

        const proxyEntryExists1 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists1).to.equal(false)

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        const registerEntry1 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry1[0]).to.equal(addr1.address)
        expect(registerEntry1[1]).to.equal(addr2.address)
        expect(registerEntry1[2]).to.equal(addr3.address)

        const proxyEntryExists2 = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyEntryExists2).to.equal(true)

        const proxyEntryExists3 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists3).to.equal(true)

        await expect(
          hardhatProxyRegister.connect(addr1).deleteRecordByProxy(1,)
          ).to.be.revertedWith("Proxy entry does not exist")

        const registerEntry2 = await hardhatProxyRegister.connect(addr1).getNominatorRecordForCaller()
        expect(registerEntry2[0]).to.equal(addr1.address)
        expect(registerEntry2[1]).to.equal(addr2.address)
        expect(registerEntry2[2]).to.equal(addr3.address)

        const proxyEntryExists4 = await hardhatProxyRegister.connect(addr1).nominatorRecordExistsForCaller()
        expect(proxyEntryExists4).to.equal(true)

        const proxyEntryExists5 = await hardhatProxyRegister.connect(addr2).proxyRecordExistsForCaller()
        expect(proxyEntryExists5).to.equal(true)
      })
    })
  });

  context("Getter Functions", function () {

    describe("Fee and Treasury", function () {   
      it("getRegisterFee", async () => {
        const fee = await hardhatProxyRegister.getRegisterFee()
        expect(fee).to.equal(ethers.utils.parseEther(registerFee.toString()));
      })

      it("getTreasuryAddress", async () => {
        const treasuryAddress = await hardhatProxyRegister.getTreasuryAddress()
        expect(treasuryAddress).to.equal(treasury.address);
      })
    })  

    describe("No proxy details saved", function () {
      it("nominationExists", async () => {
        const nominationExists = await hardhatProxyRegister.nominationExists(addr1.address)
        expect(nominationExists).to.equal(false);
      })

      it("nominationExistsForCaller", async () => {
        const nominationExists = await hardhatProxyRegister.connect(addr1.address).nominationExistsForCaller()
        expect(nominationExists).to.equal(false);
      })

      it("getNomination", async () => {
        const proxy = await hardhatProxyRegister.getNomination(addr1.address)
        expect(proxy).to.equal(ZERO_ADDRESS);
      })

      it("getNominationForCaller", async () => {
        const proxy = await hardhatProxyRegister.getNominationForCaller()
        expect(proxy).to.equal(ZERO_ADDRESS);
      })

      it("proxyRecordExists", async () => {
        const proxyRecordExists = await hardhatProxyRegister.proxyRecordExists(addr2.address)
        expect(proxyRecordExists).to.equal(false);
      })

      it("proxyRecordExistsForCaller", async () => {
        const proxyRecordExists = await hardhatProxyRegister.connect(addr2.address).proxyRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false);
      })

      it("nominatorRecordExists", async () => {
        const proxyRecordExists = await hardhatProxyRegister.nominatorRecordExists(addr1.address)
        expect(proxyRecordExists).to.equal(false);
      })

      it("nominatorRecordExistsForCaller", async () => {
        const proxyRecordExists = await hardhatProxyRegister.connect(addr1.address).nominatorRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false);
      })

      it("addressIsActive", async () => {
        const addressIsActive = await hardhatProxyRegister.addressIsActive(addr1.address)
        expect(addressIsActive).to.equal(false);

        const addressIsActive2 = await hardhatProxyRegister.addressIsActive(addr2.address)
        expect(addressIsActive2).to.equal(false);
      })

      it("addressIsActiveForCaller", async () => {
        const addressIsActive = await hardhatProxyRegister.connect(addr1.address).addressIsActiveForCaller()
        expect(addressIsActive).to.equal(false);

        const addressIsActive2 = await hardhatProxyRegister.connect(addr2.address).addressIsActiveForCaller()
        expect(addressIsActive2).to.equal(false);
      })

      it("getProxyRecord", async () => {
        const entry = await hardhatProxyRegister.getProxyRecord(addr2.address)
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getProxyRecordForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr2.address).getProxyRecordForCaller()
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getNominatorRecord", async () => {
        const entry = await hardhatProxyRegister.getNominatorRecord(addr1.address)
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getNominatorRecordForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr1.address).getNominatorRecordForCaller()
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getAddresses", async () => {
        const entry = await hardhatProxyRegister.getAddresses(addr2.address)
        expect(entry[0]).to.equal(addr2.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(false);
      })

      it("getAddressesForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr2.address).getAddressesForCaller()
        expect(entry[0]).to.equal(addr2.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(false);
      })
    })

    describe("With Proxy Nomination", function () {
              
      beforeEach(async function () {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
      })

      it("nominationExists", async () => {
        const nominationExists = await hardhatProxyRegister.nominationExists(addr1.address)
        expect(nominationExists).to.equal(true);
      })

      it("nominationExistsForCaller", async () => {
        const nominationExists = await hardhatProxyRegister.connect(addr1.address).nominationExistsForCaller()
        expect(nominationExists).to.equal(true);
      })

      it("getNomination", async () => {
        const proxy = await hardhatProxyRegister.getNomination(addr1.address)
        expect(proxy).to.equal(addr2.address);
      })

      it("getNominationForCaller", async () => {
        const proxy = await hardhatProxyRegister.connect(addr1.address).getNominationForCaller()
        expect(proxy).to.equal(addr2.address);
      })

      it("proxyRecordExists", async () => {
        const proxyRecordExists = await hardhatProxyRegister.proxyRecordExists(addr2.address)
        expect(proxyRecordExists).to.equal(false);
      })

      it("proxyRecordExistsForCaller", async () => {
        const proxyRecordExists = await hardhatProxyRegister.connect(addr2.address).proxyRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false);
      })

      it("nominatorRecordExists", async () => {
        const proxyRecordExists = await hardhatProxyRegister.nominatorRecordExists(addr1.address)
        expect(proxyRecordExists).to.equal(false);
      })

      it("nominatorRecordExistsForCaller", async () => {
        const proxyRecordExists = await hardhatProxyRegister.connect(addr2.address).nominatorRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(false);
      })

      it("addressIsActive", async () => {
        const addressIsActive = await hardhatProxyRegister.addressIsActive(addr1.address)
        expect(addressIsActive).to.equal(false);

        const addressIsActive2 = await hardhatProxyRegister.addressIsActive(addr2.address)
        expect(addressIsActive2).to.equal(false);
      })

      it("addressIsActiveForCaller", async () => {
        const addressIsActive = await hardhatProxyRegister.connect(addr1.address).addressIsActiveForCaller()
        expect(addressIsActive).to.equal(false);

        const addressIsActive2 = await hardhatProxyRegister.connect(addr2.address).addressIsActiveForCaller()
        expect(addressIsActive2).to.equal(false);
      })

      it("getProxyRecord", async () => {
        const entry = await hardhatProxyRegister.getProxyRecord(addr2.address)
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getProxyRecordForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr2.address).getProxyRecordForCaller()
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getNominatorRecord", async () => {
        const entry = await hardhatProxyRegister.getNominatorRecord(addr1.address)
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getNominatorRecordForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr1.address).getNominatorRecordForCaller()
        expect(entry[0]).to.equal(ZERO_ADDRESS);
        expect(entry[1]).to.equal(ZERO_ADDRESS);
        expect(entry[2]).to.equal(ZERO_ADDRESS);
      })

      it("getAddresses", async () => {
        const entry = await hardhatProxyRegister.getAddresses(addr2.address)
        expect(entry[0]).to.equal(addr2.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(false);
      })

      it("getAddressesForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr2.address).getAddressesForCaller()
        expect(entry[0]).to.equal(addr2.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(false);
      })
    })

    describe("With Proxy Active", function () {
              
      beforeEach(async function () {
        var tx1 = await hardhatProxyRegister
        .connect(addr1)
        .makeNomination( addr2.address, 1,  {
          value: ethers.utils.parseEther(registerFee.toString()),
        })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")
      })

      it("nominationExists", async () => {
        const nominationExists = await hardhatProxyRegister.nominationExists(addr1.address)
        expect(nominationExists).to.equal(true);
      })

      it("nominationExistsForCaller", async () => {
        const nominationExists = await hardhatProxyRegister.connect(addr1.address).nominationExistsForCaller()
        expect(nominationExists).to.equal(true);
      })

      it("getNomination", async () => {
        const proxy = await hardhatProxyRegister.getNomination(addr1.address)
        expect(proxy).to.equal(addr2.address);
      })

      it("getNominationForCaller", async () => {
        const proxy = await hardhatProxyRegister.connect(addr1.address).getNominationForCaller()
        expect(proxy).to.equal(addr2.address);
      })

      it("proxyRecordExists", async () => {
        const proxyRecordExists = await hardhatProxyRegister.proxyRecordExists(addr2.address)
        expect(proxyRecordExists).to.equal(true);
      })

      it("proxyRecordExistsForCaller", async () => {
        const proxyRecordExists = await hardhatProxyRegister.connect(addr2.address).proxyRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(true);
      })

      it("nominatorRecordExists", async () => {
        const proxyRecordExists = await hardhatProxyRegister.nominatorRecordExists(addr1.address)
        expect(proxyRecordExists).to.equal(true);
      })

      it("nominatorRecordExistsForCaller", async () => {
        const proxyRecordExists = await hardhatProxyRegister.connect(addr1.address).nominatorRecordExistsForCaller()
        expect(proxyRecordExists).to.equal(true);
      })

      it("addressIsActive", async () => {
        const addressIsActive = await hardhatProxyRegister.addressIsActive(addr1.address)
        expect(addressIsActive).to.equal(true);

        const addressIsActive2 = await hardhatProxyRegister.addressIsActive(addr2.address)
        expect(addressIsActive2).to.equal(true);
      })

      it("addressIsActiveForCaller", async () => {
        const addressIsActive = await hardhatProxyRegister.connect(addr1.address).addressIsActiveForCaller()
        expect(addressIsActive).to.equal(true);

        const addressIsActive2 = await hardhatProxyRegister.connect(addr2.address).addressIsActiveForCaller()
        expect(addressIsActive2).to.equal(true);
      })

      it("getProxyRecord", async () => {
        const entry = await hardhatProxyRegister.getProxyRecord(addr2.address)
        expect(entry[0]).to.equal(addr1.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(addr3.address);
      })

      it("getProxyRecordForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr2.address).getProxyRecordForCaller()
        expect(entry[0]).to.equal(addr1.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(addr3.address);
      })

      it("getNominatorRecord", async () => {
        const entry = await hardhatProxyRegister.getNominatorRecord(addr1.address)
        expect(entry[0]).to.equal(addr1.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(addr3.address);
      })

      it("getNominatorRecordForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr1.address).getNominatorRecordForCaller()
        expect(entry[0]).to.equal(addr1.address);
        expect(entry[1]).to.equal(addr2.address);
        expect(entry[2]).to.equal(addr3.address);
      })

      it("getAddresses", async () => {
        const entry = await hardhatProxyRegister.getAddresses(addr2.address)
        expect(entry[0]).to.equal(addr1.address);
        expect(entry[1]).to.equal(addr3.address);
        expect(entry[2]).to.equal(true);
      })

      it("getAddressesForCaller", async () => {
        const entry = await hardhatProxyRegister.connect(addr2.address).getAddressesForCaller()
        expect(entry[0]).to.equal(addr1.address);
        expect(entry[1]).to.equal(addr3.address);
        expect(entry[2]).to.equal(true);
      })

      it("getAddresses for nominator with valid proxy", async () => {
        const nominationExists = await hardhatProxyRegister.nominationExists(addr1.address)
        expect(nominationExists).to.equal(true);
        await expect(
          hardhatProxyRegister.getAddresses(addr1.address)
          ).to.be.revertedWith("Nominator address cannot interact directly, only through the proxy address")
      })

      it("getAddressesForCaller for nominator with valid proxy", async () => {
        await expect(
          hardhatProxyRegister.connect(addr1.address).getAddressesForCaller()
          ).to.be.revertedWith("Nominator address cannot interact directly, only through the proxy address")
      })
    })

    describe("Role", function () {
      it("Returns none with no proxy or nomination", async () => {
        var role = await hardhatProxyRegister.getRole(addr1.address)
        expect(role).to.equal("None");

        role = await hardhatProxyRegister.connect(addr1.address).getRoleForCaller()
        expect(role).to.equal("None");
      })

      it("Returns pending with unaccepted nomination", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")

        var role = await hardhatProxyRegister.getRole(addr1.address)
        expect(role).to.equal("Nominator - Proxy Pending");

        role = await hardhatProxyRegister.connect(addr1.address).getRoleForCaller()
        expect(role).to.equal("Nominator - Proxy Pending");
      })

      it("Returns active with accepted nomination", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        
        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        var role = await hardhatProxyRegister.getRole(addr1.address)
        expect(role).to.equal("Nominator - Proxy Active");

        role = await hardhatProxyRegister.connect(addr1.address).getRoleForCaller()
        expect(role).to.equal("Nominator - Proxy Active");
      })

      it("Returns proxy with unaccepted nomination", async () => {
        var tx1 = await hardhatProxyRegister
          .connect(addr1)
          .makeNomination( addr2.address, 1,  {
            value: ethers.utils.parseEther(registerFee.toString()),
          })
        expect(tx1).to.emit(hardhatProxyRegister, "NominationMade")
        
        var tx2 = await hardhatProxyRegister
        .connect(addr2)
        .acceptNomination( addr1.address, addr3.address, 1)
        expect(tx2).to.emit(hardhatProxyRegister, "NominationAccepted")

        var role = await hardhatProxyRegister.getRole(addr2.address)
        expect(role).to.equal("Proxy");

        role = await hardhatProxyRegister.connect(addr2.address).getRoleForCaller()
        expect(role).to.equal("Proxy");
      })
    })

  });
})
