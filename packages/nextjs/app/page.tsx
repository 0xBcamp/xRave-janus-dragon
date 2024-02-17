import Link from "next/link";
import type { NextPage } from "next";
import { GlobeAsiaAustraliaIcon, PaperAirplaneIcon, ScissorsIcon } from "@heroicons/react/24/outline";

const Home: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Welcome to</span>
            <span className="block text-4xl font-bold">DeFi Conquest</span>
            <span className="block text-4xl font-bold">A No-loss DeFi game</span>
            {/* Add in some text or taglinse and images about Rock Paper Scissors or The LP or something */}
          </h1>
        </div>

        <div className="flex-grow bg-base-300 w-full mt-16 px-8 py-12">
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <div className="flex flex-1 flex-col bg-base-100 px-10 py-10 text-center items-center min-w-[300px] sm:min-w-[200px] md:min-w-[250px] lg:min-w-[300px] xl:min-w-[350px] rounded-3xl">
              <GlobeAsiaAustraliaIcon className="h-8 w-8 fill-secondary" />
              <p>
                {/* <Link href="/debug" passHref className="link"> */}
                About
                {/* </Link>{" "} */}
              </p>
            </div>
            <div className="flex flex-1 flex-col bg-base-100 px-10 py-10 text-center items-center min-w-[300px] sm:min-w-[200px] md:min-w-[250px] lg:min-w-[300px] xl:min-w-[350px] rounded-3xl">
              <PaperAirplaneIcon className="h-8 w-8 fill-secondary" />
              <p>
                <Link href="/start" passHref className="link">
                  PLAY
                </Link>{" "}
              </p>
            </div>
            <div className="flex flex-1 flex-col bg-base-100 px-10 py-10 text-center items-center min-w-[300px] sm:min-w-[200px] md:min-w-[250px] lg:min-w-[300px] xl:min-w-[350px] rounded-3xl">
              <ScissorsIcon className="h-8 w-8 fill-secondary" />
              <p>
                {/* <Link href="/blockexplorer" passHref className="link"> */}
                LEADERBOARD
                {/* </Link>{" "} */}
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
