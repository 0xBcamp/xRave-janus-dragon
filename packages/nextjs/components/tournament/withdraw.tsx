import { useParams } from "next/navigation";
import { formatUnits } from "viem";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Withdraw = () => {
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";

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

  const { writeAsync } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "unstakeLPToken",
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
            <button className="btn btn-secondary" onClick={() => writeAsync()}>
              Unstake and receive earned rewards
            </button>
          </p>
        </div>
      </div>
    </>
  );
};
