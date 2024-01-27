// import { formatUnits } from "viem";
// import { useContractRead } from "wagmi";
// import DeployedContracts from "~~/contracts/deployedContracts";
import { useAccount } from "wagmi";
import { UserIcon } from "@heroicons/react/24/outline";

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
      <li key={player} className="flex justify-between gap-x-6 py-5">
        <div className="flex min-w-0 gap-x-4">
          <div className="min-w-0 flex-auto">
            <p className="text-sm font-semibold leading-6 text-gray-900">
              <UserIcon className="h-4 w-4 fill-secondary" />
              {player === connectedAddress ? "You" : player}
            </p>
            <p className="mt-1 truncate text-xs leading-5 text-gray-500">Score: {score.toString()}</p>
          </div>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <p className="text-sm leading-6 text-gray-900">Rank: ?</p>
        </div>
      </li>
    </>
  );
};
