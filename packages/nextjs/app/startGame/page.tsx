// import Link from "next/link";
import type { NextPage } from "next";

//import { useScaffoldContractRead, useScaffoldContractWrite } from "~~/hooks/scaffold-eth";

/**
 *
 * @todo
 */

const StartGame: NextPage = () => {
  //   // check if there is a game available to join
  //   const { data: activeGames } = useScaffoldContractRead({
  //     contractName: "Game",
  //     functionName: "activeGames",
  //   });

  //   // join a game
  //   const { data: gameId } = useScaffoldContractWrite({
  //     contractName: "Game",
  //     functionName: "joinGame",
  //   });

  //   // starts a new game
  //   const { data: gameParams } = useScaffoldContractWrite({
  //     contractName: "GameFactory",
  //     functionName: "startGame",
  //   });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Single Player</span>
          </h1>
          <button>Join a Game</button>
          <p>Start a Game</p>
        </div>
      </div>
    </>
  );
};

export default StartGame;
