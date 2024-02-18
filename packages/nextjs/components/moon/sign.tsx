import { useState } from "react";
import { useMoonWalletContext } from "../../components/ScaffoldEthAppWithProviders";
import { useMoonSDK } from "../../hooks/moon";
import { Spinner } from "../Spinner";
//import { useCall } from "~~/hooks/call";
import { CreateAccountInput } from "@moonup/moon-api";
import { formatEther } from "viem";
//import { erc20ABI } from "wagmi";
import { ClipboardIcon } from "@heroicons/react/24/outline";
import { InputBase, InputPwd } from "~~/components/scaffold-eth";

export const Sign = () => {
  const { moon, connect, disconnect, listAccounts } = useMoonSDK();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [answer, setAnswer] = useState("");
  const { moonWallet, setMoonWallet } = useMoonWalletContext();
  const [balance, setBalance] = useState(0n);
  const [action, setAction] = useState("");

  const handleSignup = async (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    setAnswer("");
    setAction("signup");
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        setAction("");
        return;
      }

      const message = await moon.getAuthSDK().emailSignup({
        email,
        password,
      });
      console.log(message);
      setAnswer(message.data.message);

      const data: CreateAccountInput = {};
      const message3 = await moon.getAccountsSDK().createAccount(data);
      console.log(message3);

      const message2 = await listAccounts();
      console.log(message2);
      if (message2) {
        const res: any = message2;
        setMoonWallet(res.data.keys[0]);
      }
    } catch (error: any) {
      console.error(error);
      if (error) setAnswer(error.error.message);
    }
    setAction("");
  };

  const handleLogin = async (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    setAnswer("");
    setAction("login");
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        setAction("");
        return;
      }

      const message = await moon.getAuthSDK().emailLogin({
        email,
        password,
      });
      const { token, refreshToken } = message.data;

      console.log(message);
      moon.updateToken(token);
      moon.updateRefreshToken(refreshToken);
      moon.MoonAccount.setEmail(email);
      moon.MoonAccount.setExpiry(message.data.expiry);
      connect();

      const message2 = await listAccounts();
      let addr: any;
      console.log(message2);
      if (message2) {
        addr = message2;
        setMoonWallet(addr.data.keys[0]);
      }

      const message4 = await moon.getAccountsSDK().getBalance(addr.data.keys[0], { chainId: "80001" });
      console.log(message4);
      if (message4) {
        const res: any = message4;
        setBalance(res.data.data.balance);
      }
    } catch (error: any) {
      console.error(error);
      setAnswer(error.error.message);
    }
    setAction("");
  };

  const handleDisconnect = async () => {
    try {
      // Disconnect from Moon
      await disconnect();
      setMoonWallet("");
      setBalance(0n);
      console.log("Disconnected from Moon");
    } catch (error) {
      console.error("Error during disconnection:", error);
    }
  };

  // const handleTransaction = async (event: React.MouseEvent<HTMLElement>) => {
  //   event.preventDefault();
  //   setAnswer("");
  //   try {
  //     await contractCall(moonWallet, "0xd8992Ed72C445c35Cb4A2be468568Ed1079357c8", erc20ABI as any, "approve", [
  //       "0x8954AfA98594b838bda56FE4C12a09D7739D179b",
  //       10000000000000000000000000n,
  //     ]);
  //   } catch (error: any) {
  //     console.error(error);
  //     if (error) setAnswer(error.error.message);
  //   }
  // };

  const handleCopy = () => {
    navigator.clipboard.writeText(moonWallet);
  };

  return (
    <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
      <h2>Moon Account</h2>
      {!moonWallet ? (
        <form>
          <label>
            <InputBase name="email" placeholder="Enter your email" value={email} onChange={setEmail} />
          </label>
          <br />
          <label>
            <InputPwd name="password" placeholder="Enter your password" value={password} onChange={setPassword} />
          </label>
          <div className="flex justify-between mt-4">
            <button className="btn btn-secondary" disabled={action !== ""} onClick={handleSignup}>
              {action === "signup" ? <Spinner /> : "Sign up"}
            </button>
            <button className="btn btn-secondary" disabled={action !== ""} onClick={handleLogin}>
              {action === "login" ? <Spinner /> : "Sign in"}
            </button>
          </div>
          <div>{answer}</div>
        </form>
      ) : (
        <>
          <div>
            <div className="flex flex-row">
              Your address: {moonWallet}
              <ClipboardIcon className="w-6 h-6" onClick={handleCopy} />
            </div>
            <br />
            Balance: {formatEther(balance)} MATIC
          </div>
          <button className="btn btn-secondary" onClick={handleDisconnect}>
            Logout
          </button>
        </>
      )}

      {/*<button className="btn btn-secondary" onClick={handleTransaction}>
        Test Tx
      </button>*/}
    </div>
  );
};
