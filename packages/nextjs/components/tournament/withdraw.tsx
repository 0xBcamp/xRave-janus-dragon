import { useState } from "react";
import { useParams } from "next/navigation";
import { formatUnits } from "viem";
import { useAccount, useContractEvent, useContractRead, useContractWrite } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const Withdraw = () => {
  const writeTx = useTransactor();
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";

  const [withdrawn, setWithdrawn] = useState(false);

  const params = useParams<{ addr: string }>();

  const LPTokenSymbol = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "getLPSymbol",
  });

  const LPTokenDecimals = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "getLPDecimals",
  });

  const { data: LPTokenAmountOfPlayer } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "LPTokenAmountOfPlayer",
    args: [connectedAddress],
  });

  const { data: prizeAmount } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "getPrizeAmount",
    args: [connectedAddress],
  });

  const { writeAsync: withdraw } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "unstakeLPToken",
  });

  const handleWithdraw = async () => {
    try {
      await writeTx(withdraw, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[31337].Tournament.abi,
    eventName: "Unstaked",
    listener: log => {
      if (log[0].args.player == connectedAddress && (log[0].args.amount || 0n) > 0n) {
        setWithdrawn(true);
      }
    },
  });

  if (Number(LPTokenAmountOfPlayer) == 0) {
    return (
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Withdraw from the pool</span>
            <span className="block text-4xl font-bold">and get your rewards</span>
          </h1>
          <p className="text-center text-lg">This tournament ended and you have no tokens in the pool to withdraw.</p>
        </div>
      </div>
    );
  }

  if (withdrawn) {
    return (
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Withdraw from the pool</span>
            <span className="block text-4xl font-bold">and get your rewards</span>
          </h1>
          <p className="text-center text-lg">Withdrawing successful!</p>
        </div>
      </div>
    );
  }

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Withdraw from the pool</span>
            <span className="block text-4xl font-bold">and get your rewards</span>
          </h1>
          <p className="text-center text-lg">
            {formatUnits(LPTokenAmountOfPlayer || 0n, Number(LPTokenDecimals.data) || 18)}{" "}
            {LPTokenSymbol.isLoading ? "..." : LPTokenSymbol.data}
            can be withdrawn from your deposit and you earned{" "}
            {formatUnits(prizeAmount || 0n, Number(LPTokenDecimals.data) || 18)}{" "}
            {LPTokenSymbol.isLoading ? "..." : LPTokenSymbol.data}.
            <button
              className="btn btn-secondary"
              disabled={(LPTokenAmountOfPlayer || 0n) + (prizeAmount || 0n) == 0n}
              onClick={() => handleWithdraw()}
            >
              Unstake and receive earned rewards
            </button>
          </p>
        </div>
      </div>
    </>
  );
};
