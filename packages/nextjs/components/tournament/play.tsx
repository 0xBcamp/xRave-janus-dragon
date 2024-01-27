import { useState } from "react";
import { useParams } from "next/navigation";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const Play = () => {
  const writeTx = useTransactor();
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const params = useParams<{ addr: string }>();
  const [move, setMove] = useState(3);

  const { data: alreadyPlayed } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "alreadyPlayed",
    args: [connectedAddress],
  });

  const { data: isActive } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "isActive",
  });

  const { data: name } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "name",
  });

  const { writeAsync: playContract } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "playAgainstContract",
    args: [move],
  });

  const playAgainstContract = async () => {
    try {
      await writeTx(playContract, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { writeAsync: playHuman } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "playAgainstPlayer",
    args: [move],
  });

  const playAgainstHuman = async () => {
    try {
      await writeTx(playHuman, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  // useContractEvent({
  //   address: params.addr,
  //   abi: DeployedContracts[31337].Tournament.abi,
  //   eventName: "Played",
  //   listener: log => {
  //     if (
  //       log[0].args.owner == connectedAddress &&
  //       spender == log[0].args.spender &&
  //       (log[0].args.value || 0n) >= BigInt(amount)
  //     ) {
  //       setApproved(true);
  //     }
  //   },
  // });

  // const { signMessage } = useSignMessage({ message: move });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Play your next move</span>
            <span className="block text-4xl font-bold">in the tournament &quot;{name}&quot;</span>
          </h1>
          {!isActive ? (
            <div
              className="flex items-center p-4 mb-4 text-sm text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400"
              role="alert"
            >
              <InformationCircleIcon className="w-5 h-5 mr-2" />
              <span className="sr-only">Info</span>
              <div>
                <span className="font-medium">Error!</span> The tournament has not started.
              </div>
            </div>
          ) : alreadyPlayed ? (
            <div
              className="flex items-center p-4 mb-4 text-sm text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400"
              role="alert"
            >
              <InformationCircleIcon className="w-5 h-5 mr-2" />
              <span className="sr-only">Info</span>
              <div>
                <span className="font-medium">Error!</span> You already played today.
              </div>
            </div>
          ) : (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <div className="flex justify-center rounded-md shadow-sm space-x-4" role="group">
                <button className="btn btn-secondary" disabled={move == 0} onClick={() => setMove(0)}>
                  Rock
                </button>
                <button className="btn btn-secondary" disabled={move == 1} onClick={() => setMove(1)}>
                  Paper
                </button>
                <button className="btn btn-secondary" disabled={move == 2} onClick={() => setMove(2)}>
                  Scissors
                </button>
              </div>
              <div className="flex rounded-md shadow-sm space-x-4" role="group">
                <button className="btn btn-secondary" onClick={() => playAgainstContract()}>
                  Instant play against the contract
                </button>
                <button className="btn btn-secondary" onClick={() => playAgainstHuman()}>
                  Be matched against a human player
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};
