import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
//import { Contract } from "ethers";

/**
 * Deploys a contract named "YourContract" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
const deployContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;
  // const UniswapV2Pair = await hre.ethers.getContract<Contract>("UniswapV2Pair", deployer);
  // const Vyper_contract = await hre.ethers.getContract<Contract>("Vyper_contract", deployer); // yearn
  // const vrf = await hre.ethers.getContract<Contract>("VRFCoordinatorV2Mock", deployer);

  // await deploy("VRFConsumerBaseV2Upgradeable", {
  //   from: deployer,
  //   // Contract constructor arguments
  //   args: [],
  //   log: true,
  //   // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
  //   // automatically mining the contract deployment transaction. There is no effect on live networks.
  //   autoMine: true,
  // });

  await deploy("Tournament", {
    from: deployer,
    // Contract constructor arguments
    args: [],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  //const implementation = await hre.ethers.getContract<Contract>("Tournament", deployer);
  const frontBurner = "0xCd3C672770495EC50013E40AEd66DBD755BbC584"; //@note this is where you need to add your burnner address

  await deploy("TournamentFactory", {
    from: deployer,
    // Contract constructor arguments
    args: [frontBurner, "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed"],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.

  // await UniswapV2Pair.transfer(frontBurner, hre.ethers.parseEther("1000"));
  // await Vyper_contract.transfer(frontBurner, hre.ethers.parseEther("1000"));
};

export default deployContracts;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployContracts.tags = ["Contracts"];
