import { Tournaments } from "./list";

export const Item = ({ tournament }: { tournament: Tournaments }) => {
  return (
    <li key={tournament.id} className="flex justify-between gap-x-6 py-5">
      <div className="flex min-w-0 gap-x-4">
        <div className="min-w-0 flex-auto">
          <p className="text-sm font-semibold leading-6 text-gray-900">{tournament.name}</p>
          <p className="mt-1 truncate text-xs leading-5 text-gray-500">{tournament.LPTokenSymbol}</p>
        </div>
      </div>
      <div className="hidden shrink-0 sm:flex sm:flex-col sm:items-end">
        <p className="text-sm leading-6 text-gray-900">Reward: {tournament.rewardTokenSymbol}</p>
        <p className="mt-1 text-xs leading-5 text-gray-500">
          Open until <time dateTime={tournament.endTime.toString()}>{tournament.endTime.toString()}</time>
        </p>
      </div>
    </li>
  );
};
