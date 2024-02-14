"use client";

import { useParams } from "next/navigation";
import type { NextPage } from "next";
import { useContractRead } from "wagmi";
import { List } from "~~/components/leaderboard/list";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

const Leaderboard: NextPage = () => {
  // const { address: connectedAddress } = useAccount();
  const params = useParams<{ addr: string }>();
  const chainId = 5;

  const { data: isTournament } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "isTournament",
    args: [params.addr],
  });

  const { data: topScore } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "topScore",
  });

  const { data: name } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "name",
  });

  console.log(topScore);

  if (!isTournament) {
    return (
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <p>No tournament found with address {params.addr}</p>
      </div>
    );
  }

  if (topScore == 0) {
    return (
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <p>No player got points at the moment</p>
      </div>
    );
  }

  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div className="px-5">
        <h1 className="text-center mb-8">
          <span className="block text-2xl mb-2">Leaderboard</span>
          <span className="block text-4xl font-bold">of the tournament &quot;{name}&quot;</span>
        </h1>
        <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
          <List tournament={params.addr} topScore={Number(topScore)} key={params.addr} />
        </div>
      </div>
    </div>
  );
};

export default Leaderboard;
