import { useParams } from "next/navigation";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Withdraw = () => {
  // const { address: connectedAddress } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";

  const params = useParams<{ addr: string }>();

  const LPTokenSymbol = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "LPTokenSymbol",
  });

  const rewardTokenSymbol = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "rewardTokenSymbol",
  });

  const LPTokenAmountOfPlayer = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "LPTokenAmountOfPlayer",
    args: [connectedAddress],
  });

  const rewardTokenAmountOfPlayer = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "rewardTokenAmountOfPlayer",
    args: [connectedAddress],
  });

  const { writeAsync } = useContractWrite({
    abi: DeployedContracts[31337].Tournament.abi,
    address: params.addr,
    functionName: "unstakeLPToken",
  });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Withdraw from the pool</span>
            <span className="block text-4xl font-bold">and get your rewards</span>
          </h1>
          <p className="text-center text-lg">
            {LPTokenAmountOfPlayer?.toString()} {LPTokenSymbol.isLoading ? "..." : LPTokenSymbol.data} and{" "}
            {rewardTokenAmountOfPlayer?.toString()} {rewardTokenSymbol.isLoading ? "..." : rewardTokenSymbol.data} can
            be withdrawn.
            <button className="btn btn-secondary" onClick={() => writeAsync()}>
              Unstake and receive earned rewards
            </button>
          </p>
        </div>
      </div>
    </>
  );
};
