import { useEffect } from "react";
import Link from "next/link";
import { useMoonSDK } from "../../hooks/moon";
import { useMoonWalletContext } from "../ScaffoldEthAppWithProviders";
import { XMarkIcon } from "@heroicons/react/24/outline";

export const WalletButton = () => {
  const { moon, initialize, connect, disconnect, listAccounts } = useMoonSDK();
  const { moonWallet, setMoonWallet } = useMoonWalletContext();
  const getAccount = async () => {
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        return;
      }

      if (moonWallet != "") {
        return;
      }
      const message: any = await listAccounts();
      console.log(message);
      setMoonWallet(message.data.keys[0]);
    } catch (error) {
      console.error(error);
    }
  };

  const handleDisconnect = async () => {
    try {
      // Disconnect from Moon
      await disconnect();
      setMoonWallet("");
      console.log("Disconnected from Moon");
    } catch (error) {
      console.error("Error during disconnection:", error);
    }
  };

  // Use useEffect to initialize Moon SDK on component mount
  useEffect(() => {
    initialize();
    connect();

    getAccount();
    // Cleanup Moon SDK on component unmount
    return () => {
      disconnect();
    };
  }, []);

  return !moonWallet ? (
    <Link href="/moon">
      <button className="btn btn-primary btn-sm">Use Moon</button>
    </Link>
  ) : (
    <button className="btn btn-primary btn-sm" onClick={handleDisconnect}>
      {moonWallet.slice(0, 4) + "..." + moonWallet.slice(-4)}
      <XMarkIcon className="h-4 w-4" />
    </button>
  );
};
