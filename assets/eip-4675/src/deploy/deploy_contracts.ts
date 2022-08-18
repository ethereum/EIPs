import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const deploy: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment,
) {
  const { deployments, hardhatArguments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  await deploy("MFNFT", {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: true,
  });

  await deploy("NFT", {
    from: deployer,
    args: [],
    log: true,
    deterministicDeployment: true,
  });

};

deploy.tags = ['contracts', 'MFNFT', 'NFT']
export default deploy;
