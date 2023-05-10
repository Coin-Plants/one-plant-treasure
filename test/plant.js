
const { expect } = require("chai")
const { upgrades } = require('hardhat');

describe("One Plant Treasure Contract", function() {
  
  it("The test of smart contract deployment", async function() {
    const [owner] = await ethers.getSigners();

    const plantFactory = await ethers.getContractFactory("OnePlantTreasure");

    const contractObject  = await upgrades.deployProxy(plantFactory, { initializer: 'initialize' });

    await contractObject.deployed();

    console.log(`\nContract deployed to:\n${contractObject.address}`);

    const balance = await contractObject.balanceOf(owner.address);

    console.log(balance);
  })

})