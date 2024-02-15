import { useEffect, useState } from "react";
import { AccountResponse } from "@moonup/moon-api";
import { MoonSDK } from "@moonup/moon-sdk";
import { AUTH, MOON_SESSION_KEY, Storage } from "@moonup/moon-types";

//import { CreateAccountInput } from "@moonup/moon-api";

interface MoonSDKHook {
  moon: MoonSDK | null;
  initialize: () => Promise<void>;
  connect: () => Promise<void>;
  disconnect: () => Promise<void>;
  //createAccount: () => Promise<AccountResponse | undefined>;
  listAccounts: () => Promise<AccountResponse | undefined>;
  signMessage: (msg: string) => Promise<string | undefined>;
  updateToken: (token: string) => Promise<void>;
  updateRefreshToken: (token: string) => Promise<void>;
  // signTransaction: (transaction: TransactionResponse) => Promise<Transaction>;
  // Add other methods as needed
}

export function useMoonSDK(): MoonSDKHook {
  const [moon, setMoon] = useState<MoonSDK | null>(null);

  const initialize = async () => {
    const moonInstance = new MoonSDK({
      Storage: {
        key: MOON_SESSION_KEY,
        type: Storage.SESSION,
      },
      Auth: {
        AuthType: AUTH.JWT,
      },
    });
    setMoon(moonInstance);
    moonInstance.connect();
  };

  const connect = async () => {
    if (moon) {
      await moon.connect();
    }
  };
  const disconnect = async () => {
    if (moon) {
      await moon.disconnect();
      setMoon(null);
    }
  };
  // const createAccount = async () => {
  // 	if (moon) {
  // 		const data: CreateAccountInput = {};
  // 		const newAccount = await moon?.getAccountsSDK().createAccount(data);
  // 		return newAccount;
  // 	}
  // };
  const listAccounts = async () => {
    if (moon) {
      return moon.listAccounts();
    }
  };
  const signMessage = async (msg: string) => {
    if (moon) {
      return moon.SignMessage(msg);
    }
  };
  const updateToken = async (token: string) => {
    if (moon) {
      return moon.updateToken(token);
    }
  };
  const updateRefreshToken = async (token: string) => {
    if (moon) {
      return moon.updateRefreshToken(token);
    }
  };

  // const signTransaction = async (transaction: TransactionResponse) => {
  // 	if (moon) {
  // 		return moon.SignTransaction(transaction);
  // 	}
  // 	throw new Error('Moon SDK is not initialized');
  // };

  // Add other methods as needed

  useEffect(() => {
    initialize();
  }, []);

  return {
    moon,
    initialize,
    connect,
    disconnect,
    //createAccount,
    listAccounts,
    signMessage,
    updateToken,
    updateRefreshToken,
    // Add other methods as needed
  };
}
