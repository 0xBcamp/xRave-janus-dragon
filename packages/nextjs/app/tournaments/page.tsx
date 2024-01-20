"use client";

import type { NextPage } from "next";
// import { useAccount } from "wagmi";
// import { useScaffoldContract, useScaffoldContractRead } from "~~/hooks/scaffold-eth";
import { List } from "~~/components/tournament";

const Tournaments: NextPage = () => {
  // const { address: connectedAddress } = useAccount();

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">List of tournaments</span>
            <span className="block text-4xl font-bold">active</span>
          </h1>
          <List />
        </div>
      </div>
    </>
  );
};

export default Tournaments;
