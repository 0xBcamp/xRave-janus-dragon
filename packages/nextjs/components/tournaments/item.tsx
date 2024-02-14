import Link from "next/link";
import { formatUnits } from "viem";
// import { formatUnits } from "viem";
import { useContractRead } from "wagmi";
import { ClockIcon, CurrencyDollarIcon, GiftIcon, TrophyIcon, UserCircleIcon } from "@heroicons/react/24/outline";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Item = ({ tournament, player }: { tournament: string; player: boolean }) => {
  const chainId = 5;

  const { data: tournamentData, isLoading: isLoading } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  if (isLoading || tournamentData == undefined) {
    return <div>Loading...</div>;
  }

  const [name, , , LPTokenSymbol, , , , , decimals, startTime, endTime, players, prize] = tournamentData;

  console.log(tournamentData);

  let tmp = new Date();
  const today = new Date(tmp.getFullYear(), tmp.getMonth(), tmp.getDate());
  tmp = new Date(Number(startTime) * 1000);
  const start = new Date(tmp.getFullYear(), tmp.getMonth(), tmp.getDate());
  tmp = new Date(Number(endTime) * 1000);
  const end = new Date(tmp.getFullYear(), tmp.getMonth(), tmp.getDate());

  if (end < today) {
    // Ended
    return (
      <li key={tournament} className="flex justify-between gap-x-6 px-5 py-5 bg-base-100 rounded-3xl">
        <div className="flex">
          <p className="font-semibold">{name}</p>
        </div>
        <div className="flex items-center">
          <CurrencyDollarIcon className="h-4 w-4 mr-1" />
          {LPTokenSymbol}
        </div>
        <div className="flex items-center">
          <UserCircleIcon className="h-4 w-4 mr-1" />
          {player ? "You + " + (Number(players) - 1).toString() : players.toString()}
        </div>
        <div className="flex items-center">
          <GiftIcon className="h-4 w-4 mr-1" />
          {Number(formatUnits(prize, decimals)).toFixed(2)}
        </div>
        <div className="flex items-center">
          <TrophyIcon className="h-4 w-4 mr-1" />
          <Link href={`/leaderboard/${tournament}`}>Leaderboard</Link>
        </div>
        <div className="flex items-center">
          <ClockIcon className="h-4 w-4 mr-1" />
          Ended on {new Date(Number(endTime) * 1000).toLocaleDateString()}
        </div>
      </li>
    );
  }

  if (start > today) {
    // Not started
    return (
      <li key={tournament} className="flex justify-between gap-x-6 px-5 py-5 bg-base-100 rounded-3xl">
        <div className="flex">
          <p className="font-semibold">
            <Link href={`/tournament/${tournament}`}>{name}</Link>
          </p>
        </div>
        <div className="flex items-center">
          <CurrencyDollarIcon className="h-4 w-4 mr-1" />
          {LPTokenSymbol}
        </div>
        <div className="flex items-center">
          <UserCircleIcon className="h-4 w-4 mr-1" />
          {player ? "You + " + (Number(players) - 1).toString() : players.toString()}
        </div>
        <div className="flex items-center">
          <GiftIcon className="h-4 w-4 mr-1" />
          {Number(formatUnits(prize, decimals)).toFixed(2)}
        </div>
        <div className="flex items-center"></div>
        <div className="flex items-center">
          <ClockIcon className="h-4 w-4 mr-1" />
          Will open on {new Date(Number(startTime) * 1000).toLocaleDateString()}
        </div>
      </li>
    );
  }

  // Active
  return (
    <li key={tournament} className="flex justify-between gap-x-6 px-5 py-5 bg-base-100 rounded-3xl">
      <div className="flex">
        <p className="font-semibold">
          <Link href={`/tournament/${tournament}`}>{name}</Link>
        </p>
      </div>
      <div className="flex items-center">
        <CurrencyDollarIcon className="h-4 w-4 mr-1" />
        {LPTokenSymbol}
      </div>
      <div className="flex items-center">
        <UserCircleIcon className="h-4 w-4 mr-1" />
        {player ? "You + " + (Number(players) - 1).toString() : players.toString()}
      </div>
      <div className="flex items-center">
        <GiftIcon className="h-4 w-4 mr-1" />
        {Number(formatUnits(prize, decimals)).toFixed(2)}
      </div>
      <div className="flex items-center">
        <TrophyIcon className="h-4 w-4 mr-1" />
        <Link href={`/leaderboard/${tournament}`}>Leaderboard</Link>
      </div>
      <div className="flex items-center">
        <ClockIcon className="h-4 w-4 mr-1" />
        Open until {new Date(Number(endTime) * 1000).toLocaleDateString()}
      </div>
    </li>
  );
};
