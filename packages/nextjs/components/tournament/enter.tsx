import { useState } from "react";
import { formatUnits } from "viem";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import { useContractEvent } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
import ExternalContracts from "~~/contracts/externalContracts";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const Enter = ({ tournament }: { tournament: string }) => {
  const writeTx = useTransactor();
  // const { address } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const [approved, setApproved] = useState(false);

  const { data: tournamentData } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  let spender = "";
  let LPaddr = "";
  let amount = 0;
  let LPTokenSymbol = "";

  if (tournamentData != undefined) {
    spender = tournamentData[1];
    LPaddr = tournamentData[2];
    LPTokenSymbol = tournamentData[3];
    amount = Number(tournamentData[4]);
  }

  const { data: balance } = useContractRead({
    abi: ExternalContracts[31337].ERC20.abi,
    address: LPaddr,
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  const { data: allowance } = useContractRead({
    abi: ExternalContracts[31337].ERC20.abi,
    address: LPaddr,
    functionName: "allowance",
    args: [connectedAddress, spender],
  });

  console.log(allowance);
  if (allowance != undefined && Number(allowance) >= amount && !approved) {
    setApproved(true);
  }

  const { data: decimals } = useContractRead({
    abi: ExternalContracts[31337].ERC20.abi,
    address: LPaddr,
    functionName: "decimals",
  });

  const { writeAsync: approve } = useContractWrite({
    abi: ExternalContracts[31337].ERC20.abi,
    address: LPaddr,
    functionName: "approve",
    args: [spender, BigInt(amount)],
  });

  const approveToken = async () => {
    try {
      await writeTx(approve, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { writeAsync: deposit } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: spender,
    functionName: "stakeLPToken",
  });

  const depositToken = async () => {
    try {
      await writeTx(deposit, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  useContractEvent({
    address: LPaddr,
    abi: ExternalContracts[31337].ERC20.abi,
    eventName: "Approval",
    listener: log => {
      if (
        log[0].args.owner == connectedAddress &&
        spender == log[0].args.spender &&
        (log[0].args.value || 0n) >= BigInt(amount)
      ) {
        setApproved(true);
      }
    },
  });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Enter the tournament</span>
            <span className="block text-4xl font-bold">by staking your LP tokens</span>
          </h1>
          <div>
            You hold {formatUnits(balance || 0n, decimals || 18) || "-?-"} {LPTokenSymbol}
            <div className="flex justify-center rounded-md shadow-sm space-x-4 mt-5" role="group">
              <button className="btn btn-secondary" disabled={approved} onClick={() => approveToken()}>
                Approve {LPTokenSymbol}
              </button>
              <button className="btn btn-secondary" disabled={!approved} onClick={() => depositToken()}>
                Deposit {formatUnits(BigInt(amount) || 0n, decimals || 18).toString()} {LPTokenSymbol}
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};
