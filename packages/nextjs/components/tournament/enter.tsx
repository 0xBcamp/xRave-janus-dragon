import { formatUnits } from "viem";
import { useAccount, useContractRead, useContractWrite } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useTransactor } from "~~/hooks/scaffold-eth";

export const Enter = ({ tournament }: { tournament: string }) => {
  const writeTx = useTransactor();
  // const { address } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";

  const tournamentData = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  let spender = "";
  let LPaddr = "";
  let amount = 0;
  let LPTokenSymbol = "";

  if (tournamentData.data != undefined) {
    spender = tournamentData.data[1];
    LPaddr = tournamentData?.data[2];
    LPTokenSymbol = tournamentData?.data[4];
    amount = Number(tournamentData?.data[5]);
  }

  const { data: balance } = useContractRead({
    abi: DeployedContracts[31337].LPToken1.abi,
    address: LPaddr,
    functionName: "balanceOf",
    args: [connectedAddress],
  });

  const { data: decimals } = useContractRead({
    abi: DeployedContracts[31337].LPToken1.abi,
    address: LPaddr,
    functionName: "decimals",
  });

  const { writeAsync: approve } = useContractWrite({
    abi: DeployedContracts[31337].LPToken1.abi,
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
            <div className="inline-flex rounded-md shadow-sm" role="group">
              <button className="btn btn-secondary" onClick={() => approveToken()}>
                Approve {LPTokenSymbol}
              </button>
              <button className="btn btn-secondary" onClick={() => depositToken()}>
                Deposit {formatUnits(BigInt(amount) || 0n, decimals || 18).toString()} {LPTokenSymbol}
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};
