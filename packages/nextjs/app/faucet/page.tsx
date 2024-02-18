"use client";

import Link from "next/link";
import { useMoonWalletContext } from "../../components/ScaffoldEthAppWithProviders";
import { useMoonSDK } from "../../hooks/moon";
import type { NextPage } from "next";
import { useAccount, useContractWrite } from "wagmi";
import { useTransactor } from "~~/hooks/scaffold-eth";

const Faucet: NextPage = () => {
  const writeTx = useTransactor();
  const connectedAddress: string = useAccount()?.address ?? "";
  const { moonWallet } = useMoonWalletContext();
  const account = connectedAddress || moonWallet;
  const { contractCall } = useMoonSDK();

  const wrapAbi = [
    {
      constant: true,
      inputs: [],
      name: "name",
      outputs: [{ name: "", type: "string" }],
      payable: false,
      stateMutability: "view",
      type: "function",
    },
    {
      constant: false,
      inputs: [
        { name: "guy", type: "address" },
        { name: "wad", type: "uint256" },
      ],
      name: "approve",
      outputs: [{ name: "", type: "bool" }],
      payable: false,
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      constant: true,
      inputs: [],
      name: "totalSupply",
      outputs: [{ name: "", type: "uint256" }],
      payable: false,
      stateMutability: "view",
      type: "function",
    },
    {
      constant: false,
      inputs: [
        { name: "src", type: "address" },
        { name: "dst", type: "address" },
        { name: "wad", type: "uint256" },
      ],
      name: "transferFrom",
      outputs: [{ name: "", type: "bool" }],
      payable: false,
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      constant: false,
      inputs: [{ name: "wad", type: "uint256" }],
      name: "withdraw",
      outputs: [],
      payable: false,
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      constant: true,
      inputs: [],
      name: "decimals",
      outputs: [{ name: "", type: "uint8" }],
      payable: false,
      stateMutability: "view",
      type: "function",
    },
    {
      constant: true,
      inputs: [{ name: "", type: "address" }],
      name: "balanceOf",
      outputs: [{ name: "", type: "uint256" }],
      payable: false,
      stateMutability: "view",
      type: "function",
    },
    {
      constant: true,
      inputs: [],
      name: "symbol",
      outputs: [{ name: "", type: "string" }],
      payable: false,
      stateMutability: "view",
      type: "function",
    },
    {
      constant: false,
      inputs: [
        { name: "dst", type: "address" },
        { name: "wad", type: "uint256" },
      ],
      name: "transfer",
      outputs: [{ name: "", type: "bool" }],
      payable: false,
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      constant: false,
      inputs: [],
      name: "deposit",
      outputs: [],
      payable: true,
      stateMutability: "payable",
      type: "function",
    },
    {
      constant: true,
      inputs: [
        { name: "", type: "address" },
        { name: "", type: "address" },
      ],
      name: "allowance",
      outputs: [{ name: "", type: "uint256" }],
      payable: false,
      stateMutability: "view",
      type: "function",
    },
    { payable: true, stateMutability: "payable", type: "fallback" },
    {
      anonymous: false,
      inputs: [
        { indexed: true, name: "src", type: "address" },
        { indexed: true, name: "guy", type: "address" },
        { indexed: false, name: "wad", type: "uint256" },
      ],
      name: "Approval",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        { indexed: true, name: "src", type: "address" },
        { indexed: true, name: "dst", type: "address" },
        { indexed: false, name: "wad", type: "uint256" },
      ],
      name: "Transfer",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        { indexed: true, name: "dst", type: "address" },
        { indexed: false, name: "wad", type: "uint256" },
      ],
      name: "Deposit",
      type: "event",
    },
    {
      anonymous: false,
      inputs: [
        { indexed: true, name: "src", type: "address" },
        { indexed: false, name: "wad", type: "uint256" },
      ],
      name: "Withdrawal",
      type: "event",
    },
  ];
  const routerAbi = [
    {
      inputs: [
        { internalType: "address", name: "_factory", type: "address" },
        { internalType: "address", name: "_WETH", type: "address" },
      ],
      stateMutability: "nonpayable",
      type: "constructor",
    },
    {
      inputs: [],
      name: "WETH",
      outputs: [{ internalType: "address", name: "", type: "address" }],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "tokenA", type: "address" },
        { internalType: "address", name: "tokenB", type: "address" },
        { internalType: "uint256", name: "amountADesired", type: "uint256" },
        { internalType: "uint256", name: "amountBDesired", type: "uint256" },
        { internalType: "uint256", name: "amountAMin", type: "uint256" },
        { internalType: "uint256", name: "amountBMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "addLiquidity",
      outputs: [
        { internalType: "uint256", name: "amountA", type: "uint256" },
        { internalType: "uint256", name: "amountB", type: "uint256" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint256", name: "amountTokenDesired", type: "uint256" },
        { internalType: "uint256", name: "amountTokenMin", type: "uint256" },
        { internalType: "uint256", name: "amountETHMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "addLiquidityETH",
      outputs: [
        { internalType: "uint256", name: "amountToken", type: "uint256" },
        { internalType: "uint256", name: "amountETH", type: "uint256" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
      ],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [],
      name: "factory",
      outputs: [{ internalType: "address", name: "", type: "address" }],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOut", type: "uint256" },
        { internalType: "uint256", name: "reserveIn", type: "uint256" },
        { internalType: "uint256", name: "reserveOut", type: "uint256" },
      ],
      name: "getAmountIn",
      outputs: [{ internalType: "uint256", name: "amountIn", type: "uint256" }],
      stateMutability: "pure",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountIn", type: "uint256" },
        { internalType: "uint256", name: "reserveIn", type: "uint256" },
        { internalType: "uint256", name: "reserveOut", type: "uint256" },
      ],
      name: "getAmountOut",
      outputs: [{ internalType: "uint256", name: "amountOut", type: "uint256" }],
      stateMutability: "pure",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOut", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
      ],
      name: "getAmountsIn",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountIn", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
      ],
      name: "getAmountsOut",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "view",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountA", type: "uint256" },
        { internalType: "uint256", name: "reserveA", type: "uint256" },
        { internalType: "uint256", name: "reserveB", type: "uint256" },
      ],
      name: "quote",
      outputs: [{ internalType: "uint256", name: "amountB", type: "uint256" }],
      stateMutability: "pure",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "tokenA", type: "address" },
        { internalType: "address", name: "tokenB", type: "address" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
        { internalType: "uint256", name: "amountAMin", type: "uint256" },
        { internalType: "uint256", name: "amountBMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "removeLiquidity",
      outputs: [
        { internalType: "uint256", name: "amountA", type: "uint256" },
        { internalType: "uint256", name: "amountB", type: "uint256" },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
        { internalType: "uint256", name: "amountTokenMin", type: "uint256" },
        { internalType: "uint256", name: "amountETHMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "removeLiquidityETH",
      outputs: [
        { internalType: "uint256", name: "amountToken", type: "uint256" },
        { internalType: "uint256", name: "amountETH", type: "uint256" },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
        { internalType: "uint256", name: "amountTokenMin", type: "uint256" },
        { internalType: "uint256", name: "amountETHMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "removeLiquidityETHSupportingFeeOnTransferTokens",
      outputs: [{ internalType: "uint256", name: "amountETH", type: "uint256" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
        { internalType: "uint256", name: "amountTokenMin", type: "uint256" },
        { internalType: "uint256", name: "amountETHMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
        { internalType: "bool", name: "approveMax", type: "bool" },
        { internalType: "uint8", name: "v", type: "uint8" },
        { internalType: "bytes32", name: "r", type: "bytes32" },
        { internalType: "bytes32", name: "s", type: "bytes32" },
      ],
      name: "removeLiquidityETHWithPermit",
      outputs: [
        { internalType: "uint256", name: "amountToken", type: "uint256" },
        { internalType: "uint256", name: "amountETH", type: "uint256" },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "token", type: "address" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
        { internalType: "uint256", name: "amountTokenMin", type: "uint256" },
        { internalType: "uint256", name: "amountETHMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
        { internalType: "bool", name: "approveMax", type: "bool" },
        { internalType: "uint8", name: "v", type: "uint8" },
        { internalType: "bytes32", name: "r", type: "bytes32" },
        { internalType: "bytes32", name: "s", type: "bytes32" },
      ],
      name: "removeLiquidityETHWithPermitSupportingFeeOnTransferTokens",
      outputs: [{ internalType: "uint256", name: "amountETH", type: "uint256" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "address", name: "tokenA", type: "address" },
        { internalType: "address", name: "tokenB", type: "address" },
        { internalType: "uint256", name: "liquidity", type: "uint256" },
        { internalType: "uint256", name: "amountAMin", type: "uint256" },
        { internalType: "uint256", name: "amountBMin", type: "uint256" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
        { internalType: "bool", name: "approveMax", type: "bool" },
        { internalType: "uint8", name: "v", type: "uint8" },
        { internalType: "bytes32", name: "r", type: "bytes32" },
        { internalType: "bytes32", name: "s", type: "bytes32" },
      ],
      name: "removeLiquidityWithPermit",
      outputs: [
        { internalType: "uint256", name: "amountA", type: "uint256" },
        { internalType: "uint256", name: "amountB", type: "uint256" },
      ],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOut", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapETHForExactTokens",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapExactETHForTokens",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapExactETHForTokensSupportingFeeOnTransferTokens",
      outputs: [],
      stateMutability: "payable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountIn", type: "uint256" },
        { internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapExactTokensForETH",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountIn", type: "uint256" },
        { internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapExactTokensForETHSupportingFeeOnTransferTokens",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountIn", type: "uint256" },
        { internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapExactTokensForTokens",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountIn", type: "uint256" },
        { internalType: "uint256", name: "amountOutMin", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapExactTokensForTokensSupportingFeeOnTransferTokens",
      outputs: [],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOut", type: "uint256" },
        { internalType: "uint256", name: "amountInMax", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapTokensForExactETH",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    {
      inputs: [
        { internalType: "uint256", name: "amountOut", type: "uint256" },
        { internalType: "uint256", name: "amountInMax", type: "uint256" },
        { internalType: "address[]", name: "path", type: "address[]" },
        { internalType: "address", name: "to", type: "address" },
        { internalType: "uint256", name: "deadline", type: "uint256" },
      ],
      name: "swapTokensForExactTokens",
      outputs: [{ internalType: "uint256[]", name: "amounts", type: "uint256[]" }],
      stateMutability: "nonpayable",
      type: "function",
    },
    { stateMutability: "payable", type: "receive" },
  ];

  const amountETH = 100000000000000000n;
  const amountETHmin = 90000000000000000n;
  const amountUSDC = 400000;

  const { writeAsync: wrap } = useContractWrite({
    abi: wrapAbi,
    address: "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
    functionName: "deposit",
    value: amountETH,
  });

  const handleWrap = async () => {
    try {
      if (moonWallet)
        await contractCall(
          moonWallet,
          "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
          wrapAbi as any,
          "deposit",
          [],
          Number(amountETH),
        );
      else await writeTx(wrap, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { writeAsync: approveETH } = useContractWrite({
    abi: wrapAbi,
    address: "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
    functionName: "approve",
    args: ["0x8954AfA98594b838bda56FE4C12a09D7739D179b", amountETH],
  });

  const handleApproveETH = async () => {
    try {
      if (moonWallet)
        await contractCall(moonWallet, "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889", wrapAbi as any, "approve", [
          "0x8954AfA98594b838bda56FE4C12a09D7739D179b",
          amountETH,
        ]);
      else await writeTx(approveETH, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { writeAsync: approveUSDC } = useContractWrite({
    abi: wrapAbi,
    address: "0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97",
    functionName: "approve",
    args: ["0x8954AfA98594b838bda56FE4C12a09D7739D179b", amountUSDC],
  });

  const handleApproveUSDC = async () => {
    try {
      if (moonWallet)
        await contractCall(moonWallet, "0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97", wrapAbi as any, "approve", [
          "0x8954AfA98594b838bda56FE4C12a09D7739D179b",
          amountUSDC,
        ]);
      else await writeTx(approveUSDC, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  const { writeAsync: addLiquidity } = useContractWrite({
    abi: routerAbi,
    address: "0x8954AfA98594b838bda56FE4C12a09D7739D179b",
    functionName: "addLiquidity",
    args: [
      "0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97",
      "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
      amountUSDC,
      amountETH,
      (amountUSDC * 9) / 10,
      amountETHmin,
      account,
      999999999999,
    ],
  });

  const handleAddLiquidity = async () => {
    try {
      if (moonWallet)
        await contractCall(moonWallet, "0x8954AfA98594b838bda56FE4C12a09D7739D179b", routerAbi as any, "addLiquidity", [
          "0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97",
          "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
          amountUSDC,
          amountETH,
          (amountUSDC * 9) / 10,
          amountETHmin,
          account,
          999999999999,
        ]);
      else await writeTx(addLiquidity, { blockConfirmations: 1 });
    } catch (e) {
      console.log("Unexpected error in writeTx", e);
    }
  };

  return (
    <>
      <div className="flex items-center flex-col flex-grow pt-10">
        <div className="px-5">
          <h1 className="text-center mb-8">
            <span className="block text-2xl mb-2">Get testnet LP Token (Polygon Mumbai)</span>
          </h1>
          <div className="flex justify-center items-center gap-12 flex-col">
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <h2>Get MATIC and USDC from the faucets</h2>
              <p>
                MATIC faucet:
                <br />
                <Link href="https://faucet.polygon.technology/" passHref className="link" target="_blank">
                  https://faucet.polygon.technology/
                </Link>
                <br />
                <br />
                USDC faucet:
                <br />
                <Link href="https://faucet.circle.com/" passHref className="link" target="_blank">
                  https://faucet.circle.com/
                </Link>
              </p>
            </div>
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <h2>Check the transactions on Polygonscan</h2>
              <p>Event listeners have not been implemented yet. Click the link to view your account on PolygonScan.</p>
              <Link
                href={"https://mumbai.polygonscan.com/address/" + account}
                passHref
                className="link"
                target="_blank"
              >
                Go to PolygonScan
              </Link>
              <p>You can also find the transaction statuses in your Browser wallet (if not using Moon).</p>
            </div>
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <h2>Wrap 0.1 MATIC</h2>
              <button className="btn btn-secondary" onClick={handleWrap}>
                Wrap
              </button>
            </div>
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <h2>Approve tokens to Uniswap V2 Router</h2>
              <button className="btn btn-secondary" onClick={handleApproveETH}>
                Approve WMATIC
              </button>
              <button className="btn btn-secondary" onClick={handleApproveUSDC}>
                Approve USDC
              </button>
            </div>
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <h2>Add Liquidity to Uniswap V2 pool</h2>
              <button className="btn btn-secondary" onClick={handleAddLiquidity}>
                Add Liquidity
              </button>
            </div>
            <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
              <h2>Enter the test tournament</h2>
              <Link href="/tournaments" passHref className="link">
                Go to Tournaments page
              </Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Faucet;
