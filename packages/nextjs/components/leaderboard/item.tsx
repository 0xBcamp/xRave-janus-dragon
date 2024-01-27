// import { formatUnits } from "viem";
// import { useContractRead } from "wagmi";
// import DeployedContracts from "~~/contracts/deployedContracts";
import { useAccount } from "wagmi";
import { UserIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";

export const Item = ({ /*tournament,*/ player, score }: { /*tournament: string,*/ player: string; score: number }) => {
  //   const { data: playerData } = useContractRead({
  //     abi: DeployedContracts[31337].Tournament.abi,
  //     address: tournament,
  //     functionName: "player",
  //     args: [player],
  //   });

  //   console.log(playerData);

  //   if(playerData == undefined) {
  //     return <></>;
  //   }
  const connectedAddress: string = useAccount()?.address ?? "";

  return (
    <>
      <li key={player} className="flex justify-between gap-x-6 px-5 py-2 bg-base-100 rounded-3xl">
        <div className="flex min-w-0 gap-x-4">
          <div className="min-w-0 flex-auto">
            <p className="text-sm font-semibold leading-6">
              {player === connectedAddress ? (
                <div className="flex items-center">
                  <UserIcon className="h-6 w-6" />
                  You
                </div>
              ) : (
                <Address address={player} />
              )}
            </p>
            <p className="mt-1 truncate text-xs leading-5">Score: {score.toString()}</p>
          </div>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <p className="text-sm leading-6">Rank: ?</p>
        </div>
      </li>
    </>
  );
};
