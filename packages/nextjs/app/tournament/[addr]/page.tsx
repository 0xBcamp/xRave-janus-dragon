"use client";

import { useState } from "react";
import { useParams } from "next/navigation";
import type { NextPage } from "next";
import { useAccount, useContractRead } from "wagmi";
import { useContractEvent } from "wagmi";
import { useMoonWalletContext } from "~~/components/ScaffoldEthAppWithProviders";
import { Enter } from "~~/components/tournament/enter";
import { EnterMoon } from "~~/components/tournament/enter-moon";
import { Play } from "~~/components/tournament/play";
import { PlayMoon } from "~~/components/tournament/play-moon";
import { Withdraw } from "~~/components/tournament/withdraw";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

const Tournament: NextPage = () => {
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const { moonWallet } = useMoonWalletContext();
  const account = connectedAddress || moonWallet;
  const params = useParams<{ addr: string }>();
  const chainId = 80001;

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
    args: [account],
  });
  if (isPlayerRead.data && !isPlayer) {
    setIsPlayer(true);
  }

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "Staked",
    listener: log => {
      if (log[0].args.player == account) {
        setIsPlayer(true);
      }
    },
  });

  if (!account) {
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

  if (isPlayer && connectedAddress) {
    return (
      <>
        <Play />
      </>
    );
  }

  if (isPlayer && moonWallet) {
    return (
      <>
        <PlayMoon />
      </>
    );
  }

  if (moonWallet) {
    return (
      <>
        <EnterMoon tournament={params.addr} key={params.addr} />
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
