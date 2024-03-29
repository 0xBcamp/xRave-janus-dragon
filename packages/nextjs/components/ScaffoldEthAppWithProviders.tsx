"use client";

import { createContext, useContext, useEffect, useState } from "react";
import { RainbowKitProvider, darkTheme, lightTheme } from "@rainbow-me/rainbowkit";
import { Toaster } from "react-hot-toast";
import { WagmiConfig } from "wagmi";
import { Footer } from "~~/components/Footer";
import { Header } from "~~/components/Header";
import { BlockieAvatar } from "~~/components/scaffold-eth";
import { ProgressBar } from "~~/components/scaffold-eth/ProgressBar";
import { useNativeCurrencyPrice } from "~~/hooks/scaffold-eth";
import { useDarkMode } from "~~/hooks/scaffold-eth/useDarkMode";
import { useGlobalState } from "~~/services/store/store";
import { wagmiConfig } from "~~/services/web3/wagmiConfig";
import { appChains } from "~~/services/web3/wagmiConnectors";

//import { rainbowkitUseMoonConnector } from "@moonup/moon-rainbowkit";
//import { AUTH, MOON_SESSION_KEY, Storage } from "@moonup/moon-types";
const ScaffoldEthApp = ({ children }: { children: React.ReactNode }) => {
  const price = useNativeCurrencyPrice();
  const setNativeCurrencyPrice = useGlobalState(state => state.setNativeCurrencyPrice);

  useEffect(() => {
    if (price > 0) {
      setNativeCurrencyPrice(price);
    }
  }, [setNativeCurrencyPrice, price]);

  return (
    <>
      <div className="flex flex-col min-h-screen">
        <Header />
        <main className="relative flex flex-col flex-1">{children}</main>
        <Footer />
      </div>
      <Toaster />
    </>
  );
};

export type MoonWalletContextType = {
  moonWallet: string;
  setMoonWallet: (c: string) => void;
};
export const MoonWalletContext = createContext<MoonWalletContextType>({
  moonWallet: "",
  setMoonWallet: () => {
    true;
  },
});

export const useMoonWalletContext = () => useContext(MoonWalletContext);

export const ScaffoldEthAppWithProviders = ({ children }: { children: React.ReactNode }) => {
  const { isDarkMode } = useDarkMode();
  const [moonWallet, setMoonWallet] = useState("");

  return (
    <WagmiConfig config={wagmiConfig}>
      <ProgressBar />
      <RainbowKitProvider
        chains={appChains.chains}
        avatar={BlockieAvatar}
        theme={isDarkMode ? darkTheme() : lightTheme()}
      >
        <MoonWalletContext.Provider value={{ moonWallet, setMoonWallet }}>
          <ScaffoldEthApp>{children}</ScaffoldEthApp>
        </MoonWalletContext.Provider>
      </RainbowKitProvider>
    </WagmiConfig>
  );
};
