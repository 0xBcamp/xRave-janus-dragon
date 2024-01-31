// import Link from "next/link";
import type { NextPage } from "next";

//import { GlobeAsiaAustraliaIcon, PaperAirplaneIcon, ScissorsIcon } from "@heroicons/react/24/outline";
//import { MetaHeader } from "~~/components/MetaHeader";

/**
 *
 * @dev need to check if user has lives left & deposited tokens
 */

const Start: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Choose Your Path</span>
            {/* Put Single / Tournament into boxes
                add links
                add short description of each format
             */}
            <span className="block text-4xl font-bold">Single Game</span>
            <span className="block text-4xl font-bold">Tournament</span>
          </h1>
        </div>
      </div>
    </>
  );
};

export default Start;
