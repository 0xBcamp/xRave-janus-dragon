import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

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
  const LPToken1 = await hre.ethers.getContract<Contract>("LPToken1", deployer);
  const LPToken2 = await hre.ethers.getContract<Contract>("LPToken2", deployer);

  await deploy("Tournament", {
    from: deployer,
    // Contract constructor arguments
    args: [deployer, "Tournament", "0x0000000000000000000000000000000000000000", 0, 0, 0],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  await deploy("TournamentFactory", {
    from: deployer,
    // Contract constructor arguments
    args: [deployer],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  // Get the deployed contract to interact with it after deploying.

  const frontBurner = "0x7D64289652C768b56A9Efa7eEc7cb4133c8317e2"; // Address of the front end burner account
  await LPToken1.transfer(frontBurner, hre.ethers.parseEther("1000"));
  await LPToken2.transfer(frontBurner, hre.ethers.parseEther("1000"));
};

export default deployContracts;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags YourContract
deployContracts.tags = ["Contracts"];
