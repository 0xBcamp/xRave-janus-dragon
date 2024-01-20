"use client";

import { useParams } from "next/navigation";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

const Exit: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const params = useParams<{ id: string }>();

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
            <div
              className="flex items-center p-4 mb-4 text-sm text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400"
              role="alert"
            >
              <svg
                className="flex-shrink-0 inline w-4 h-4 me-3"
                aria-hidden="true"
                xmlns="http://www.w3.org/2000/svg"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path d="M10 .5a9.5 9.5 0 1 0 9.5 9.5A9.51 9.51 0 0 0 10 .5ZM9.5 4a1.5 1.5 0 1 1 0 3 1.5 1.5 0 0 1 0-3ZM12 15H8a1 1 0 0 1 0-2h1v-3H8a1 1 0 0 1 0-2h2a1 1 0 0 1 1 1v4h1a1 1 0 0 1 0 2Z" />
              </svg>
              <span className="sr-only">Info</span>
              <div>
                <span className="font-medium">Error!</span> Unstaking from tournament {params.id} is not available at
                the moment. It will be available at {new Date(Number(endTime) * 1000).toLocaleString()}
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};

export default Exit;
