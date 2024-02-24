"use client";

import Link from "next/link";
import type { NextPage } from "next";

const About: NextPage = () => {
  return (
    <div className="flex items-center flex-col flex-grow pt-10">
      <div className="px-5">
        <h1 className="text-center mb-8">
          <span className="block text-2xl mb-2">About this dApp</span>
        </h1>
        <div className="flex justify-center items-center gap-12 flex-col">
          <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
            <h2>BCamp Janus Dragon Project</h2>
            <p>
              This project is part of the projects developped by the apprentices of the BCamp cohort of January 2024.
              <br />
              <br />
              <Link href="https://github.com/0xBcamp/xRave-janus-dragon" passHref className="link" target="_blank">
                Github repository
              </Link>
              <br />
              <Link href="https://twitter.com/0xBcamp" passHref className="link" target="_blank">
                BCamp on Twitter
              </Link>
            </p>
          </div>
          <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
            <h2>The Team</h2>
            <p>The team consists of 2 apprentices and 1 mentor.</p>
            <h3>Nicolas - 0xc00c</h3>
            <Link href={"https://twitter.com/0xc00c"} passHref className="link" target="_blank">
              Twitter
            </Link>
            <br />
            <Link href={"https://github.com/0xc00c"} passHref className="link" target="_blank">
              Github
            </Link>
            <br />
            <br />
            <h3>Trevor - funkornaut</h3>
            <Link href={"https://twitter.com/funkornaut"} passHref className="link" target="_blank">
              Twitter
            </Link>
            <br />
            <Link href={"https://github.com/funkornaut001"} passHref className="link" target="_blank">
              Github
            </Link>
          </div>
          <div className="space-y-8 px-5 py-5 bg-base-100 rounded-3xl">
            <h2>What can this live demo do?</h2>
            <p>
              This live demo allows you to interact with the contracts deployed on Mumbai testnet.
              <br />
              <br />
              The contract interactions can be initiated by a browser wallet or with the account abstraction Moon SDK.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default About;
