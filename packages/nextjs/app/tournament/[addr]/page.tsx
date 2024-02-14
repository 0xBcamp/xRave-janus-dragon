"use client";

import { useState } from "react";
import { useParams } from "next/navigation";
import type { NextPage } from "next";
import { useAccount, useContractRead } from "wagmi";
import { useContractEvent } from "wagmi";
import { Enter } from "~~/components/tournament/enter";
import { Play } from "~~/components/tournament/play";
import { Withdraw } from "~~/components/tournament/withdraw";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

const Tournament: NextPage = () => {
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const params = useParams<{ addr: string }>();
  const chainId = 5;

  const [isPlayer, setIsPlayer] = useState(false);

  const { data: isTournament } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "isTournament",
    args: [params.addr],
  });

  const unstakingAllowed = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "unstakingAllowed",
  });

  const isPlayerRead = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "isPlayer",
    args: [connectedAddress],
  });
  if (isPlayerRead.data && !isPlayer) {
    setIsPlayer(true);
  }

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "Staked",
    listener: log => {
      if (log[0].args.player == connectedAddress) {
        setIsPlayer(true);
      }
    },
  });

  if (!connectedAddress) {
    return (
      <>
        <p>Please connect your wallet to see the tournament</p>
      </>
    );
  }

  if (!isTournament) {
    return (
      <>
        <p>No tournament found with address {params.addr}</p>
      </>
    );
  }

  if (unstakingAllowed.data) {
    return (
      <>
        <Withdraw />
      </>
    );
  }

  if (isPlayer) {
    return (
      <>
        <Play />
      </>
    );
  }

  return (
    <>
      <Enter tournament={params.addr} key={params.addr} />
    </>
  );
};

export default Tournament;
