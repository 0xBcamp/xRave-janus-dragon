import { useEffect, useState } from "react";
import { Spinner } from "../Spinner";
import { Item } from "./item";
import { useAccount } from "wagmi";
import { useScaffoldContract, useScaffoldContractRead } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";

export interface Tournaments {
  id: number;
  name: string;
  LPTokenSymbol: string;
  rewardTokenSymbol: string;
  endTime: bigint;
}

export const List = () => {
  const { address: connectedAddress } = useAccount();
  const [activeList, setActiveList] = useState<Tournaments[]>([]);
  const [listLoading, setListLoading] = useState(false);

  const { data: TournamentFactory } = useScaffoldContract({
    contractName: "TournamentFactory",
  });

  const { data: activeTournaments } = useScaffoldContractRead({
    contractName: "TournamentFactory",
    functionName: "getAllActiveTournaments",
  });

  useEffect(() => {
    const updateList = async (): Promise<void> => {
      if (activeTournaments === undefined || TournamentFactory === undefined || connectedAddress === undefined) return;

      setListLoading(true);
      const listUpdate: Tournaments[] = [];
      for (let id = 0; id < activeTournaments.length; id++) {
        try {
          const tournamentData: any = await TournamentFactory.read.getTournament([BigInt(id)]);

          listUpdate.push({
            id: id,
            name: tournamentData.name,
            LPTokenSymbol: tournamentData.LPTokenSymbol,
            rewardTokenSymbol: tournamentData.rewardTokenSymbol,
            endTime: tournamentData.endTime,
          });
        } catch (e) {
          notification.error("Error fetching tournaments");
          setListLoading(false);
          console.log(e);
        }
      }
      listUpdate.sort((a, b) => a.id - b.id);
      setActiveList(listUpdate);
      setListLoading(false);
    };

    updateList();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [connectedAddress, activeTournaments]);

  if (listLoading)
    return (
      <div className="flex justify-center items-center mt-10">
        <Spinner width="75" height="75" />
      </div>
    );

  return (
    <>
      {activeList.length === 0 ? (
        <div className="flex justify-center items-center mt-10">
          <div className="text-2xl text-primary-content">No tournaments found</div>
        </div>
      ) : (
        <ul role="list" className="divide-y divide-gray-100">
          {activeList.map(tid => (
            <Item tournament={tid} key={tid.id} />
          ))}
        </ul>
      )}
    </>
  );
};
