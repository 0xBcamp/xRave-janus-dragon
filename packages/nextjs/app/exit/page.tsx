import type { NextPage } from "next";

const Exit: NextPage = () => {
  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Withdraw from the pool</span>
            <span className="block text-4xl font-bold">and get your rewards</span>
          </h1>
          <button className="btn btn-secondary">Withdraw</button>
        </div>
      </div>
    </>
  );
};

export default Exit;
