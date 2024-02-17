// import { formatUnits } from "viem";
import { Item } from "./item";
import { useContractRead } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Rank = ({ tournament, score }: { tournament: string; score: number }) => {
  const chainId = 80001;

  const { data: players, isLoading } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: tournament,
    functionName: "getPlayersAtScore",
    args: [score],
  });

  console.log(players);

  if (players == undefined || isLoading) {
    return <></>;
  }

  const list = [];
  for (let i = 0; i < players.length; i++) {
    list.push(
      <>
        <Item tournament={tournament} player={players[i]} score={score} key={i} />
      </>,
    );
  }

  return list;
};
