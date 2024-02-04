"use client";

import { useEffect, useState } from "react";
import { useMoonSDK } from "../../hooks/moonsiwe";
import { AccountResponse } from "@moonup/moon-api";
import { ethers } from "ethers";
import { set } from "nprogress";
import { SiweMessage } from "siwe";

function SIWE() {
  const [accounts, setAccounts] = useState<string[]>([]);
  const [loggedIn, setLoggedIn] = useState<boolean>(false);
  const { updateToken, listAccounts, moon, signTransaction, initialize, connect } = useMoonSDK();
  const { ethereum } = window as any;

  //   useEffect(() => {
  //     initialize();
  //     connect();
  //     console.log("Connected to Moon");
  //   });

  const SIWE = async () => {
    //await initialize();
    if (typeof ethereum === "undefined") {
      return;
    }

    const address = await ethereum.request({ method: "eth_requestAccounts" }).then(function (accounts: any[]) {
      console.log(accounts);
      return accounts[0];
    });
    console.log(address);
    return fetch("https://vault-api.usemoon.ai/auth/ethereum/challenge", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        address: address,
      }),
    })
      .then(function (response) {
        return response.json();
      })
      .then(function (json) {
        return ethereum.request({ method: "eth_requestAccounts" }).then(function (accounts: any[]) {
          return [accounts[0], json.nonce];
        });
      })
      .then(function (args) {
        const account = args[0];
        const address = ethers.utils.getAddress(account);
        const message = new SiweMessage({
          domain: window.location.host,
          address: address,
          statement: "Sign in with Ethereum to the app.",
          uri: window.location.origin,
          version: "1",
          chainId: 1,
          nonce: args[1],
        });

        const m = message.prepareMessage();
        return ethereum
          .request({
            method: "personal_sign",
            params: [m, address],
          })
          .then(function (signature: any) {
            return [m, signature];
          });
      })
      .then(function (args) {
        return fetch("https://vault-api.usemoon.ai/auth/ethereum", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify({
            message: args[0],
            signature: args[1],
            address,
          }),
        });
      })
      .then(function (response) {
        return response.json();
      })
      .then(function (json) {
        console.log(json);
        //updates moonsdk with new tokens??
        updateToken(json.accessToken, json.refreshToken);
        setLoggedIn(true);
        console.log("Logged In");

        getAccounts();
        // can redirect after succesful authentication
        // window.location.href = json.location;
      });
  };

  //   useEffect(() => {
  //     if (moon?.MoonAccount.isAuth) {
  //       setLoggedIn(true);
  //       console.log("Logged In");
  //       //getAccounts();
  //     }
  //   }, [moon]);

  // make new accounts when user is logged in and authenticated
  // React to changes in the isAuthenticated state
  //   useEffect(() => {
  //     if (loggedIn) {
  //         const newAccount = await createAccount();
  //         .then(newAccount => {
  //           console.log("New account created:", newAccount);
  //           //setAccountInfo(newAccount); // Store or use the new account info as needed
  //         })
  //         .catch(error => {
  //           console.error("Failed to create account:", error);
  //         });
  //     }
  //   }, [loggedIn, createAccount]);

  const createAccount = async () => {
    if (!moon) {
      console.log("Moon SDK is not initialized or authenticated");
      return;
    }
    try {
      const account = await moon.getAccountsSDK().createAccount({}, {});
      console.log(account);
      return account;
    } catch (error) {
      console.error("Failed to create account:", error);
    }
  };

  const signMessage = async () => {
    const message = await moon?.getAccountsSDK().signMessage(accounts[0], {
      data: "Hello World",
    });
    console.log(message);
  };

  const getAccounts = async () => {
    const accounts = await moon?.getAccountsSDK().listAccounts();
    console.log("accounts:", accounts);
    const newAccounts = (accounts?.data.data as AccountResponse).keys || [];
    setAccounts(newAccounts);
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen py-12">
      <div
        className="w-full max-w-md p-8 space-y-4 bg-blue-300
   shadow-lg rounded-xl"
      >
        {loggedIn ? (
          <div className="text-center">
            <h1 className="text-2xl font-bold">Logged In</h1>
          </div>
        ) : (
          <button
            id="siw-ethereum"
            onClick={SIWE}
            className="w-full px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50"
          >
            Join The Conquest
          </button>
        )}

        {accounts.length > 0 ? (
          <ul className="space-y-2">
            {accounts.map((account, index) => (
              <li key={index} className="text-sm text-gray-700">
                {account}
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-center text-sm text-gray-500">No accounts available.</p>
        )}

        <div className="flex flex-col space-y-2">
          <button
            onClick={createAccount}
            className="px-4 py-2 text-white bg-blue-500 hover:bg-blue-600 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-400 focus:ring-opacity-50"
          >
            Create Your Armory
          </button>
          {/* Additional buttons or content can be added here following the same pattern */}
        </div>
      </div>
    </div>
  );
}

export default SIWE;

