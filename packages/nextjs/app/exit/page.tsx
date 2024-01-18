"use client";

import type { NextPage } from "next";
import { useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

const Exit: NextPage = () => {
  const { writeAsync } = useScaffoldContractWrite({
    contractName: "YourContract",
    functionName: "withdraw",
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
          <button className="btn btn-secondary" onClick={() => writeAsync()}>
            Withdraw
          </button>
        </div>
      </div>
    </>
  );
};

export default Exit;
