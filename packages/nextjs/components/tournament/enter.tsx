import { useState } from "react";
import { formatUnits } from "viem";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import { erc20ABI, useContractEvent } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
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
    abi: erc20ABI,
    address: LPaddr,
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  const { data: allowance } = useContractRead({
    abi: erc20ABI,
    address: LPaddr,
    functionName: "allowance",
    args: [connectedAddress, spender],
  });

  console.log(allowance);
  if (allowance != undefined && Number(allowance) >= amount && !approved) {
    setApproved(true);
  }

  const { data: decimals } = useContractRead({
    abi: erc20ABI,
    address: LPaddr,
    functionName: "decimals",
  });

  const { writeAsync: approve } = useContractWrite({
    abi: erc20ABI,
    address: LPaddr,
    functionName: "approve",
    args: [spender, BigInt(amount)],
  });

  const handleApprove = async () => {
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

  const handleDeposit = async () => {
    try {
      await writeTx(deposit, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  useContractEvent({
    address: LPaddr,
    abi: erc20ABI,
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
              <button className="btn btn-secondary" disabled={approved} onClick={() => handleApprove()}>
                Approve {LPTokenSymbol}
              </button>
              <button className="btn btn-secondary" disabled={!approved} onClick={() => handleDeposit()}>
                Deposit {formatUnits(BigInt(amount) || 0n, decimals || 18).toString()} {LPTokenSymbol}
              </button>
            </div>
            <div>
              To enter the tournament, you need to stake the required amount of LP token for its entire duration.
              <br />
              The value accrued by the LP token from deposit to wtihdrawal is used to increase the prize pool.
              <br />
              At the end of the tournament, you&apos;ll be able to withdraw the same value you deposited + game earnings
              based on rank.
              <br />
              <br />
              Simple exemple: <br />
              You deposit 1 LP token worth 1 ETH.
              <br />
              During the tournament, the LP token increase in value and by the end of the tournament, 1 LP is now worth
              1.1 ETH.
              <br />
              You get back 0.91 LP = 1 ETH plus your game earnings.
              <br />
              The remaining 0.09 LP are pooled together into the pool prize.
              <br />
              <br />
              Protocol fee on deposit/withdrawal: 0%
              <br />
              Protocol fee on prize: 10%
            </div>
          </div>
        </div>
      </div>
    </>
  );
};
