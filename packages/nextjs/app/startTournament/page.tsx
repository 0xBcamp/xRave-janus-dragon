// import Link from "next/link";
import type { NextPage } from "next";

//import { useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

/**
 * @todo add buttons
 */

const StartTournament: NextPage = () => {
  //   // check if there is a tournament available to join
  //   const { data: activeTournaments } = useScaffoldContractRead({
  //     contractName: "TournamnetFactory",
  //     functionName: "getActiveTournaments",
  //   });

  //   // join a tournament
  //   const { data: tournamentId } = useScaffoldContractWrite({
  //     contractName: "TouramentFactory",
  //     functionName: "joinTournament",
  //   });

  //   // starts a new game
  //   const { data: tournament } = useScaffoldContractWrite({
  //     contractName: "TournamentFactory",
  //     functionName: "createTournament",
  //   });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Start A Tournament</span>
          </h1>
          <p>Join a Tournament</p>
          <p>Start a Tournament</p>
        </div>
      </div>
    </>
  );
};

export default StartTournament;
