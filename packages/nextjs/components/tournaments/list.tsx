import { Item } from "./item";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

export const List = () => {
  const { data: activeTournaments, isLoading: isActiveTournamentsLoading } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "getAllActiveTournaments",
  });

  const { data: futureTournaments, isLoading: isFutureTournamentsLoading } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "getAllFutureTournaments",
  });

  const { data: pastTournaments, isLoading: isPastTournamentsLoading } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "getAllPastTournaments",
  });

  if (isActiveTournamentsLoading || isFutureTournamentsLoading || isPastTournamentsLoading) {
    return <div className="flex justify-center items-center mt-10">Loading...</div>;
  }

  console.log(activeTournaments);

  return (
    <>
      {activeTournaments?.length === 0 ? (
        <div className="flex justify-center items-center mt-10">
          <div
            className="flex items-center p-4 mb-4 text-sm text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400"
            role="alert"
          >
            <InformationCircleIcon className="w-5 h-5 mr-2" />
            <span className="sr-only">Info</span>
            <div>
              <span className="font-medium">Error!</span> No tournament found.
            </div>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-4 place-content-start space-y-6 gap-6">
          <div className="flex col-span-1 justify-end mt-10">Active Tournaments</div>
          <ul role="list" className="space-y-4 col-span-3">
            {activeTournaments?.map(addr => (
              <Item tournament={addr} key={addr} />
            ))}
          </ul>
          <div className="flex col-span-1 justify-end mt-10">Future Tournaments</div>
          <ul role="list" className="space-y-4 col-span-3">
            {futureTournaments?.map(addr => (
              <Item tournament={addr} key={addr} />
            ))}
          </ul>
          <div className="flex col-span-1 justify-end mt-10">Past Tournaments</div>
          <ul role="list" className="space-y-4 col-span-3">
            {pastTournaments?.map(addr => (
              <Item tournament={addr} key={addr} />
            ))}
          </ul>
        </div>
      )}
    </>
  );
};
