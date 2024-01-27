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
      <li key={tournament} className="flex justify-between gap-x-6 px-5 py-5 bg-base-100 rounded-3xl">
        <div className="flex min-w-0 gap-x-4">
          <div className="min-w-0 flex-auto">
            <p className="text-sm font-semibold leading-6">{name}</p>
            <div className="flex items-center">
              <CurrencyDollarIcon className="h-4 w-4 mr-1" />
              {LPTokenSymbol}
            </div>
          </div>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <div className="flex items-center">
            <StarIcon className="h-4 w-4 mr-1" />
            <Link href={`/leaderboard/${tournament}`}>Leaderboard</Link>
          </div>
          <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
            <div className="flex items-center">
              <ClockIcon className="h-4 w-4 mr-1" />
              <span>Ended on {new Date(Number(endTime) * 1000).toLocaleString()}</span>
            </div>
          </div>
        </div>
      </li>
    );
  }

  if (startTime > Date.now() / 1000) {
    return (
      <li key={tournament} className="flex justify-between gap-x-6 px-5 py-5 bg-base-100 rounded-3xl">
        <div className="flex min-w-0 gap-x-4">
          <div className="min-w-0 flex-auto">
            <p className="text-sm font-semibold leading-6">
              <Link href={`/tournament/${tournament}`}>{name}</Link>
            </p>
            <div className="flex items-center">
              <CurrencyDollarIcon className="h-4 w-4 mr-1" />
              {LPTokenSymbol}
            </div>
          </div>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <div className="flex items-center">
            <ClockIcon className="h-4 w-4 mr-1" />
            <span>Will open on {new Date(Number(startTime) * 1000).toLocaleString()}</span>
          </div>
        </div>
      </li>
    );
  }

  return (
    <li key={tournament} className="flex justify-between gap-x-6 px-5 py-5 bg-base-100 rounded-3xl">
      <div className="flex min-w-0 gap-x-4">
        <div className="min-w-0 flex-auto">
          <p className="text-sm font-semibold leading-6">
            <Link href={`/tournament/${tournament}`}>{name}</Link>
          </p>
          <div className="flex items-center">
            <CurrencyDollarIcon className="h-4 w-4 mr-1" />
            {LPTokenSymbol}
          </div>
        </div>
      </div>
      <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
        <div className="flex items-center">
          <StarIcon className="h-4 w-4 mr-1" />
          <Link href={`/leaderboard/${tournament}`}>Leaderboard</Link>
        </div>
        <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
          <div className="flex items-center">
            <ClockIcon className="h-4 w-4 mr-1" />
            <span>
              Open until <time dateTime={endTime.toString()}>{new Date(Number(endTime) * 1000).toLocaleString()}</time>
            </span>
          </div>
        </div>
      </div>
    </li>
  );
};
