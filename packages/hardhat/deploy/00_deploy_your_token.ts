import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployMocksAndTokens: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy, log } = hre.deployments;
  const chainId = await hre.getChainId();

  const BASE_FEE = "250000000000000000"; // 0.25 is this the premium in LINK?
  const GAS_PRICE_LINK = 1e9; // link per gas, is this the gas lane? // 0.000000001 LINK per gas

  // Deploy VRFCoordinatorV2Mock on local networks
  if (chainId === "31337") {
    log("Local network detected! Deploying mocks...");

    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      log: true,
      args: [BASE_FEE, GAS_PRICE_LINK], // Add the appropriate constructor arguments if needed
      autoMine: true,
    });

    log("VRFCoordinatorV2Mock Deployed!");
    log("------------------------------------------------");
  }

  // Example token deployment, adjust as necessary
  await deploy("USDT", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  await deploy("WETH", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  const USDT = await hre.ethers.getContract("USDT", deployer);
  const WETH = await hre.ethers.getContract("WETH", deployer);

  await deploy("UniswapV2Pair", {
    from: deployer,
    args: [USDT.target, WETH.target],
    log: true,
    autoMine: true,
  });

  await deploy("Vyper_contract", {
    from: deployer,
    args: [USDT.target],
    log: true,
    autoMine: true,
  });

  // Additional deployment logic...
};

export default deployMocksAndTokens;
deployMocksAndTokens.tags = ["Mocks", "Tokens"];

// import { HardhatRuntimeEnvironment } from "hardhat/types";
// import { DeployFunction } from "hardhat-deploy/types";

// /**
//  * Deploys a contract named "YourToken" using the deployer account and
//  * constructor arguments set to the deployer address
//  *
//  * @param hre HardhatRuntimeEnvironment object.
//  */
// const deployTokens: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
//   /*
//     On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

//     When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
//     should have sufficient balance to pay for the gas fees for contract creation.

//     You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
//     with a random private key in the .env file (then used on hardhat.config.ts)
//     You can run the `yarn account` command to check your balance in every network.
//   */
//   const { deployer } = await hre.getNamedAccounts();
//   const { deploy } = hre.deployments;

//   await deploy("LPToken1", {
//     from: deployer,
//     // Contract constructor arguments
//     args: [],
//     log: true,
//     // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
//     // automatically mining the contract deployment transaction. There is no effect on live networks.
//     autoMine: true,
//   });

//   await deploy("LPToken2", {
//     from: deployer,
//     // Contract constructor arguments
//     args: [],
//     log: true,
//     // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
//     // automatically mining the contract deployment transaction. There is no effect on live networks.
//     autoMine: true,
//   });

//   // Get the deployed contract
//   // const LPToken1 = await hre.ethers.getContract("LPToken1", deployer);
// };

// export default deployTokens;

// // Tags are useful if you have multiple deploy files and only want to run one of them.
// // e.g. yarn deploy --tags YourToken
// deployTokens.tags = ["Tokens"];
