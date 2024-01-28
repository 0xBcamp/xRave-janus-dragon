// import { formatUnits } from "viem";
import { Item } from "./item";
import { useContractRead } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";

export const Rank = ({ tournament, score }: { tournament: string; score: number }) => {
  const { data: players } = useContractRead({
    abi: DeployedContracts[31337].Tournament.abi,
    address: tournament,
    functionName: "getPlayersAtScore",
    args: [BigInt(score)],
  });

  console.log(players);

  if (players == undefined) {
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
