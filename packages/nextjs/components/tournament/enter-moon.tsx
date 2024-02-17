import { useState } from "react";
import Link from "next/link";
import { useMoonSDK } from "../../hooks/moon";
import { useMoonWalletContext } from "../ScaffoldEthAppWithProviders";
//import { ethers } from 'ethers';
import { formatUnits } from "viem";
import { erc20ABI, useAccount, useContractEvent, useContractRead } from "wagmi";
import DeployedContracts from "~~/contracts/deployedContracts";
import { useMoonEthers } from "~~/hooks/ethers";

//import { useTransactor } from "~~/hooks/scaffold-eth";

export const EnterMoon = ({ tournament }: { tournament: string }) => {
  // const writeTx = useTransactor();
  // const { address } = useAccount();
  const connectedAddress: string = useAccount()?.address ?? "";
  const { moonWallet } = useMoonWalletContext();
  const account = connectedAddress || moonWallet;
  const chainId = 80001;
  const [approved, setApproved] = useState(false);
  const { moon, contractCall } = useMoonSDK();

  const { data: tournamentData } = useContractRead({
    abi: DeployedContracts[chainId].Tournament.abi,
    address: tournament,
    functionName: "getTournament",
  });

  let spender = "";
  let LPaddr = "";
  let amount = 0;
  let decimals = 18;
  let LPTokenSymbol = "";
  let protocol = 0;
  let tokens: string[] = [];

  if (tournamentData != undefined) {
    spender = tournamentData[1];
    LPaddr = tournamentData[2];
    LPTokenSymbol = tournamentData[3];
    amount = Number(tournamentData[7]);
    decimals = Number(tournamentData[8]);
    protocol = Number(tournamentData[4]);
    tokens = [tournamentData[5], tournamentData[6]];
  }

  const { data: balance } = useContractRead({
    abi: erc20ABI,
    address: LPaddr,
    functionName: "balanceOf",
    args: [account],
  });

  const { data: allowance } = useContractRead({
    abi: erc20ABI,
    address: LPaddr,
    functionName: "allowance",
    args: [account, spender],
  });

  console.log(allowance);
  if (allowance != undefined && Number(allowance) >= amount && !approved) {
    setApproved(true);
  }

  const { moonProvider } = useMoonEthers();
  const { ethereum } = window as any;

  // const contractLP = new ethers.Contract(
  //   LPaddr,
  //   erc20ABI,
  //   moonProvider || undefined
  // );

  const signTransaction = async () => {
    if (!moon) {
      throw new Error("Moon SDK is not initialized");
    }
    await contractCall(moonWallet, LPaddr, erc20ABI as any, "approve", [spender, amount]);
    // const raw_tx = await moon.getAccountsSDK().signTransaction(account, {
    //   to: LPaddr,
    //   data: "",
    //   gasPrice: "1000000000",
    //   gas: "200000",
    //   nonce: "0",
    //   chain_id: chainId.toString(),
    //   encoding: "utf-8",
    //   value: "1",
    // });
    // const kek = (raw_tx.data.data as Transaction)?.transactions?.at(0)?.raw_transaction;
    // console.log(kek);
    // const tx = await moon.getAccountsSDK().broadcastTx(account, {
    //   chainId: chainId.toString(),
    //   rawTransaction: "",
    // });

    // console.log(tx);
    return "";
  };

  const handleApprove = async () => {
    if (!ethereum) {
      return;
    }
    if (!moonProvider) {
      return;
    }
    try {
      await signTransaction();
      // const approve = await contractLP.populateTransaction.approve(
      //   spender,
      //   BigInt(amount)
      // );
      // await moonProvider.sendTransaction(approve);
      // sign transaction
      // const signedTx = await ethereum.request({
      //   method: 'eth_sendTransaction',
      //   params: [approve],
      // });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  // const { writeAsync: deposit } = useContractWrite({
  //   abi: DeployedContracts[chainId].Tournament.abi,
  //   address: spender,
  //   functionName: "stakeLPToken",
  // });

  const handleDeposit = async () => {
    try {
      //await writeTx(deposit, { blockConfirmations: 1 });
      await contractCall(moonWallet, spender, DeployedContracts[chainId].Tournament.abi as any, "stakeLPToken", []);
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  useContractEvent({
    address: LPaddr,
    abi: erc20ABI,
    eventName: "Approval",
    listener: log => {
      if (
        log[0].args.owner == account &&
        spender == log[0].args.spender &&
        (log[0].args.value || 0n) >= BigInt(amount)
      ) {
        setApproved(true);
      }
    },
  });

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Enter the tournament</span>
            <span className="block text-4xl font-bold">
              by staking your {protocol == 0 ? "Uniswap" : "Yearn"} LP tokens
            </span>
          </h1>
          <div>
            You hold {formatUnits(balance || 0n, decimals || 18) || "-?-"} {LPTokenSymbol}
            <br />
            {protocol == 0 ? (
              <Link href={`https://app.uniswap.org/add/${tokens[0]}/${tokens[1]}`}>Obtain more LP</Link>
            ) : (
              <Link href={`https://yearn.fi/vaults/10/${LPaddr}`}>Obtain more LP</Link>
            )}
            <div className="flex justify-center rounded-md shadow-sm space-x-4 mt-5" role="group">
              <button className="btn btn-secondary" disabled={approved} onClick={() => handleApprove()}>
                Approve {LPTokenSymbol}
              </button>
              <button className="btn btn-secondary" disabled={!approved} onClick={() => handleDeposit()}>
                Deposit {formatUnits(BigInt(amount) || 0n, decimals || 18).toString()} {LPTokenSymbol}
              </button>
            </div>
            <div>
              To enter the tournament, you need to stake the required amount of LP token for its entire duration.
              <br />
              The value accrued by the LP token from deposit to wtihdrawal is used to increase the prize pool.
              <br />
              At the end of the tournament, you&apos;ll be able to withdraw the same value you deposited + game earnings
              based on rank.
              <br />
              <br />
              Simple exemple: <br />
              You deposit 1 LP token worth 1 ETH.
              <br />
              During the tournament, the LP token increase in value and by the end of the tournament, 1 LP is now worth
              1.1 ETH.
              <br />
              You get back 0.91 LP = 1 ETH plus your game earnings.
              <br />
              The remaining 0.09 LP are pooled together into the pool prize.
              <br />
              <br />
              Protocol fee on deposit/withdrawal: 0%
              <br />
              Protocol fee on prize: 10%
            </div>
          </div>
        </div>
      </div>
    </>
  );
};
