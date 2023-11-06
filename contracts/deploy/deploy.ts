import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "ethers";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const tx = await deploy("Badge", {
    from: deployer,
    args: [
      "0x28CeE427fCD58e5EF1cE4C93F877b621E2Db66df",
      5,
      "0x51ea83562bdc7cdc587c6376a68642520256257a9d1a52d17c09131a3aeff8e9",
    ],
    log: true,
  });
  console.log(tx.address);
};

func.tags = ["Badge"];

module.exports = func;
