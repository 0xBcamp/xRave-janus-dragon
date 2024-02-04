/// BCAMP EXAMPLE ///
import { useState } from "react";
import { CreateAccountInput } from "@moonup/moon-api";
import { MoonSDK } from "@moonup/moon-sdk";
import { AUTH, MOON_SESSION_KEY, Storage } from "@moonup/moon-types";
export const useMoonSDK = () => {
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
    moonInstance.login();
  };
  const connect = async () => {
    if (moon) {
      return moon.connect();
    }
  };
  const updateToken = async (token: string, refreshToken: string) => {
    if (moon) {
      moon.updateToken(token);
      moon.updateRefreshToken(refreshToken);
      //moon.connect();
    }
  };
  const createAccount = async () => {
    if (moon) {
      const data: CreateAccountInput = {};
      const newAccount = await moon?.getAccountsSDK().createAccount(data);
      return newAccount;
    }
  };
  const disconnect = async () => {
    if (moon) {
      await moon.disconnect();
      sessionStorage.removeItem(MOON_SESSION_KEY);
      setMoon(null);
    }
  };
  
  const listAccounts = async () => {
    if (moon) {
      return moon.listAccounts();
    }
  };
  return {
    moon,
    initialize,
    connect,
    updateToken,
    createAccount,
    disconnect,
    listAccounts,
  };
};
/// MOON-SDK EXAMPLE ///
// import { useEffect, useState } from "react";
// import { AccountResponse, CreateAccountInput, Transaction } from "@moonup/moon-api";
// import { MoonSDK } from "@moonup/moon-sdk";
// import { AUTH, MOON_SESSION_KEY, Storage } from "@moonup/moon-types";

// interface MoonSDKHook {
//   moon: MoonSDK | null;
//   initialize: () => Promise<void>;
//   disconnect: () => Promise<void>;
//   listAccounts: () => Promise<AccountResponse | undefined>;
//   updateToken: (token: string) => Promise<void>;
//   signTransaction: () => Promise<string>;
//   createAccount: () => Promise<HttpResponse<AccountControllerResponse, any> | undefined>;
//   // Add other methods as needed
// }

// export function useMoonSDK(): MoonSDKHook {
//   const [moon, setMoon] = useState<MoonSDK | null>(null);

//   const initialize = async () => {
//     const moonInstance = new MoonSDK({
//       Storage: {
//         key: MOON_SESSION_KEY,
//         type: Storage.SESSION,
//       },
//       Auth: {
//         AuthType: AUTH.JWT,
//       },
//     });
//     setMoon(moonInstance);
//     moonInstance.login();
//   };

//   const disconnect = async () => {
//     if (moon) {
//       await moon.disconnect();
//       setMoon(null);
//     }
//   };
//   const listAccounts = async () => {
//     if (moon) {
//       return moon.listAccounts();
//     }
//   };
//   const updateToken = async (token: string) => {
//     if (moon) {
//       return moon.updateToken(token);
//     }
//   };

//   const createAccount = async () => {
//     if (moon) {
//       const data: CreateAccountInput = {};
//       const newAccount = await moon?.getAccountsSDK().createAccount(data);
//       return newAccount;
//     }
//   };

//   const signTransaction = async () => {
//     if (!moon) {
//       throw new Error("Moon SDK is not initialized");
//     }
//     const raw_tx = await moon.getAccountsSDK().signTransaction("0x1c728ca6aec4ac69199c8724b752f72e775b90b6", {
//       to: "0x96bd4d63fba9fdc97a226c30e88d13680bd91527",
//       data: "",
//       gasPrice: "1000000000",
//       gas: "200000",
//       nonce: "0",
//       chain_id: "1891",
//       encoding: "utf-8",
//       value: "1",
//     });
//     const kek = (raw_tx.data.data as Transaction)?.transactions?.at(0)?.raw_transaction;
//     console.log(kek);
//     const tx = await moon.getAccountsSDK().broadcastTx("0x1c728ca6aec4ac69199c8724b752f72e775b90b6", {
//       chainId: "1891",
//       rawTransaction: "",
//     });

//     console.log(tx);
//     return "";
//   };

//   // Add other methods as needed

//   useEffect(() => {
//     initialize();
//   }, []);

//   return {
//     moon,
//     initialize,
//     disconnect,
//     listAccounts,
//     signTransaction,
//     updateToken,
//     createAccount,
//     // Add other methods as needed
//   };
// }
