import Link from "next/link";
// import { formatUnits } from "viem";
import { useContractRead } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Item = ({ tournament }: { tournament: string }) => {
  const { data: tournamentData } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  /*   let address = "";
  if (tournamentData != undefined) {
    address = tournamentData[2];
  }

  const { data: decimals } = useContractRead({
    abi: DeployedContracts[31337].LPToken1.abi,
    address: address,
    functionName: "decimals",
  }); */

  console.log(tournamentData);

  if (tournamentData == undefined) {
    return <></>;
  }

  return (
    <li key={tournament} className="flex justify-between gap-x-6 py-5">
      <div className="flex min-w-0 gap-x-4">
        <div className="min-w-0 flex-auto">
          <p className="text-sm font-semibold leading-6 text-gray-900">
            <Link href={`/tournament/${tournament}`}>{tournamentData[0]}</Link>
          </p>
          <p className="mt-1 truncate text-xs leading-5 text-gray-500">{tournamentData[3]}</p>
        </div>
      </div>
      <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
        <p className="text-sm leading-6 text-gray-900">Reward:</p>
        <p className="mt-1 text-xs leading-5 text-gray-500">
          Open until <time dateTime={tournamentData[6].toString()}>{tournamentData[6].toString()}</time>
        </p>
      </div>
    </li>
  );
};
