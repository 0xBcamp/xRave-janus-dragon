import { Rank } from "./rank";

export const List = ({ tournament, topScore }: { tournament: string; topScore: number }) => {
  console.log(tournament);
  console.log(topScore);

  const list = [];
  for (let i = topScore; i > 0; i--) {
    console.log("Getting score", i);
    list.push(<Rank tournament={tournament} score={i} key={i} />);
  }

  return (
    <>
      <ul role="list" className="space-y-4">
        {list}
      </ul>
    </>
  );
};
