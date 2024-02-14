import { useEffect, useState } from "react";
import { Item } from "./item";
import { MoonProvider } from "@moonup/ethers";
import { AUTH, MOON_SESSION_KEY, Storage } from "@moonup/moon-types";
import { ethers } from "ethers";
import { InformationCircleIcon } from "@heroicons/react/24/outline";
import DeployedContracts from "~~/contracts/deployedContracts";

export const List = () => {
  const [loaded, setLoaded] = useState(false);
  const [activeTournaments, setActiveTournaments] = useState([] as string[]);
  const [futureTournaments, setFutureTournaments] = useState([] as string[]);
  const [pastTournaments, setPastTournaments] = useState([] as string[]);
  const [playerTournaments, setPlayerTournaments] = useState([] as string[]);

  const provider = new MoonProvider({
    chainId: 31337,
    MoonSDKConfig: {
      Storage: {
        key: MOON_SESSION_KEY,
        type: Storage.SESSION,
      },
      Auth: {
        AuthType: AUTH.JWT,
      },
    },
  });

  const tournamentFactory = new ethers.Contract(
    DeployedContracts[31337].Tournament.address,
    DeployedContracts[31337].Tournament.abi,
    provider,
  );

  useEffect(() => {
    const getTournaments = async () => {
      setActiveTournaments(await tournamentFactory.getAllActiveTournaments());
      setFutureTournaments(await tournamentFactory.getAllFutureTournaments());
      setPastTournaments(await tournamentFactory.getAllPastTournaments());
      setPlayerTournaments(await tournamentFactory.getAllPlayerTournaments());
    };
    if (!loaded) {
      getTournaments();
      setLoaded(true);
    }
  }, []);

  if (!loaded) {
    return <div className="flex justify-center items-center mt-10">Loading...</div>;
  }

  console.log(activeTournaments);

  return (
    <>
      {activeTournaments?.length + futureTournaments?.length + pastTournaments?.length === 0 ? (
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
              <Item tournament={addr} key={addr} player={playerTournaments?.includes(addr) || false} />
            ))}
          </ul>
          <div className="flex col-span-1 justify-end mt-10">Future Tournaments</div>
          <ul role="list" className="space-y-4 col-span-3">
            {futureTournaments?.map(addr => (
              <Item tournament={addr} key={addr} player={playerTournaments?.includes(addr) || false} />
            ))}
          </ul>
          <div className="flex col-span-1 justify-end mt-10">Past Tournaments</div>
          <ul role="list" className="space-y-4 col-span-3">
            {pastTournaments?.map(addr => (
              <Item tournament={addr} key={addr} player={playerTournaments?.includes(addr) || false} />
            ))}
          </ul>
        </div>
      )}
    </>
  );
};
