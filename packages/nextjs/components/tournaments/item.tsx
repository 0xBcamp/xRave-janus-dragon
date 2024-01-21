import Link from "next/link";
import { useContractRead } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Item = ({ tournament }: { tournament: string }) => {
  const tournamentData = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  console.log(tournamentData);

  if (tournamentData.data == undefined) {
    return <></>;
  }

  return (
    <li key={tournament} className="flex justify-between gap-x-6 py-5">
      <div className="flex min-w-0 gap-x-4">
        <div className="min-w-0 flex-auto">
          <p className="text-sm font-semibold leading-6 text-gray-900">
            <Link href={`/tournament/${tournament}`}>{tournamentData.data[0]}</Link>
          </p>
          <p className="mt-1 truncate text-xs leading-5 text-gray-500">{tournamentData.data[4]}</p>
        </div>
      </div>
      <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
        <p className="text-sm leading-6 text-gray-900">
          Reward: {tournamentData.data[7].toString()} {tournamentData.data[6]}
        </p>
        <p className="mt-1 text-xs leading-5 text-gray-500">
          Open until <time dateTime={tournamentData.data[8].toString()}>{tournamentData.data[8].toString()}</time>
        </p>
      </div>
    </li>
  );
};
