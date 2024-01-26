import { useState } from "react";
import { useParams } from "next/navigation";
import { useAccount, useContractRead, useContractWrite, useSignMessage } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const Play = () => {
  const writeTx = useTransactor();
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const params = useParams<{ addr: string }>();
  const [move, setMove] = useState("");

  const livesOfPlayer = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "livesOfPlayer",
    args: [connectedAddress],
  });

  const { writeAsync } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "playAgainstContract",
    args: [move],
  });

  const playAgainstContract = async () => {
    try {
      await writeTx(writeAsync, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { signMessage } = useSignMessage({ message: move });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Play your next move</span>
            <span className="block text-4xl font-bold">in the tournament {params.addr}</span>
          </h1>
          {Number(livesOfPlayer.data) > 0 ? (
            <div>
              <div className="inline-flex rounded-md shadow-sm" role="group">
                <button className="btn btn-secondary" disabled={move == "ROCK"} onClick={() => setMove("ROCK")}>
                  Rock
                </button>
                <button className="btn btn-secondary" disabled={move == "PAPER"} onClick={() => setMove("PAPER")}>
                  Paper
                </button>
                <button className="btn btn-secondary" disabled={move == "SCISSORS"} onClick={() => setMove("SCISSORS")}>
                  Scissors
                </button>
              </div>
              <div className="inline-flex rounded-md shadow-sm" role="group">
                <button className="btn btn-secondary" onClick={() => playAgainstContract()}>
                  Instant play against the contract
                </button>
                <button className="btn btn-secondary" onClick={() => signMessage()}>
                  Be matched against a human player
                </button>
              </div>
            </div>
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
                <span className="font-medium">Error!</span> You do not have any lives left.
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};
