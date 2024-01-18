"use client";

import type { NextPage } from "next";
import { useSignMessage } from "wagmi";

const Play: NextPage = () => {
  const { signMessage } = useSignMessage();

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Play your next move</span>
            <span className="block text-4xl font-bold">in the tournament</span>
          </h1>
          <button className="btn btn-secondary" onClick={() => signMessage({ message: "ROCK" })}>
            Rock
          </button>
          <button className="btn btn-secondary" onClick={() => signMessage({ message: "PAPER" })}>
            Paper
          </button>
          <button className="btn btn-secondary" onClick={() => signMessage({ message: "SCISSORS" })}>
            Scissors
          </button>
        </div>
      </div>
    </>
  );
};

export default Play;
