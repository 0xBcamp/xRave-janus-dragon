"use client";

import type { NextPage } from "next";
import { List } from "~~/components/tournaments";

const Tournaments: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">List of tournaments</span>
          </h1>
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <List />
          </div>
        </div>
      </div>
    </>
  );
};

export default Tournaments;
