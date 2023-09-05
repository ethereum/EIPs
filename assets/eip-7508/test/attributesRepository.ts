import { ethers } from "hardhat";
import { expect } from "chai";
import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  OwnableMintableERC721Mock,
  AttributesRepository,
} from "../../typechain-types";
import { BigNumber } from "ethers";
import { smock, FakeContract } from "@defi-wonderland/smock";

const IERC165 = "0x01ffc9a7";
const IAttributesRepository = "0x07cd44c7";

// --------------- FIXTURES -----------------------

async function tokenAttributesFixture() {
  const factory = await ethers.getContractFactory("AttributesRepository");
  const tokenAttributes = await factory.deploy();
  await tokenAttributes.deployed();

  return { tokenAttributes };
}

async function ownedCollectionFixture() {
  const ownedCollection = await smock.fake<OwnableMintableERC721Mock>(
    "OwnableMintableERC721Mock"
  );

  return { ownedCollection };
}

// --------------- TESTS -----------------------

describe("AttributesRepository", async function () {
  let tokenAttributes: AttributesRepository;
  let ownedCollection: FakeContract<OwnableMintableERC721Mock>;

  beforeEach(async function () {
    ({ tokenAttributes } = await loadFixture(tokenAttributesFixture));
    ({ ownedCollection } = await loadFixture(ownedCollectionFixture));

    this.tokenAttributes = tokenAttributes;
    this.ownedCollection = ownedCollection;
  });

  shouldBehaveLikeTokenAttributesRepositoryInterface();

  describe("AttributesRepository", async function () {
    let issuer: SignerWithAddress;
    let owner: SignerWithAddress;
    const tokenId = 1;
    const tokenId2 = 2;

    beforeEach(async function () {
      ({ tokenAttributes } = await loadFixture(tokenAttributesFixture));
      ({ ownedCollection } = await loadFixture(ownedCollectionFixture));

      const signers = await ethers.getSigners();
      issuer = signers[0];
      owner = signers[1];

      ownedCollection.owner.returns(issuer.address);

      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );
    });

    it("can set and get token attributes", async function () {
      expect(
        await tokenAttributes.setStringAttribute(
          ownedCollection.address,
          tokenId,
          "description",
          "test description"
        )
      )
        .to.emit(tokenAttributes, "StringAttributeSet")
        .withArgs(
          ownedCollection.address,
          tokenId,
          "description",
          "test description"
        );
      expect(
        await tokenAttributes.setStringAttribute(
          ownedCollection.address,
          tokenId,
          "description1",
          "test description"
        )
      )
        .to.emit(tokenAttributes, "StringAttributeSet")
        .withArgs(
          ownedCollection.address,
          tokenId,
          "description1",
          "test description"
        );
      expect(
        await tokenAttributes.setBoolAttribute(
          ownedCollection.address,
          tokenId,
          "rare",
          true
        )
      )
        .to.emit(tokenAttributes, "BoolAttributeSet")
        .withArgs(ownedCollection.address, tokenId, "rare", true);
      expect(
        await tokenAttributes.setAddressAttribute(
          ownedCollection.address,
          tokenId,
          "owner",
          owner.address
        )
      )
        .to.emit(tokenAttributes, "AddressAttributeSet")
        .withArgs(ownedCollection.address, tokenId, "owner", owner.address);
      expect(
        await tokenAttributes.setUintAttribute(
          ownedCollection.address,
          tokenId,
          "atk",
          BigNumber.from(100)
        )
      )
        .to.emit(tokenAttributes, "UintAttributeSet")
        .withArgs(ownedCollection.address, tokenId, "atk", BigNumber.from(100));
      expect(
        await tokenAttributes.setUintAttribute(
          ownedCollection.address,
          tokenId,
          "health",
          BigNumber.from(100)
        )
      )
        .to.emit(tokenAttributes, "UintAttributeSet")
        .withArgs(
          ownedCollection.address,
          tokenId,
          "health",
          BigNumber.from(100)
        );
      expect(
        await tokenAttributes.setUintAttribute(
          ownedCollection.address,
          tokenId,
          "health",
          BigNumber.from(95)
        )
      )
        .to.emit(tokenAttributes, "UintAttributeSet")
        .withArgs(
          ownedCollection.address,
          tokenId,
          "health",
          BigNumber.from(95)
        );
      expect(
        await tokenAttributes.setUintAttribute(
          ownedCollection.address,
          tokenId,
          "health",
          BigNumber.from(80)
        )
      )
        .to.emit(tokenAttributes, "UintAttributeSet")
        .withArgs(
          ownedCollection.address,
          tokenId,
          "health",
          BigNumber.from(80)
        );
      expect(
        await tokenAttributes.setBytesAttribute(
          ownedCollection.address,
          tokenId,
          "data",
          "0x1234"
        )
      )
        .to.emit(tokenAttributes, "BytesAttributeSet")
        .withArgs(ownedCollection.address, tokenId, "data", "0x1234");

      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId,
          "description"
        )
      ).to.eql("test description");
      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId,
          "description1"
        )
      ).to.eql("test description");
      expect(
        await tokenAttributes.getBoolTokenAttribute(
          ownedCollection.address,
          tokenId,
          "rare"
        )
      ).to.eql(true);
      expect(
        await tokenAttributes.getAddressTokenAttribute(
          ownedCollection.address,
          tokenId,
          "owner"
        )
      ).to.eql(owner.address);
      expect(
        await tokenAttributes.getUintTokenAttribute(
          ownedCollection.address,
          tokenId,
          "atk"
        )
      ).to.eql(BigNumber.from(100));
      expect(
        await tokenAttributes.getUintTokenAttribute(
          ownedCollection.address,
          tokenId,
          "health"
        )
      ).to.eql(BigNumber.from(80));
      expect(
        await tokenAttributes.getBytesTokenAttribute(
          ownedCollection.address,
          tokenId,
          "data"
        )
      ).to.eql("0x1234");

      await tokenAttributes.setStringAttribute(
        ownedCollection.address,
        tokenId,
        "description",
        "test description update"
      );
      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId,
          "description"
        )
      ).to.eql("test description update");
    });

    it("can set multiple attributes of multiple types at the same time", async function () {
      await expect(
        tokenAttributes.setTokenAttributes(
          ownedCollection.address,
          tokenId,
          [
            { key: "string1", value: "value1" },
            { key: "string2", value: "value2" },
          ],
          [
            { key: "uint1", value: BigNumber.from(1) },
            { key: "uint2", value: BigNumber.from(2) },
          ],
          [
            { key: "bool1", value: true },
            { key: "bool2", value: false },
          ],
          [
            { key: "address1", value: owner.address },
            { key: "address2", value: issuer.address },
          ],
          [
            { key: "bytes1", value: "0x1234" },
            { key: "bytes2", value: "0x5678" },
          ]
        )
      )
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string1", "value1")
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string2", "value2")
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint1", BigNumber.from(1))
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint2", BigNumber.from(2))
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool1", true)
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool2", false)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address1", owner.address)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address2", issuer.address)
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes1", "0x1234")
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes2", "0x5678");
    });

    it("can update multiple attributes of multiple types at the same time", async function () {
      await tokenAttributes.setTokenAttributes(
        ownedCollection.address,
        tokenId,
        [
          { key: "string1", value: "value0" },
          { key: "string2", value: "value1" },
        ],
        [
          { key: "uint1", value: BigNumber.from(0) },
          { key: "uint2", value: BigNumber.from(1) },
        ],
        [
          { key: "bool1", value: false },
          { key: "bool2", value: true },
        ],
        [
          { key: "address1", value: issuer.address },
          { key: "address2", value: owner.address },
        ],
        [
          { key: "bytes1", value: "0x5678" },
          { key: "bytes2", value: "0x1234" },
        ]
      );

      await expect(
        tokenAttributes.setTokenAttributes(
          ownedCollection.address,
          tokenId,
          [
            { key: "string1", value: "value1" },
            { key: "string2", value: "value2" },
          ],
          [
            { key: "uint1", value: BigNumber.from(1) },
            { key: "uint2", value: BigNumber.from(2) },
          ],
          [
            { key: "bool1", value: true },
            { key: "bool2", value: false },
          ],
          [
            { key: "address1", value: owner.address },
            { key: "address2", value: issuer.address },
          ],
          [
            { key: "bytes1", value: "0x1234" },
            { key: "bytes2", value: "0x5678" },
          ]
        )
      )
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string1", "value1")
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string2", "value2")
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint1", BigNumber.from(1))
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint2", BigNumber.from(2))
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool1", true)
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool2", false)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address1", owner.address)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address2", issuer.address)
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes1", "0x1234")
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes2", "0x5678");
    });

    it("can set and update multiple attributes of multiple types at the same time even if not all types are updated at the same time", async function () {
      await tokenAttributes.setTokenAttributes(
        ownedCollection.address,
        tokenId,
        [{ key: "string1", value: "value0" }],
        [
          { key: "uint1", value: BigNumber.from(0) },
          { key: "uint2", value: BigNumber.from(1) },
        ],
        [
          { key: "bool1", value: false },
          { key: "bool2", value: true },
        ],
        [
          { key: "address1", value: issuer.address },
          { key: "address2", value: owner.address },
        ],
        []
      );

      await expect(
        tokenAttributes.setTokenAttributes(
          ownedCollection.address,
          tokenId,
          [],
          [
            { key: "uint1", value: BigNumber.from(1) },
            { key: "uint2", value: BigNumber.from(2) },
          ],
          [
            { key: "bool1", value: true },
            { key: "bool2", value: false },
          ],
          [
            { key: "address1", value: owner.address },
            { key: "address2", value: issuer.address },
          ],
          [
            { key: "bytes1", value: "0x1234" },
            { key: "bytes2", value: "0x5678" },
          ]
        )
      )
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint1", BigNumber.from(1))
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint2", BigNumber.from(2))
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool1", true)
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool2", false)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address1", owner.address)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address2", issuer.address)
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes1", "0x1234")
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes2", "0x5678");

      await expect(
        tokenAttributes.setTokenAttributes(
          ownedCollection.address,
          tokenId,
          [],
          [],
          [
            { key: "bool1", value: false },
            { key: "bool2", value: true },
          ],
          [],
          []
        )
      )
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool1", false)
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool2", true);
    });

    it("can set and update multiple attributes of multiple types at the same time", async function () {
      await expect(
        tokenAttributes.setTokenAttributes(
          ownedCollection.address,
          tokenId,
          [
            { key: "string1", value: "value1" },
            { key: "string2", value: "value2" },
          ],
          [
            { key: "uint1", value: BigNumber.from(1) },
            { key: "uint2", value: BigNumber.from(2) },
          ],
          [
            { key: "bool1", value: true },
            { key: "bool2", value: false },
          ],
          [
            { key: "address1", value: owner.address },
            { key: "address2", value: issuer.address },
          ],
          [
            { key: "bytes1", value: "0x1234" },
            { key: "bytes2", value: "0x5678" },
          ]
        )
      )
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string1", "value1")
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string2", "value2")
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint1", BigNumber.from(1))
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint2", BigNumber.from(2))
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool1", true)
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool2", false)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address1", owner.address)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address2", issuer.address)
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes1", "0x1234")
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes2", "0x5678");
    });

    it("should allow to retrieve multiple attributes at once", async function () {
      await tokenAttributes.setTokenAttributes(
        ownedCollection.address,
        tokenId,
        [
          { key: "string1", value: "value1" },
          { key: "string2", value: "value2" },
        ],
        [
          { key: "uint1", value: BigNumber.from(1) },
          { key: "uint2", value: BigNumber.from(2) },
        ],
        [
          { key: "bool1", value: true },
          { key: "bool2", value: false },
        ],
        [
          { key: "address1", value: owner.address },
          { key: "address2", value: issuer.address },
        ],
        [
          { key: "bytes1", value: "0x1234" },
          { key: "bytes2", value: "0x5678" },
        ]
      );

      expect(
        await tokenAttributes.getTokenAttributes(
          ownedCollection.address,
          tokenId,
          ["string1", "string2"],
          ["uint1", "uint2"],
          ["bool1", "bool2"],
          ["address1", "address2"],
          ["bytes1", "bytes2"]
        )
      ).to.eql([
        [
          ["string1", "value1"],
          ["string2", "value2"],
        ],
        [
          ["uint1", BigNumber.from(1)],
          ["uint2", BigNumber.from(2)],
        ],
        [
          ["bool1", true],
          ["bool2", false],
        ],
        [
          ["address1", owner.address],
          ["address2", issuer.address],
        ],
        [
          ["bytes1", "0x1234"],
          ["bytes2", "0x5678"],
        ],
      ]);
    });

    it("can set multiple string attributes at the same time", async function () {
      await expect(
        tokenAttributes.setStringAttributes(ownedCollection.address, tokenId, [
          { key: "string1", value: "value1" },
          { key: "string2", value: "value2" },
        ])
      )
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string1", "value1")
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "string2", "value2");

      expect(
        await tokenAttributes.getTokenAttributes(
          ownedCollection.address,
          tokenId,
          ["string1", "string2"],
          [],
          [],
          [],
          []
        )
      ).to.eql([
        [
          ["string1", "value1"],
          ["string2", "value2"],
        ],
        [],
        [],
        [],
        [],
      ]);
    });

    it("can set multiple uint attributes at the same time", async function () {
      await expect(
        tokenAttributes.setUintAttributes(ownedCollection.address, tokenId, [
          { key: "uint1", value: BigNumber.from(1) },
          { key: "uint2", value: BigNumber.from(2) },
        ])
      )
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint1", BigNumber.from(1))
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "uint2", BigNumber.from(2));

      expect(
        await tokenAttributes.getTokenAttributes(
          ownedCollection.address,
          tokenId,
          [],
          ["uint1", "uint2"],
          [],
          [],
          []
        )
      ).to.eql([
        [],
        [
          ["uint1", BigNumber.from(1)],
          ["uint2", BigNumber.from(2)],
        ],
        [],
        [],
        [],
      ]);
    });

    it("can set multiple bool attributes at the same time", async function () {
      await expect(
        tokenAttributes.setBoolAttributes(ownedCollection.address, tokenId, [
          { key: "bool1", value: true },
          { key: "bool2", value: false },
        ])
      )
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool1", true)
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bool2", false);

      expect(
        await tokenAttributes.getTokenAttributes(
          ownedCollection.address,
          tokenId,
          [],
          [],
          ["bool1", "bool2"],
          [],
          []
        )
      ).to.eql([
        [],
        [],
        [
          ["bool1", true],
          ["bool2", false],
        ],
        [],
        [],
      ]);
    });

    it("can set multiple address attributes at the same time", async function () {
      await expect(
        tokenAttributes.setAddressAttributes(ownedCollection.address, tokenId, [
          { key: "address1", value: owner.address },
          { key: "address2", value: issuer.address },
        ])
      )
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address1", owner.address)
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "address2", issuer.address);

      expect(
        await tokenAttributes.getTokenAttributes(
          ownedCollection.address,
          tokenId,
          [],
          [],
          [],
          ["address1", "address2"],
          []
        )
      ).to.eql([
        [],
        [],
        [],
        [
          ["address1", owner.address],
          ["address2", issuer.address],
        ],
        [],
      ]);
    });

    it("can set multiple bytes attributes at the same time", async function () {
      await expect(
        tokenAttributes.setBytesAttributes(ownedCollection.address, tokenId, [
          { key: "bytes1", value: "0x1234" },
          { key: "bytes2", value: "0x5678" },
        ])
      )
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes1", "0x1234")
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, tokenId, "bytes2", "0x5678");

      expect(
        await tokenAttributes.getTokenAttributes(
          ownedCollection.address,
          tokenId,
          [],
          [],
          [],
          [],
          ["bytes1", "bytes2"]
        )
      ).to.eql([
        [],
        [],
        [],
        [],
        [
          ["bytes1", "0x1234"],
          ["bytes2", "0x5678"],
        ],
      ]);
    });

    it("can reuse keys and values are fine", async function () {
      await tokenAttributes.setStringAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        "X1"
      );
      await tokenAttributes.setStringAttribute(
        ownedCollection.address,
        tokenId2,
        "X",
        "X2"
      );

      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql("X1");
      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId2,
          "X"
        )
      ).to.eql("X2");
    });

    it("can reuse keys among different attributes and values are fine", async function () {
      await tokenAttributes.setStringAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        "test description"
      );
      await tokenAttributes.setBoolAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        true
      );
      await tokenAttributes.setAddressAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        owner.address
      );
      await tokenAttributes.setUintAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        BigNumber.from(100)
      );
      await tokenAttributes.setBytesAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        "0x1234"
      );

      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql("test description");
      expect(
        await tokenAttributes.getBoolTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql(true);
      expect(
        await tokenAttributes.getAddressTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql(owner.address);
      expect(
        await tokenAttributes.getUintTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql(BigNumber.from(100));
      expect(
        await tokenAttributes.getBytesTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql("0x1234");
    });

    it("can reuse string values and values are fine", async function () {
      await tokenAttributes.setStringAttribute(
        ownedCollection.address,
        tokenId,
        "X",
        "common string"
      );
      await tokenAttributes.setStringAttribute(
        ownedCollection.address,
        tokenId2,
        "X",
        "common string"
      );

      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId,
          "X"
        )
      ).to.eql("common string");
      expect(
        await tokenAttributes.getStringTokenAttribute(
          ownedCollection.address,
          tokenId2,
          "X"
        )
      ).to.eql("common string");
    });

    it("should not allow to set string values to unauthorized caller", async function () {
      await expect(
        tokenAttributes
          .connect(owner)
          .setStringAttribute(
            ownedCollection.address,
            tokenId,
            "X",
            "test description"
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to set uint values to unauthorized caller", async function () {
      await expect(
        tokenAttributes
          .connect(owner)
          .setUintAttribute(
            ownedCollection.address,
            tokenId,
            "X",
            BigNumber.from(42)
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to set boolean values to unauthorized caller", async function () {
      await expect(
        tokenAttributes
          .connect(owner)
          .setBoolAttribute(ownedCollection.address, tokenId, "X", true)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to set address values to unauthorized caller", async function () {
      await expect(
        tokenAttributes
          .connect(owner)
          .setAddressAttribute(
            ownedCollection.address,
            tokenId,
            "X",
            owner.address
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to set bytes values to unauthorized caller", async function () {
      await expect(
        tokenAttributes
          .connect(owner)
          .setBytesAttribute(ownedCollection.address, tokenId, "X", "0x1234")
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });
  });

  describe("Token attributes access control", async function () {
    let issuer: SignerWithAddress;
    let owner: SignerWithAddress;
    const tokenId = 1;
    const tokenId2 = 2;

    beforeEach(async function () {
      ({ tokenAttributes } = await loadFixture(tokenAttributesFixture));
      ({ ownedCollection } = await loadFixture(ownedCollectionFixture));

      const signers = await ethers.getSigners();
      issuer = signers[0];
      owner = signers[1];

      ownedCollection.owner.returns(issuer.address);
    });

    it("should not allow registering an already registered collection", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      await expect(
        tokenAttributes.registerAccessControl(
          ownedCollection.address,
          issuer.address,
          false
        )
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "CollectionAlreadyRegistered"
      );
    });

    it("should not allow to register a collection if caller is not the owner of the collection", async function () {
      await expect(
        tokenAttributes
          .connect(owner)
          .registerAccessControl(ownedCollection.address, issuer.address, true)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to register a collection without Ownable implemented", async function () {
      ownedCollection.owner.reset();

      await expect(
        tokenAttributes.registerAccessControl(
          ownedCollection.address,
          issuer.address,
          false
        )
      ).to.be.revertedWithCustomError(tokenAttributes, "OwnableNotImplemented");
    });

    it("should allow to manage access control for registered collections", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      expect(
        await tokenAttributes
          .connect(issuer)
          .manageAccessControl(ownedCollection.address, "X", 2, owner.address)
      )
        .to.emit(tokenAttributes, "AccessControlUpdate")
        .withArgs(ownedCollection.address, "X", 2, owner);
    });

    it("should allow issuer to manage collaborators", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      expect(
        await tokenAttributes
          .connect(issuer)
          .manageCollaborators(ownedCollection.address, [owner.address], [true])
      )
        .to.emit(tokenAttributes, "CollaboratorUpdate")
        .withArgs(ownedCollection.address, [owner.address], [true]);
    });

    it("should not allow to manage collaborators of an unregistered collection", async function () {
      await expect(
        tokenAttributes
          .connect(issuer)
          .manageCollaborators(ownedCollection.address, [owner.address], [true])
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "CollectionNotRegistered"
      );
    });

    it("should not allow to manage collaborators if the caller is not the issuer", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .manageCollaborators(ownedCollection.address, [owner.address], [true])
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to manage collaborators for registered collections if collaborator arrays are not of equal length", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      await expect(
        tokenAttributes
          .connect(issuer)
          .manageCollaborators(
            ownedCollection.address,
            [owner.address, issuer.address],
            [true]
          )
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "CollaboratorArraysNotEqualLength"
      );
    });

    it("should not allow to manage access control for unregistered collections", async function () {
      await expect(
        tokenAttributes
          .connect(issuer)
          .manageAccessControl(ownedCollection.address, "X", 2, owner.address)
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "CollectionNotRegistered"
      );
    });

    it("should not allow to manage access control if the caller is not issuer", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .manageAccessControl(ownedCollection.address, "X", 2, owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should not allow to manage access control if the caller is not returned as collection owner when using ownable", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        true
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .manageAccessControl(ownedCollection.address, "X", 2, owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should return the expected value when checking for collaborators", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      expect(
        await tokenAttributes.isCollaborator(
          owner.address,
          ownedCollection.address
        )
      ).to.be.false;

      await tokenAttributes
        .connect(issuer)
        .manageCollaborators(ownedCollection.address, [owner.address], [true]);

      expect(
        await tokenAttributes.isCollaborator(
          owner.address,
          ownedCollection.address
        )
      ).to.be.true;
    });

    it("should return the expected value when checking for specific addresses", async function () {
      await tokenAttributes.registerAccessControl(
        ownedCollection.address,
        issuer.address,
        false
      );

      expect(
        await tokenAttributes.isSpecificAddress(
          owner.address,
          ownedCollection.address,
          "X"
        )
      ).to.be.false;

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(ownedCollection.address, "X", 2, owner.address);

      expect(
        await tokenAttributes.isSpecificAddress(
          owner.address,
          ownedCollection.address,
          "X"
        )
      ).to.be.true;
    });

    it("should use the issuer returned from the collection when using only issuer when only issuer is allowed to manage parameter", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, true);

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(
          ownedCollection.address,
          "X",
          0,
          ethers.constants.AddressZero
        );

      await expect(
        tokenAttributes
          .connect(owner)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");

      ownedCollection.owner.returns(owner.address);

      await expect(
        tokenAttributes
          .connect(issuer)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });

    it("should only allow collaborator to modify the parameters if only collaborator is allowed to modify them", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(
          ownedCollection.address,
          "X",
          1,
          ethers.constants.AddressZero
        );

      await tokenAttributes
        .connect(issuer)
        .manageCollaborators(ownedCollection.address, [owner.address], [true]);

      await tokenAttributes
        .connect(owner)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);

      await expect(
        tokenAttributes
          .connect(issuer)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "NotCollectionCollaborator"
      );
    });

    it("should only allow issuer and collaborator to modify the parameters if only issuer and collaborator is allowed to modify them", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(
          ownedCollection.address,
          "X",
          2,
          ethers.constants.AddressZero
        );

      await tokenAttributes
        .connect(issuer)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);

      await expect(
        tokenAttributes
          .connect(owner)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "NotCollectionIssuerOrCollaborator"
      );

      await tokenAttributes
        .connect(issuer)
        .manageCollaborators(ownedCollection.address, [owner.address], [true]);

      await tokenAttributes
        .connect(owner)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);
    });

    it("should only allow issuer and collaborator to modify the parameters if only issuer and collaborator is allowed to modify them even when using the ownable", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, true);

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(
          ownedCollection.address,
          "X",
          2,
          ethers.constants.AddressZero
        );

      ownedCollection.owner.returns(owner.address);

      await tokenAttributes
        .connect(owner)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);

      await expect(
        tokenAttributes
          .connect(issuer)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(
        tokenAttributes,
        "NotCollectionIssuerOrCollaborator"
      );

      await tokenAttributes
        .connect(owner)
        .manageCollaborators(ownedCollection.address, [issuer.address], [true]);

      await tokenAttributes
        .connect(issuer)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);
    });

    it("should only allow token owner to modify the parameters if only token owner is allowed to modify them", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(
          ownedCollection.address,
          "X",
          3,
          ethers.constants.AddressZero
        );

      await expect(
        tokenAttributes
          .connect(owner)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotTokenOwner");

      ownedCollection.ownerOf.returns(owner.address);

      await tokenAttributes
        .connect(owner)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);

      await expect(
        tokenAttributes
          .connect(issuer)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotTokenOwner");
    });

    it("should only allow specific address to modify the parameters if only specific address is allowed to modify them", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(
          ownedCollection.address,
          "X",
          4,
          ethers.constants.AddressZero
        );

      await expect(
        tokenAttributes
          .connect(owner)
          .setAddressAttribute(ownedCollection.address, 1, "X", owner.address)
      ).to.be.revertedWithCustomError(tokenAttributes, "NotSpecificAddress");

      await tokenAttributes
        .connect(issuer)
        .manageAccessControl(ownedCollection.address, "X", 4, owner.address);

      await tokenAttributes
        .connect(owner)
        .setAddressAttribute(ownedCollection.address, 1, "X", owner.address);
    });

    it("should allow to use presigned message to modify the parameters", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      const uintMessage =
        await tokenAttributes.prepareMessageToPresignUintAttribute(
          ownedCollection.address,
          1,
          "X",
          1,
          BigNumber.from(9999999999)
        );
      const stringMessage =
        await tokenAttributes.prepareMessageToPresignStringAttribute(
          ownedCollection.address,
          1,
          "X",
          "test",
          BigNumber.from(9999999999)
        );
      const boolMessage =
        await tokenAttributes.prepareMessageToPresignBoolAttribute(
          ownedCollection.address,
          1,
          "X",
          true,
          BigNumber.from(9999999999)
        );
      const bytesMessage =
        await tokenAttributes.prepareMessageToPresignBytesAttribute(
          ownedCollection.address,
          1,
          "X",
          "0x1234",
          BigNumber.from(9999999999)
        );
      const addressMessage =
        await tokenAttributes.prepareMessageToPresignAddressAttribute(
          ownedCollection.address,
          1,
          "X",
          owner.address,
          BigNumber.from(9999999999)
        );

      const uintSignature = await issuer.signMessage(
        ethers.utils.arrayify(uintMessage)
      );
      const stringSignature = await issuer.signMessage(
        ethers.utils.arrayify(stringMessage)
      );
      const boolSignature = await issuer.signMessage(
        ethers.utils.arrayify(boolMessage)
      );
      const bytesSignature = await issuer.signMessage(
        ethers.utils.arrayify(bytesMessage)
      );
      const addressSignature = await issuer.signMessage(
        ethers.utils.arrayify(addressMessage)
      );

      const uintR: string = uintSignature.substring(0, 66);
      const uintS: string = "0x" + uintSignature.substring(66, 130);
      const uintV: string = parseInt(uintSignature.substring(130, 132), 16);

      const stringR: string = stringSignature.substring(0, 66);
      const stringS: string = "0x" + stringSignature.substring(66, 130);
      const stringV: string = parseInt(stringSignature.substring(130, 132), 16);

      const boolR: string = boolSignature.substring(0, 66);
      const boolS: string = "0x" + boolSignature.substring(66, 130);
      const boolV: string = parseInt(boolSignature.substring(130, 132), 16);

      const bytesR: string = bytesSignature.substring(0, 66);
      const bytesS: string = "0x" + bytesSignature.substring(66, 130);
      const bytesV: string = parseInt(bytesSignature.substring(130, 132), 16);

      const addressR: string = addressSignature.substring(0, 66);
      const addressS: string = "0x" + addressSignature.substring(66, 130);
      const addressV: string = parseInt(
        addressSignature.substring(130, 132),
        16
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetUintAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            1,
            BigNumber.from(9999999999),
            uintV,
            uintR,
            uintS
          )
      )
        .to.emit(tokenAttributes, "UintAttributeUpdated")
        .withArgs(ownedCollection.address, 1, "X", 1);
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetStringAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "test",
            BigNumber.from(9999999999),
            stringV,
            stringR,
            stringS
          )
      )
        .to.emit(tokenAttributes, "StringAttributeUpdated")
        .withArgs(ownedCollection.address, 1, "X", "test");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBoolAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            true,
            BigNumber.from(9999999999),
            boolV,
            boolR,
            boolS
          )
      )
        .to.emit(tokenAttributes, "BoolAttributeUpdated")
        .withArgs(ownedCollection.address, 1, "X", true);
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBytesAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "0x1234",
            BigNumber.from(9999999999),
            bytesV,
            bytesR,
            bytesS
          )
      )
        .to.emit(tokenAttributes, "BytesAttributeUpdated")
        .withArgs(ownedCollection.address, 1, "X", "0x1234");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetAddressAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            owner.address,
            BigNumber.from(9999999999),
            addressV,
            addressR,
            addressS
          )
      )
        .to.emit(tokenAttributes, "AddressAttributeUpdated")
        .withArgs(ownedCollection.address, 1, "X", owner.address);
    });

    it("should not allow to use presigned message to modify the parameters if the deadline has elapsed", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      await mine(1000, { interval: 15 });

      const uintMessage =
        await tokenAttributes.prepareMessageToPresignUintAttribute(
          ownedCollection.address,
          1,
          "X",
          1,
          BigNumber.from(10)
        );
      const stringMessage =
        await tokenAttributes.prepareMessageToPresignStringAttribute(
          ownedCollection.address,
          1,
          "X",
          "test",
          BigNumber.from(10)
        );
      const boolMessage =
        await tokenAttributes.prepareMessageToPresignBoolAttribute(
          ownedCollection.address,
          1,
          "X",
          true,
          BigNumber.from(10)
        );
      const bytesMessage =
        await tokenAttributes.prepareMessageToPresignBytesAttribute(
          ownedCollection.address,
          1,
          "X",
          "0x1234",
          BigNumber.from(10)
        );
      const addressMessage =
        await tokenAttributes.prepareMessageToPresignAddressAttribute(
          ownedCollection.address,
          1,
          "X",
          owner.address,
          BigNumber.from(10)
        );

      const uintSignature = await issuer.signMessage(
        ethers.utils.arrayify(uintMessage)
      );
      const stringSignature = await issuer.signMessage(
        ethers.utils.arrayify(stringMessage)
      );
      const boolSignature = await issuer.signMessage(
        ethers.utils.arrayify(boolMessage)
      );
      const bytesSignature = await issuer.signMessage(
        ethers.utils.arrayify(bytesMessage)
      );
      const addressSignature = await issuer.signMessage(
        ethers.utils.arrayify(addressMessage)
      );

      const uintR: string = uintSignature.substring(0, 66);
      const uintS: string = "0x" + uintSignature.substring(66, 130);
      const uintV: string = parseInt(uintSignature.substring(130, 132), 16);

      const stringR: string = stringSignature.substring(0, 66);
      const stringS: string = "0x" + stringSignature.substring(66, 130);
      const stringV: string = parseInt(stringSignature.substring(130, 132), 16);

      const boolR: string = boolSignature.substring(0, 66);
      const boolS: string = "0x" + boolSignature.substring(66, 130);
      const boolV: string = parseInt(boolSignature.substring(130, 132), 16);

      const bytesR: string = bytesSignature.substring(0, 66);
      const bytesS: string = "0x" + bytesSignature.substring(66, 130);
      const bytesV: string = parseInt(bytesSignature.substring(130, 132), 16);

      const addressR: string = addressSignature.substring(0, 66);
      const addressS: string = "0x" + addressSignature.substring(66, 130);
      const addressV: string = parseInt(
        addressSignature.substring(130, 132),
        16
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetUintAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            1,
            BigNumber.from(10),
            uintV,
            uintR,
            uintS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "ExpiredDeadline");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetStringAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "test",
            BigNumber.from(10),
            stringV,
            stringR,
            stringS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "ExpiredDeadline");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBoolAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            true,
            BigNumber.from(10),
            boolV,
            boolR,
            boolS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "ExpiredDeadline");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBytesAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "0x1234",
            BigNumber.from(10),
            bytesV,
            bytesR,
            bytesS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "ExpiredDeadline");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetAddressAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            owner.address,
            BigNumber.from(10),
            addressV,
            addressR,
            addressS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "ExpiredDeadline");
    });

    it("should not allow to use presigned message to modify the parameters if the setter does not match the actual signer", async function () {
      await tokenAttributes
        .connect(issuer)
        .registerAccessControl(ownedCollection.address, issuer.address, false);

      const uintMessage =
        await tokenAttributes.prepareMessageToPresignUintAttribute(
          ownedCollection.address,
          1,
          "X",
          1,
          BigNumber.from(9999999999)
        );
      const stringMessage =
        await tokenAttributes.prepareMessageToPresignStringAttribute(
          ownedCollection.address,
          1,
          "X",
          "test",
          BigNumber.from(9999999999)
        );
      const boolMessage =
        await tokenAttributes.prepareMessageToPresignBoolAttribute(
          ownedCollection.address,
          1,
          "X",
          true,
          BigNumber.from(9999999999)
        );
      const bytesMessage =
        await tokenAttributes.prepareMessageToPresignBytesAttribute(
          ownedCollection.address,
          1,
          "X",
          "0x1234",
          BigNumber.from(9999999999)
        );
      const addressMessage =
        await tokenAttributes.prepareMessageToPresignAddressAttribute(
          ownedCollection.address,
          1,
          "X",
          owner.address,
          BigNumber.from(9999999999)
        );

      const uintSignature = await owner.signMessage(
        ethers.utils.arrayify(uintMessage)
      );
      const stringSignature = await owner.signMessage(
        ethers.utils.arrayify(stringMessage)
      );
      const boolSignature = await owner.signMessage(
        ethers.utils.arrayify(boolMessage)
      );
      const bytesSignature = await owner.signMessage(
        ethers.utils.arrayify(bytesMessage)
      );
      const addressSignature = await owner.signMessage(
        ethers.utils.arrayify(addressMessage)
      );

      const uintR: string = uintSignature.substring(0, 66);
      const uintS: string = "0x" + uintSignature.substring(66, 130);
      const uintV: string = parseInt(uintSignature.substring(130, 132), 16);

      const stringR: string = stringSignature.substring(0, 66);
      const stringS: string = "0x" + stringSignature.substring(66, 130);
      const stringV: string = parseInt(stringSignature.substring(130, 132), 16);

      const boolR: string = boolSignature.substring(0, 66);
      const boolS: string = "0x" + boolSignature.substring(66, 130);
      const boolV: string = parseInt(boolSignature.substring(130, 132), 16);

      const bytesR: string = bytesSignature.substring(0, 66);
      const bytesS: string = "0x" + bytesSignature.substring(66, 130);
      const bytesV: string = parseInt(bytesSignature.substring(130, 132), 16);

      const addressR: string = addressSignature.substring(0, 66);
      const addressS: string = "0x" + addressSignature.substring(66, 130);
      const addressV: string = parseInt(
        addressSignature.substring(130, 132),
        16
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetUintAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            1,
            BigNumber.from(9999999999),
            uintV,
            uintR,
            uintS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "InvalidSignature");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetStringAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "test",
            BigNumber.from(9999999999),
            stringV,
            stringR,
            stringS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "InvalidSignature");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBoolAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            true,
            BigNumber.from(9999999999),
            boolV,
            boolR,
            boolS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "InvalidSignature");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBytesAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "0x1234",
            BigNumber.from(9999999999),
            bytesV,
            bytesR,
            bytesS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "InvalidSignature");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetAddressAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            owner.address,
            BigNumber.from(9999999999),
            addressV,
            addressR,
            addressS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "InvalidSignature");
    });

    it("should not allow to use presigned message to modify the parameters if the signer is not authorized to modify them", async function () {
      const uintMessage =
        await tokenAttributes.prepareMessageToPresignUintAttribute(
          ownedCollection.address,
          1,
          "X",
          1,
          BigNumber.from(9999999999)
        );
      const stringMessage =
        await tokenAttributes.prepareMessageToPresignStringAttribute(
          ownedCollection.address,
          1,
          "X",
          "test",
          BigNumber.from(9999999999)
        );
      const boolMessage =
        await tokenAttributes.prepareMessageToPresignBoolAttribute(
          ownedCollection.address,
          1,
          "X",
          true,
          BigNumber.from(9999999999)
        );
      const bytesMessage =
        await tokenAttributes.prepareMessageToPresignBytesAttribute(
          ownedCollection.address,
          1,
          "X",
          "0x1234",
          BigNumber.from(9999999999)
        );
      const addressMessage =
        await tokenAttributes.prepareMessageToPresignAddressAttribute(
          ownedCollection.address,
          1,
          "X",
          owner.address,
          BigNumber.from(9999999999)
        );

      const uintSignature = await issuer.signMessage(
        ethers.utils.arrayify(uintMessage)
      );
      const stringSignature = await issuer.signMessage(
        ethers.utils.arrayify(stringMessage)
      );
      const boolSignature = await issuer.signMessage(
        ethers.utils.arrayify(boolMessage)
      );
      const bytesSignature = await issuer.signMessage(
        ethers.utils.arrayify(bytesMessage)
      );
      const addressSignature = await issuer.signMessage(
        ethers.utils.arrayify(addressMessage)
      );

      const uintR: string = uintSignature.substring(0, 66);
      const uintS: string = "0x" + uintSignature.substring(66, 130);
      const uintV: string = parseInt(uintSignature.substring(130, 132), 16);

      const stringR: string = stringSignature.substring(0, 66);
      const stringS: string = "0x" + stringSignature.substring(66, 130);
      const stringV: string = parseInt(stringSignature.substring(130, 132), 16);

      const boolR: string = boolSignature.substring(0, 66);
      const boolS: string = "0x" + boolSignature.substring(66, 130);
      const boolV: string = parseInt(boolSignature.substring(130, 132), 16);

      const bytesR: string = bytesSignature.substring(0, 66);
      const bytesS: string = "0x" + bytesSignature.substring(66, 130);
      const bytesV: string = parseInt(bytesSignature.substring(130, 132), 16);

      const addressR: string = addressSignature.substring(0, 66);
      const addressS: string = "0x" + addressSignature.substring(66, 130);
      const addressV: string = parseInt(
        addressSignature.substring(130, 132),
        16
      );

      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetUintAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            1,
            BigNumber.from(9999999999),
            uintV,
            uintR,
            uintS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetStringAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "test",
            BigNumber.from(9999999999),
            stringV,
            stringR,
            stringS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBoolAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            true,
            BigNumber.from(9999999999),
            boolV,
            boolR,
            boolS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetBytesAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            "0x1234",
            BigNumber.from(9999999999),
            bytesV,
            bytesR,
            bytesS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
      await expect(
        tokenAttributes
          .connect(owner)
          .presignedSetAddressAttribute(
            issuer.address,
            ownedCollection.address,
            1,
            "X",
            owner.address,
            BigNumber.from(9999999999),
            addressV,
            addressR,
            addressS
          )
      ).to.be.revertedWithCustomError(tokenAttributes, "NotCollectionIssuer");
    });
  });
});

async function shouldBehaveLikeTokenAttributesRepositoryInterface() {
  it("can support IERC165", async function () {
    expect(await this.tokenAttributes.supportsInterface(IERC165)).to.equal(
      true
    );
  });

  it("can support IAttributesRepository", async function () {
    expect(
      await this.tokenAttributes.supportsInterface(IAttributesRepository)
    ).to.equal(true);
  });
}
