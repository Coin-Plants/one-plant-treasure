import { ethers, upgrades } from "hardhat";
import { OnePlantTreasureV2, Pollen } from "../typechain-types";

// npx hardhat run scripts/deploy.ts --network sepolia
async function main() {

  const Pollen = await ethers.getContractFactory("Pollen");
  const pollen: Pollen = (await Pollen.attach("0xB1b08c24dab1483254033E038B6471CB03D80d71")) as Pollen;
  let POLLEN = await pollen.getAddress();
  console.log("Pollen deployed to:", POLLEN);

  console.log("Deploying OnePlantTreasure...")
  const OnePlantTreasure = await ethers.getContractFactory("OnePlantTreasureV2");
  const onePlantTreasure: OnePlantTreasureV2 = (await upgrades.deployProxy(OnePlantTreasure, [POLLEN], { initializer: 'initialize' })) as unknown as OnePlantTreasureV2;
  console.log("OnePlantTreasure deployed to:", await onePlantTreasure.getAddress());
  // await onePlantTreasure.setBaseURI("ipfs://");
  console.log("Transferring 7M Pollen to OnePlantTreasure...")
  await pollen.transfer(await onePlantTreasure.getAddress(), ethers.parseEther("7000000"));
  console.log("Opening the mint...")
  await onePlantTreasure.setOpen(true);
  console.log("Boom! Mint is open. You're good to go")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
