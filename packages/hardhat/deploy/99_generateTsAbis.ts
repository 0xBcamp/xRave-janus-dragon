/**
 * DON'T MODIFY OR DELETE THIS SCRIPT (unless you know what you're doing)
 *
 * This script generates the file containing the contracts Abi definitions.
 * These definitions are used to derive the types needed in the custom scaffold-eth hooks, for example.
 * This script should run as the last deploy script.
 *  */

import * as fs from "fs";
import prettier from "prettier";
import { DeployFunction } from "hardhat-deploy/types";

const DEPLOYMENTS_DIR = "./deployments";
const ARTIFACTS_DIR = "./artifacts";

function getDirectories(path: string) {
  return fs
    .readdirSync(path, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);
}

function getContractNames(path: string) {
  return fs
    .readdirSync(path, { withFileTypes: true })
    .filter(dirent => dirent.isFile() && dirent.name.endsWith(".json"))
    .map(dirent => dirent.name.split(".")[0]);
}

function getInheritedFunctions(sources: { [key: string]: any }, contractName: string) {
  const inheritedFunctions = {} as Record<string, any>;
  for (const sourcePath of Object.keys(sources)) {
    const sourceName = sourcePath.split("/").pop()?.split(".sol")[0];
    if (sourceName === contractName) {
      continue;
    }
    const { abi } = JSON.parse(fs.readFileSync(`${ARTIFACTS_DIR}/${sourcePath}/${sourceName}.json`).toString());
    for (const functionAbi of abi) {
      if (functionAbi.type === "function") {
        inheritedFunctions[functionAbi.name] = sourcePath;
      }
    }
  }
  return inheritedFunctions;
}

function getContractDataFromDeployments() {
  if (!fs.existsSync(DEPLOYMENTS_DIR)) {
    throw Error("At least one other deployment script should exist to generate an actual contract.");
  }
  const output = {} as Record<string, any>;
  for (const chainName of getDirectories(DEPLOYMENTS_DIR)) {
    const chainId = fs.readFileSync(`${DEPLOYMENTS_DIR}/${chainName}/.chainId`).toString();
    const contracts = {} as Record<string, any>;
    for (const contractName of getContractNames(`${DEPLOYMENTS_DIR}/${chainName}`)) {
      const { abi, address, metadata } = JSON.parse(
        fs.readFileSync(`${DEPLOYMENTS_DIR}/${chainName}/${contractName}.json`).toString(),
      );
      const inheritedFunctions = getInheritedFunctions(JSON.parse(metadata).sources, contractName);
      contracts[contractName] = { address, abi, inheritedFunctions };
    }
    output[chainId] = [
      {
        chainId,
        name: chainName,
        contracts,
      },
    ];
  }
  return output;
}

/**
 * Generates the TypeScript contract definition file based on the json output of the contract deployment scripts
 * This script should be run last.
 */
const generateTsAbis: DeployFunction = async function () {
  const TARGET_DIR = "../nextjs/generated/";
  const allContractsData = getContractDataFromDeployments();

  const fileContent = Object.entries(allContractsData).reduce((content, [chainId, chainConfig]) => {
    return `${content}${parseInt(chainId).toFixed(0)}:${JSON.stringify(chainConfig, null, 2)},`;
  }, "");

  if (!fs.existsSync(TARGET_DIR)) {
    fs.mkdirSync(TARGET_DIR);
  }
  fs.writeFileSync(
    `${TARGET_DIR}deployedContracts.ts`,
    prettier.format(`const contracts = {${fileContent}} as const; \n\n export default contracts`, {
      parser: "typescript",
    }),
  );

  console.log(`📝 Updated TypeScript contract definition file on ${TARGET_DIR}deployedContracts.ts`);
};

export default generateTsAbis;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags generateTsAbis
generateTsAbis.tags = ["generateTsAbis"];

generateTsAbis.runAtTheEnd = true;
