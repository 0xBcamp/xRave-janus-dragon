"use client";

import { useParams } from "next/navigation";
import type { NextPage } from "next";
import { useAccount, useSignMessage } from "wagmi";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

const Play: NextPage = () => {
  const { address: connectedAddress } = useAccount();
  const params = useParams<{ id: string }>();

  const { data: livesOfPlayer } = useScaffoldContractRead({
    contractName: "Tournament",
    functionName: "livesOfPlayer",
    args: [connectedAddress],
  });

  /*   const { data: tournamentData } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "getTournament",
    args: [BigInt(params.id)],
  });
 */
  const { signMessage } = useSignMessage();

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Play your next move</span>
            <span className="block text-4xl font-bold">in the tournament {params.id}</span>
          </h1>
          {Number(livesOfPlayer) > 0 ? (
            <div className="inline-flex rounded-md shadow-sm" role="group">
              <button className="btn btn-secondary" onClick={() => signMessage({ message: "ROCK" })}>
                Rock
              </button>
              <button className="btn btn-secondary" onClick={() => signMessage({ message: "PAPER" })}>
                Paper
              </button>
              <button className="btn btn-secondary" onClick={() => signMessage({ message: "SCISSORS" })}>
                Scissors
              </button>
            </div>
          ) : (
            <p className="text-center">You do not have any lives left.</p>
          )}
        </div>
      </div>
    </>
  );
};

export default Play;
