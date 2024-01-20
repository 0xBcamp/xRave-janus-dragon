"use client";

import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

const Exit: NextPage = () => {
  const { address: connectedAddress } = useAccount();

  const { data: unstakingAllowed } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "unstakingAllowed",
  });

  const { data: endTime } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "endTime",
  });

  const { data: LPTokenSymbol } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "LPTokenSymbol",
  });

  const { data: rewardTokenSymbol } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "rewardTokenSymbol",
  });

  const { data: LPTokenAmountOfPlayer } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "LPTokenAmountOfPlayer",
    args: [connectedAddress],
  });

  const { data: rewardTokenAmountOfPlayer } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "rewardTokenAmountOfPlayer",
    args: [connectedAddress],
  });

  const { writeAsync } = useScaffoldContractWrite({
    contractName: "Tournament",
    functionName: "unstakeLPToken",
    blockConfirmations: 1,
    onBlockConfirmation: txnReceipt => {
      console.log("Transaction blockHash", txnReceipt.blockHash);
    },
  });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Withdraw from the pool</span>
            <span className="block text-4xl font-bold">and get your rewards</span>
          </h1>
          {unstakingAllowed ? (
            <p className="text-center text-lg">
              {LPTokenAmountOfPlayer?.toString()} {LPTokenSymbol} and {rewardTokenAmountOfPlayer?.toString()}{" "}
              {rewardTokenSymbol} can be withdrawn.
              <button className="btn btn-secondary" onClick={() => writeAsync()}>
                Unstake and receive earned rewards
              </button>
            </p>
          ) : (
            <p>
              Unstaking is not available at the moment. It will be available at{" "}
              {new Date(Number(endTime) * 1000).toLocaleString()}
            </p>
          )}
        </div>
      </div>
    </>
  );
};

export default Exit;
