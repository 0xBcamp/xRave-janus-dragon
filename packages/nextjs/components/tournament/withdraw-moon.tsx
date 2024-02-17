import { useState } from "react";
import { useParams } from "next/navigation";
import { useMoonWalletContext } from "../ScaffoldEthAppWithProviders";
import { formatUnits } from "viem";
import { useAccount, useContractEvent, useContractRead } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useMoonSDK } from "~~/hooks/moon";

export const WithdrawMoon = () => {
  const connectedAddress: string = useAccount()?.address ?? "";
  const { moonWallet } = useMoonWalletContext();
  const chainId = 80001;

  const [withdrawn, setWithdrawn] = useState(false);
  const { contractCall } = useMoonSDK();

  const params = useParams<{ addr: string }>();

  const LPTokenSymbol = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "getFancySymbol",
  });

  const LPTokenDecimals = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "getLPDecimals",
  });

  const { data: withdrawAmountFromDeposit } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "withdrawAmountFromDeposit",
    args: [connectedAddress],
  });

  const { data: prizeAmount } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: params.addr,
    functionName: "getPrizeAmount",
    args: [connectedAddress],
  });

  const handleWithdraw = async () => {
    try {
      await contractCall(
        moonWallet,
        params.addr,
        DeployedContracts[chainId].Tournament.abi as any,
        "unstakeLPToken",
        [],
      );
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  useContractEvent({
    address: params.addr,
    abi: DeployedContracts[chainId].Tournament.abi,
    eventName: "Unstaked",
    listener: log => {
      if (log[0].args.player == connectedAddress && (log[0].args.amount || 0n) > 0n) {
        setWithdrawn(true);
      }
    },
  });

  if (Number(withdrawAmountFromDeposit) == 0) {
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
            {Number(formatUnits(withdrawAmountFromDeposit || 0n, Number(LPTokenDecimals.data) || 18)).toFixed(2)}{" "}
            {LPTokenSymbol.isLoading ? "..." : LPTokenSymbol.data}
            can be withdrawn from your deposit and you earned{" "}
            {Number(formatUnits(prizeAmount || 0n, Number(LPTokenDecimals.data) || 18)).toFixed(2)}{" "}
            {LPTokenSymbol.isLoading ? "..." : LPTokenSymbol.data}.
            <button
              className="btn btn-secondary"
              disabled={(withdrawAmountFromDeposit || 0n) + (prizeAmount || 0n) == 0n}
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
