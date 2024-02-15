"use client";

import { useMoonWalletContext } from "../../components/ScaffoldEthAppWithProviders";
import { useMoonSDK } from "../../hooks/moon";
import { CreateAccountInput } from "@moonup/moon-api";
import type { NextPage } from "next";
import { Sign } from "~~/components/moon";

const Moon: NextPage = () => {
  const { moon, disconnect, listAccounts } = useMoonSDK();
  const { moonWallet, setMoonWallet } = useMoonWalletContext();

  const handleCreate = async () => {
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        return;
      }

      const data: CreateAccountInput = {};
      const message = await moon.getAccountsSDK().createAccount(data);
      //setMoonWallet(message.data.data.address);
      console.log(message);
    } catch (error) {
      console.error(error);
      //setAnswer(error.error.message);
    }
  };

  const handleList = async () => {
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        return;
      }

      const message = await listAccounts();
      console.log(message);
      if (message) {
        const res: any = message;
        setMoonWallet(res.data.keys[0]);
      }
    } catch (error) {
      console.error(error);
      //setAnswer(error.error.message);
    }
  };

  const handleSign = async () => {
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        return;
      }

      const message = await moon
        .getAccountsSDK()
        .signMessage(moonWallet, { data: "68656c6c6f20776f726c64000000000000000000000000000000000000000000" });
      console.log(message);
    } catch (error) {
      console.error(error);
      //setAnswer(error.error.message);
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

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Moon account page</span>
            <p>Authenticated Address: {moonWallet}</p>
          </h1>
          <div className="flex justify-center items-center gap-12 flex-col sm:flex-row">
            <Sign />
            <button className="btn btn-secondary" onClick={handleList}>
              List accounts
            </button>
            <button className="btn btn-secondary" onClick={handleCreate}>
              Create account
            </button>
            <button className="btn btn-secondary" onClick={handleSign}>
              Sign
            </button>
            <button className="btn btn-secondary" onClick={handleDisconnect}>
              Logout
            </button>
          </div>
        </div>
      </div>
    </>
  );
};

export default Moon;
