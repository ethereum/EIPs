const ERC5007Demo = artifacts.require("ERC5007Demo");
const ERC5007ComposableTest = artifacts.require("ERC5007ComposableTest");

module.exports = function (deployer) {
  deployer.deploy(ERC5007Demo,'ERC5007Demo','ERC5007Demo');  
  deployer.deploy(ERC5007ComposableTest,'ERC5007ComposableTest','ERC5007ComposableTest');
};
