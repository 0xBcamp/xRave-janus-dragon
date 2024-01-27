"use client";

import { useParams } from "next/navigation";
import type { NextPage } from "next";
import { useAccount, useContractRead } from "wagmi";
import { List } from "~~/components/leaderboard/list";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

const Leaderboard: NextPage = () => {
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const params = useParams<{ addr: string }>();

  const { data: isTournament } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "isTournament",
    args: [params.addr],
  });

  const { data: topScore } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "topScore",
  });

  console.log(topScore);

  if (!connectedAddress) {
    return (
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <p>Please connect your wallet to see the leaderboard</p>
      </div>
    );
  }

  if (!isTournament) {
    return (
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <p>No tournament found with address {params.addr}</p>
      </div>
    );
  }

  if (topScore == 0n) {
    return (
      <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
        <p>No player got points at the moment</p>
      </div>
    );
  }

  return (
    <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
      <List tournament={params.addr} topScore={Number(topScore)} key={params.addr} />
    </div>
  );
};

export default Leaderboard;
