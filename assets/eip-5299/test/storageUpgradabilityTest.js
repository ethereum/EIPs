/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  StorageAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert } = require('chai')

describe('Storage Test', async function () {
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let tx
  let receipt
  let result
  const addresses = []

  before(async function () {
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
  })

  it('should have three facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }

    assert.equal(addresses.length, 3)
  })

  it('deployed facets with none storage should have ghost storage positions', async () => {
    let storagePositions = await diamondLoupeFacet.storagePositions(addresses[0])
    assert.sameMembers(storagePositions, [ethers.utils.keccak256(ethers.constants.AddressZero)])
    storagePositions = await diamondLoupeFacet.storagePositions(addresses[1])
    assert.sameMembers(storagePositions, [ethers.utils.keccak256(ethers.constants.AddressZero)])
    storagePositions = await diamondLoupeFacet.storagePositions(addresses[2])
    assert.sameMembers(storagePositions, [ethers.utils.keccak256(ethers.constants.AddressZero)])
  })

  it('adds new facet with its own new storage', async () => {
    const Test3Facet = await ethers.getContractFactory('Test3Facet')
    test3Facet = await Test3Facet.deploy()
    await test3Facet.deployed()
    addresses.push(test3Facet.address)
    const selectors = getSelectors(test3Facet)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: test3Facet.address,
        facetAction: FacetCutAction.Add,
        storageAction: StorageAction.Add,
        deprecatedFacetAddress: ethers.constants.AddressZero,
        functionSelectors: getSelectors(test3Facet)
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(test3Facet.address)
    assert.sameMembers(result, selectors)
    const storagePositions = await diamondLoupeFacet.storagePositions(test3Facet.address)
    assert.sameMembers(storagePositions, [ethers.utils.keccak256(test3Facet.address)])
  });

  it('adds new facet with upgraded storage', async () => {
    const Test4Facet = await ethers.getContractFactory('Test4Facet')
    test4Facet = await Test4Facet.deploy()
    await test4Facet.deployed()
    addresses.push(test4Facet.address)
    const selectors = getSelectors(test4Facet)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: test4Facet.address,
        facetAction: FacetCutAction.Add,
        storageAction: StorageAction.Upgrade,
        deprecatedFacetAddress: addresses[3],
        functionSelectors: getSelectors(test4Facet)
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(test4Facet.address)
    assert.sameMembers(result, selectors)
    const storagePositions = await diamondLoupeFacet.storagePositions(test4Facet.address)
    assert.sameMembers(storagePositions, [ethers.utils.keccak256(addresses[3]), ethers.utils.keccak256(test4Facet.address)])
  });

  it('adds new facet with old storage', async () => {
    const Test5Facet = await ethers.getContractFactory('Test5Facet')
    test5Facet = await Test5Facet.deploy()
    await test5Facet.deployed()
    addresses.push(test5Facet.address)
    const selectors = getSelectors(test5Facet)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: test5Facet.address,
        facetAction: FacetCutAction.Add,
        storageAction: StorageAction.Old,
        deprecatedFacetAddress: addresses[4],
        functionSelectors: getSelectors(test5Facet)
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    result = await diamondLoupeFacet.facetFunctionSelectors(test5Facet.address)
    assert.sameMembers(result, selectors)
    const storagePositions = await diamondLoupeFacet.storagePositions(test5Facet.address)
    assert.sameMembers(storagePositions, [ethers.utils.keccak256(addresses[3]), ethers.utils.keccak256(addresses[4])])
  });

  it('uses data from multiple facets in conjunction', async () => {
    const test3Facet = await ethers.getContractAt('Test3Facet', diamondAddress)
    tx = await test3Facet.setData(addresses[0]);
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`test3facet setData failed: ${tx.hash}`)
    }


    const test4Facet = await ethers.getContractAt('Test4Facet', diamondAddress)
    tx = await test4Facet.setDataUpgraded(addresses[1]);
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`test4facet setData failed: ${tx.hash}`)
    }

    // use upgraded storage contract to fetch data from both the storages
    result = await test4Facet.getDataUpgraded();
    assert.sameMembers(result, [addresses[0], addresses[1]])
  })
})
