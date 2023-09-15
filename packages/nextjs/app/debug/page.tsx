
import type { Metadata, NextPage } from "next";
import DebugContracts from "./debugContracts";
import { generateMetadata } from "~~/utils/generateMetadata";


export const metadata:Metadata = generateMetadata({
  title: "Debug Contracts | Scaffold-ETH 2",
  description: "Debug your deployed 🏗 Scaffold-ETH 2 contracts in an easy way",
})


const Debug: NextPage = () => {

  return (
    <>
      <DebugContracts />
      <div className="text-center mt-8 bg-secondary p-10">
        <h1 className="text-4xl my-0">Debug Contracts</h1>
        <p className="text-neutral">
          You can debug & interact with your deployed contracts here.
          <br /> Check{" "}
          <code className="italic bg-base-300 text-base font-bold [word-spacing:-0.5rem] px-1">
            packages / nextjs / pages / debug.tsx
          </code>{" "}
        </p>
      </div>
    </>
  );
};

export default Debug;
