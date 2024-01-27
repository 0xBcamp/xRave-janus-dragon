import { Item } from "./item";
import { useScaffoldContractRead } from "~~/hooks/scaffold-eth";

export const List = () => {
  const { data: activeTournaments, isLoading: isTournamentsLoading } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "getAllActiveTournaments",
  });

  if (isTournamentsLoading) {
    return <div>Loading...</div>;
  }

  console.log(activeTournaments);

  return (
    <>
      {activeTournaments?.length === 0 ? (
        <div className="flex justify-center items-center mt-10">
          <div className="text-2xl text-primary-content">No tournaments found</div>
        </div>
      ) : (
        <ul role="list" className="divide-y divide-gray-100">
          {activeTournaments?.map(addr => (
            <Item tournament={addr} key={addr} />
          ))}
        </ul>
      )}
    </>
  );
};
