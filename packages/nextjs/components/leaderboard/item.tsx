// import { formatUnits } from "viem";
import { useContractRead } from "wagmi";
import { useAccount } from "wagmi";
import { SparklesIcon, TrophyIcon, UserIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Item = ({ tournament, player, score }: { tournament: string; player: string; score: number }) => {
  const connectedAddress: string = useAccount()?.address ?? "";

  const { data: playerRank } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getRank",
    args: [player],
  });

  if (playerRank == undefined) {
    return <></>;
  }

  return (
    <>
      <li key={player} className="grid grid-cols-3 justify-items-start flex px-5 py-5 bg-base-100 rounded-3xl">
        <div className="flex items-center justify-self-start">
          <TrophyIcon className="h-4 w-4 mr-1" /> {playerRank[0].toString()}
        </div>
        {player === connectedAddress ? (
          <div className="flex items-center">
            <UserIcon className="h-6 w-6 mr-1" />
            You
          </div>
        ) : (
          <Address address={player} />
        )}
        <div className="justify-self-end flex items-center">
          {score.toString()}
          <SparklesIcon className="h-4 w-4 ml-1" />
        </div>
      </li>
    </>
  );
};
