import { useEffect, useState } from "react";
import { useMoonSDK } from "../../hooks/moon";
import { InputBase } from "~~/components/scaffold-eth";

export const Signup = () => {
  // Signup Component
  const { moon, initialize, disconnect } = useMoonSDK();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [answer, setAnswer] = useState("");

  const handleSignup = async (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    try {
      // Check if Moon SDK is properly initialized and user is authenticated
      if (!moon) {
        console.error("User not authenticated");
        return;
      }

      const message = await moon.getAuthSDK().emailSignup({
        email,
        password,
      });
      console.log(message);
      setAnswer(message.data.message);
    } catch (error: any) {
      console.error(error);
      if (error) setAnswer(error.error.message);
    }
  };

  // Use useEffect to initialize Moon SDK on component mount
  useEffect(() => {
    initialize();

    // Cleanup Moon SDK on component unmount
    return () => {
      disconnect();
    };
  }, [initialize, disconnect]);

  return (
    <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
      <h2>Create Moon Account</h2>
      <form>
        <label>
          <InputBase name="email" placeholder="Enter your email" value={email} onChange={setEmail} />
        </label>
        <br />
        <label>
          <InputBase name="password" placeholder="Enter your password" value={password} onChange={setPassword} />
        </label>
        <button className="btn btn-secondary" onClick={handleSignup}>
          Sign up
        </button>
        <div>{answer}</div>
      </form>
    </div>
  );
};
