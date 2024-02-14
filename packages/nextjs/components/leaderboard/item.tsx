// import { formatUnits } from "viem";
import { useContractRead } from "wagmi";
import { useAccount } from "wagmi";
import { SparklesIcon, UserIcon } from "@heroicons/react/24/outline";
import { TrophyIcon } from "@heroicons/react/24/solid";
import { Address } from "~~/components/scaffold-eth";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Item = ({ tournament, player, score }: { tournament: string; player: string; score: number }) => {
  const connectedAddress: string = useAccount()?.address ?? "";
  const chainId = 5;

  const { data: playerRank, isLoading } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: tournament,
    functionName: "getRank",
    args: [player],
  });

  if (playerRank == undefined || isLoading) {
    return <></>;
  }

  let trophyColor = "h-4 w-4 mr-1";
  if (playerRank[0] == 1) {
    trophyColor += " text-yellow-400";
  } else if (playerRank[0] == 2) {
    trophyColor += " text-gray-300";
  } else if (playerRank[0] == 3) {
    trophyColor += " text-yellow-700";
  } else {
    trophyColor += " text-gray-600";
  }

  return (
    <>
      <li key={player} className="grid grid-cols-3 justify-items-start flex px-5 py-5 bg-base-100 rounded-3xl">
        <div className="flex items-center justify-self-start">
          <TrophyIcon className={trophyColor} /> {playerRank[0].toString()}
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
