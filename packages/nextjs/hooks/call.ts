import { Transaction } from "@moonup/moon-api";
import { MoonSDK } from "@moonup/moon-sdk";
import { encodeFunctionData } from "viem";

interface CallProps {
  moon: MoonSDK | null;
  moonWallet: string;
  contract: string;
  abi: any;
  function: string;
  args: any;
}

export async function useCall(props: CallProps): Promise<void> {
  if (!props.moon) {
    console.error("User not authenticated");
    return;
  }

  // Define a type guard function to check if an object conforms to the Transaction interface
  function isTransaction(obj: any): obj is Transaction {
    return (
      obj && typeof obj.userop_transaction === "string" && Array.isArray(obj.transactions)
      // Add more checks for other properties if necessary
    );
  }

  const encodedData = encodeFunctionData({
    abi: props.abi,
    functionName: props.function,
    args: props.args,
  });

  const data = {
    to: props.contract,
    data: encodedData,
    chain_id: "80001",
    encoding: "utf-8",
  };

  const rawTx = await props.moon.getAccountsSDK().signTransaction(props.moonWallet, data);

  console.log(rawTx);
  if (isTransaction(rawTx.data.data)) {
    const res: Transaction = rawTx.data.data;
    if (res.transactions) {
      const raw = res.transactions[0].raw_transaction || "";
      const tx = await props.moon.getAccountsSDK().broadcastTx(props.moonWallet, {
        chainId: "80001",
        rawTransaction: raw,
      });
      console.log(tx);
    }
  }
}
