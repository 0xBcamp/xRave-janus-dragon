"use client";


//basic next page, user signs into moon using moon-sdk
import { useState } from "react";
import { useMoonSDK } from "../../hooks/moon";
import { EmailLoginInput, EmailSignupInput, EmailSignupResponse } from "@moonup/moon-api";
import { setDefaultResultOrder } from "dns";
import { NextPage } from "next";

const SignIntoMoon: NextPage = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [signupSuccess, setSignupSuccess] = useState(false);
  const [signInSuccess, setSignInSuccess] = useState(false);
  const [authenticatedAddress, setAuthenticatedAddress] = useState("");
  const [isConnected, setIsConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // use these instead of
  const [response, setResponse] = useState<EmailSignupResponse | null>(null);

  const { moon, connect, createAccount, disconnect, updateToken, initialize, listAccounts } = useMoonSDK();

  const handleEmailChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };

  const handlePasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleConfirmPasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setConfirmPassword(event.target.value);
  };

  const handleInitializeAndConnect = async () => {
    try {
      setLoading(true);
      setError(null);

      await initialize();
      await connect();
      console.log("Connected to Moon");

      setIsConnected(true);
    } catch (error) {
      console.error("Error connecting to Moon", error);
      setError("Error connecting to Moon");
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async () => {
    try {
      setLoading(true);
      setError(null);

      if (password !== confirmPassword) {
        setPasswordError("Passwords do not match");
      } else {
        setPasswordError("");

        //sign user in
        const auth = moon.getAuthSDK();
        const signupRequest: EmailSignupInput = {
          email,
          password,
        };
        console.log("Signing up ...");
        console.log("Signup Request:", signupRequest);
        // can we use email siginuprespones??
        // const EmailSignupResponse = await auth?.emailSignup(signupRequest);
        // console.log('Signup successful:', signupResponse);

        // setSignupSuccess(true);

        /// await?
        const signupResponse = await auth.emailSignup(signupRequest);
        console.log("Signup successful:", signupResponse);

        setSignupSuccess(true);
      }
    } catch (error) {
      console.error("Error during signup:", error);
      setError("Error signing up. Please try again.");
    } finally {
      setLoading(false);
    }

    // validate email & password //
    // if (!email.includes('@')) {
    //   setError('Invalid email format');
    //   setLoading(false);
    //   return;
    // }
    
    // // Assuming a simple password length requirement for demonstration
    // if (password.length < 8) {
    //   setPasswordError('Password must be at least 8 characters long');
    //   setLoading(false);
    //   return;
    // }
    
    // // Proceed with signup request if validations pass
    // const signupRequest: EmailSignupInput = {
    //   email,
    //   password,
    // };
    
  };

  const handleSignIn = async () => {
    try {
      setLoading(true);
      setError(null);

      //sign user in
      const auth = moon?.getAuthSDK();
      const loginRequest: EmailLoginInput = {
        email,
        password,
      };
      console.log("Authenticating ...");
      const loginResponse: any = await auth.emailLogin(loginRequest);
      console.log("Authentication successful:", loginResponse);

      

      // Set tokens and email
      console.log("Updating tokens and email ...");
      await updateToken(loginResponse.data.token, loginResponse.data.refreshToken);
      moon?.MoonAccount.setEmail(email);
      
      //@note what is expiry??
      moon?.MoonAccount.setExpiry(loginResponse.data.expiry);
      console.log("Tokens and email updated");
      const accounts = await listAccounts();
      console.log("Accounts:", accounts); 

      //perform signin logic w/ Moonsdk
      console.log("Creating Moon Account ...");
      const newAccount = await createAccount();
      
      
      console.log("New Account Data:", newAccount);
      console.log("Setting expiry and navigating...");
      moon?.MoonAccount.setExpiry(loginResponse.data.expiry);
      setSignInSuccess(true);
      setAuthenticatedAddress(newAccount?.data.data.address);
      console.log("Authenticated Address:", newAccount?.data.data.address);
      

    } catch (error) {
      console.error("Error during signin:", error);
      setError("Error signing in. Please try again.");
    } finally {
      setLoading(false);
    }
  };
  //@todo Disconnect needs to actually disconnect

  const handleDisconnect = async () => {
    try {
      setLoading(true);
      setError(null);

      // Disconnect from Moon
      console.log("Disconnecting...");
      await disconnect();
      console.log("Disconnected");
      setIsConnected(false);
    } catch (error) {
      console.error("Error during disconnection:", error);
      setError("Error disconnecting from Moon. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex justify-center items-center h-screen">
      {!isConnected && (
        // First Button to connect to moon
        <div>
          <h2 className="text-2xl font-bold mb-4 text-center">Initialize & Connect to Moon</h2>
          <button type="button" className="bg-blue-500 text-white p-2 rounded" onClick={handleInitializeAndConnect}>
            {loading ? "Connecting..." : "Initialize & Connect to Moon"}
          </button>
          {error && <p className="text-red-500 mt-2">{error}</p>}
        </div>
      )}

      {isConnected && !signupSuccess && !signInSuccess && (
        //signup form
        <form className="bg-white text-black shadow-md rounded px-8 pt-6 pb-8 mb-4 w-96">
          <div className="mb-4">
            <h2 className="text-2xl font-bold mb-4 text-center">Sign up for a Moon Account</h2>
            <input
              type="email"
              placeholder="Email"
              className="w-full border p-2 rounded mb-2 "
              value={email}
              onChange={handleEmailChange}
            />
          </div>
          <div className="mb-4">
            <input
              type="password"
              placeholder="Password"
              className="w-full border p-2 rounded mb-2"
              value={password}
              onChange={handlePasswordChange}
            />
          </div>
          <div className="mb-4">
            <input
              type="password"
              placeholder="Confirm Password"
              className={`w-full border p-2 rounded mb-2 ${passwordError ? "border-red-500" : ""}`}
              value={confirmPassword}
              onChange={handleConfirmPasswordChange}
            />
            {passwordError && <p className="text-red-500 text-xs italic">{passwordError}</p>}
          </div>
          <div className="flex justify-center">
            <button type="button" className="bg-blue-500 text-white p-2 rounded" onClick={handleSignUp}>
              {loading ? "Signing up..." : "Sign up for a Moon Account"}
            </button>
            {error && <p className="text-red-500 ml-2">{error}</p>}
          </div>
        </form>
      )}

      {signupSuccess && !signInSuccess && isConnected && (
        <div className="mb-4 text-center">
          <p>Congratulations! Your Moon account is created.</p>
          <p>Now that you have created an account, sign in.</p>
          <form className="bg-white text-black shadow-md rounded px-8 pt-6 pb-8 mb-4 w-96">
            <div className="mb-4">
              <h2 className="text-2xl font-bold mb-4 text-center">Sign In</h2>
              <input
                type="email"
                placeholder="Email"
                className="w-full border p-2 rounded mb-2"
                value={email}
                onChange={handleEmailChange}
              />
            </div>
            <div className="mb-4">
              <input
                type="password"
                placeholder="Password"
                className="w-full border p-2 rounded mb-2"
                value={password}
                onChange={handlePasswordChange}
              />
            </div>
            <div className="flex justify-center">
              <button type="button" className="bg-blue-500 text-white p-2 rounded" onClick={handleSignIn}>
                {loading ? "Signing in..." : "Sign In"}
              </button>
              {error && <p className="text-red-500 ml-2">{error}</p>}
            </div>
          </form>
        </div>
      )}

      {signInSuccess && isConnected && (
        <div className="mt-4 text-center">
          <p>Authenticated Address: {authenticatedAddress}</p>
          <button type="button" className="bg-red-500 text-white p-2 rounded mt-2" onClick={handleDisconnect}>
            {loading ? "Disconnecting..." : "Disconnect from Moon"}
          </button>
          {error && <p className="text-red-500 mt-2">{error}</p>}
        </div>
      )}
    </div>
  );
};

export default SignIntoMoon;




// import { useEffect, useState } from "react";
// import { useMoonSDK } from "../../hooks/moon";

// // Signup Component
// function LoginPage() {
//   const { moon, initialize, disconnect } = useMoonSDK();
//   const [email, setEmail] = useState("");
//   const [password, setPassword] = useState("");
//   const [walletAddress, setWalletAddress] = useState("");

//   const handleLogin = async () => {
//     try {
//       // Check if Moon SDK is properly initialized and user is authenticated
//       if (!moon) {
//         console.error("User not authenticated");
//         return;
//       }

//       const message = await moon.getAuthSDK().emailLogin({
//         email,
//         password,
//       });
//       console.log("Login message:", message);
//       const { token, refreshToken } = message.data;

//       moon.updateToken(token);
//       moon.updateRefreshToken(refreshToken);
//     } catch (error) {
//       console.error(error);
//     }
//   };

//   // Use useEffect to initialize Moon SDK on component mount
//   useEffect(() => {
//     initialize();

//     // Cleanup Moon SDK on component unmount
//     return () => {
//       disconnect();
//     };
//   }, []);

//   return (
//     <div>
//       <h2>Login Moon Account</h2>
//       <form>
//         <label>
//           Email:
//           <input type="email" value={email} onChange={e => setEmail(e.target.value)} />
//         </label>
//         <br />
//         <label>
//           Password:
//           <input type="password" value={password} onChange={e => setPassword(e.target.value)} />
//         </label>
//         <button type="button" onClick={handleLogin}>
//           Login
//         </button>
//       </form>
//     </div>
//   );
// }

// export default LoginPage;