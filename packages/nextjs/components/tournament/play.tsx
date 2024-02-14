import { useState } from "react";
import { useParams } from "next/navigation";
import { useAccount, useContractEvent, useContractRead, useContractWrite } from "wagmi";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const Play = () => {
  const writeTx = useTransactor();
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const params = useParams<{ addr: string }>();
  const chainId = 5;
  const [move, setMove] = useState(3);
  const [hash0, setHash0] = useState<`0x${string}`>("0x");
  const [hash1, setHash1] = useState<`0x${string}`>("0x");
  const [hash2, setHash2] = useState<`0x${string}`>("0x");
  const [hash, setHash] = useState<`0x${string}`>("0x");
  const [result, setResult] = useState("none");
  const [VRFrequest, setVRFrequest] = useState(0);

  const { data: alreadyPlayed } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "alreadyPlayed",
    args: [connectedAddress],
  });

  const { data: hashMoves } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "hashMoves",
    args: [connectedAddress],
  });
  if (hash0 == "0x" && hashMoves != undefined) {
    const [h0, h1, h2] = hashMoves;
    console.log(h0, h1, h2);
    setHash0(h0);
    setHash1(h1);
    setHash2(h2);
  }

  const { data: isActive } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "isActive",
  });

  const { data: name } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "name",
  });

  const { writeAsync: playContract } = useContractWrite({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "playAgainstContract",
    args: [move],
  });

  const handlePlayAgainstContract = async () => {
    setResult("sent");
    try {
      await writeTx(playContract, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { writeAsync: playHuman } = useContractWrite({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "playAgainstPlayer",
    args: [hash],
  });

  const handlePlayAgainstHuman = async () => {
    setResult("sent");
    try {
      await writeTx(playHuman, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const handleMove = (m: number) => {
    setMove(m);
    m == 0 ? setHash(hash0) : m == 1 ? setHash(hash1) : setHash(hash2);
  };

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "MoveSaved",
    listener: log => {
      if (log[0].args.player == connectedAddress) {
        setVRFrequest(Number(log[0].args.vrf) || 0);
        if (result == "sent" || result == "none") setResult("saved");
      }
    },
  });

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "Winner",
    listener: log => {
      if (log[0].args.player == connectedAddress) {
        setResult("winner");
      }
    },
  });

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "Loser",
    listener: log => {
      if (log[0].args.player == connectedAddress) {
        setResult("loser");
      }
    },
  });

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "Draw",
    listener: log => {
      if (log[0].args.player == connectedAddress || log[0].args.opponent == connectedAddress) {
        setResult("draw");
      }
    },
  });

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
          ) : result == "winner" ? (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <p>Congratulations! You won against your opponent.</p>
            </div>
          ) : result == "loser" ? (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <p>You lost against your opponent.</p>
            </div>
          ) : result == "draw" ? (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <p>That&apos;s a draw!</p>
            </div>
          ) : result == "saved" && VRFrequest > 0 ? (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <p>
                Waiting for the move of the contract (request: {VRFrequest.toString()}).
                <br />
                You can close this window or wait for the resolution.
              </p>
            </div>
          ) : result == "saved" ? (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <p>
                Waiting for a player to match against you.
                <br />
                You can close this window or wait for the resolution.
              </p>
            </div>
          ) : result == "sent" ? (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <p>Your move has been sent</p>
            </div>
          ) : (
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <div className="flex justify-center rounded-md shadow-sm space-x-4" role="group">
                <button className="btn btn-secondary" disabled={move == 0} onClick={() => handleMove(0)}>
                  Rock
                </button>
                <button className="btn btn-secondary" disabled={move == 1} onClick={() => handleMove(1)}>
                  Paper
                </button>
                <button className="btn btn-secondary" disabled={move == 2} onClick={() => handleMove(2)}>
                  Scissors
                </button>
              </div>
              <div className="flex justify-center rounded-md shadow-sm space-x-4" role="group">
                <button className="btn btn-secondary" disabled={move > 2} onClick={() => handlePlayAgainstContract()}>
                  Instant play against the contract
                </button>
                <button className="btn btn-secondary" disabled={move > 2} onClick={() => handlePlayAgainstHuman()}>
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
