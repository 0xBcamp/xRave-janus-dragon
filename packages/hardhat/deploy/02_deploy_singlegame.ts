import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deploySingleGame: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();

  // Retrieve the VRFCoordinatorV2Mock address from the deployment artifacts
  const vrfCoordinatorV2Mock = await get("VRFCoordinatorV2Mock");
  const vrfCoordinatorV2MockAddress = vrfCoordinatorV2Mock.address;

  // Assuming you have a function to create and fund a subscription
  const subscriptionId = await createAndFundSubscription(vrfCoordinatorV2MockAddress, deployer, ethers);

  // Deploy SingleGame contract with the retrieved subscription ID and VRF Coordinator address
  const args = [subscriptionId, "0xYourGasLaneHere", 1000000 /* callbackGasLimit */, vrfCoordinatorV2MockAddress];
  const singleGameDeployment = await deploy("SingleGame", {
    from: deployer,
    args: args,
    log: true,
  });

  log(`SingleGame deployed to ${singleGameDeployment.address}`);
};

async function createAndFundSubscription(vrfCoordinatorV2MockAddress: string, deployerAddress: string, ethers: any) {
  const vrfCoordinatorV2Mock = await ethers.getContractAt(
    "VRFCoordinatorV2Mock",
    vrfCoordinatorV2MockAddress,
    deployerAddress,
  );
  const tx = await vrfCoordinatorV2Mock.createSubscription();
  const receipt = await tx.wait();
  const subIdEvent = receipt.events?.find((e: any) => e.event === "SubscriptionCreated");
  if (!subIdEvent) throw new Error("Subscription creation failed");
  const subscriptionId = subIdEvent.args.subId;

  // Optionally fund the subscription if your mock requires it
  // const fundTx = await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, ethers.utils.parseEther("10"));
  // await fundTx.wait();

  return subscriptionId;
}

export default deploySingleGame;
deploySingleGame.tags = ["SingleGame"];
