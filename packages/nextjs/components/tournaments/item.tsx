import Link from "next/link";
// import { formatUnits } from "viem";
import { useContractRead } from "wagmi";
import { ClockIcon, CurrencyDollarIcon, StarIcon } from "@heroicons/react/24/outline";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Item = ({ tournament }: { tournament: string }) => {
  const { data: tournamentData, isLoading: isLoading } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  if (isLoading || tournamentData == undefined) {
    return <div>Loading...</div>;
  }

  const [name, , , LPTokenSymbol, , startTime, endTime] = tournamentData;

  console.log(tournamentData);

  if (endTime < Date.now() / 1000) {
    return (
      <li key={tournament} className="flex justify-between gap-x-6 py-5">
        <div className="flex min-w-0 gap-x-4">
          <div className="min-w-0 flex-auto">
            <p className="text-sm font-semibold leading-6 text-gray-900">{name}</p>
            <p className="mt-1 truncate text-xs leading-5 text-gray-500">
              <CurrencyDollarIcon className="h-4 w-4 fill-secondary" />
              {LPTokenSymbol}
            </p>
          </div>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <p className="text-sm leading-6 text-gray-900">
            Ended on {new Date(Number(endTime) * 1000).toLocaleString()}
          </p>
        </div>
      </li>
    );
  }

  if (startTime > Date.now() / 1000) {
    return (
      <li key={tournament} className="flex justify-between gap-x-6 py-5">
        <div className="flex min-w-0 gap-x-4">
          <div className="min-w-0 flex-auto">
            <p className="text-sm font-semibold leading-6 text-gray-900">{name}</p>
            <p className="mt-1 truncate text-xs leading-5 text-gray-500">
              <CurrencyDollarIcon className="h-4 w-4 fill-secondary" />
              {LPTokenSymbol}
            </p>
          </div>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <p className="text-sm leading-6 text-gray-900">
            Will open on {new Date(Number(startTime) * 1000).toLocaleString()}
          </p>
        </div>
      </li>
    );
  }

  return (
    <li key={tournament} className="flex justify-between gap-x-6 py-5">
      <div className="flex min-w-0 gap-x-4">
        <div className="min-w-0 flex-auto">
          <p className="text-sm font-semibold leading-6 text-gray-900">
            <Link href={`/tournament/${tournament}`}>{name}</Link>
          </p>
          <div>
            <CurrencyDollarIcon className="h-4 w-4" />
            <span className="mt-1 truncate text-xs leading-5 text-gray-500">{LPTokenSymbol}</span>
          </div>
        </div>
      </div>
      <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
        <p className="text-sm leading-6 text-gray-900">
          <Link href={`/leaderboard/${tournament}`}>
            <StarIcon className="h-4 w-4" /> Leaderboard
          </Link>
        </p>
        <p className="mt-1 text-xs leading-5 text-gray-500">
          <ClockIcon className="h-4 w-4" />
          Open until <time dateTime={endTime.toString()}>{new Date(Number(endTime) * 1000).toLocaleString()}</time>
        </p>
      </div>
    </li>
  );
};
