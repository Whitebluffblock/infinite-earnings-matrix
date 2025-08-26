import { ethers } from "hardhat";
import { writeFileSync } from "fs";

async function main() {
  // Replace with your recipients & bps (60/30/10 as example)
  const recipients = [
    "0xRecipientAddress1", // Reinvestment Pool
    "0xRecipientAddress2", // Agent Upgrade Fund
    "0xRecipientAddress3"  // BountyNova / Airdrop Pool
  ];
  const bps = [6000, 3000, 1000]; // sum 10000

  // Owner: the Gnosis Safe address (set your safe address here)
  const owner = "0xYourGnosisSafeAddress";

  const InfinityVault = await ethers.getContractFactory("InfinityVault");
  const vault = await InfinityVault.deploy(recipients, bps, owner);
  await vault.waitForDeployment();

  console.log("InfinityVault deployed to:", await vault.getAddress());

  writeFileSync("deployed-address.json", JSON.stringify({ address: await vault.getAddress() }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
