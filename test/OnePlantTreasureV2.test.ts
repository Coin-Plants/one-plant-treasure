import {
  time,
  mine,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Pollen, OnePlantTreasure, OnePlantTreasureV2 } from "../typechain-types";

const name = "One Plant Treasure"
const symbol = "$OPT"
const DURATION = 75;
const MATURITY = 7200;
let POLLEN: string;
const smartDev = "0x372B95Ac394F7dbdDc90f7a07551fb75509346A8";
const frontDev = "0x5546e8e71fCcEc025265fB07D4d4bd46Cee55aa9";

// Mint gas cost: 155,272
// Mint gas cost: 239,836 with 0.1 ETH
describe.only("OnePlantTreasureV2", function () {
  async function deploy() {
    const [owner, otherAccount] = await ethers.getSigners();

    const Pollen = await ethers.getContractFactory("Pollen");
    const pollen: Pollen = (await upgrades.deployProxy(Pollen, [], { initializer: 'initialize' })) as unknown as Pollen;

    POLLEN = await pollen.getAddress();
    const OnePlantTreasure = await ethers.getContractFactory("OnePlantTreasureV2");
    const onePlantTreasure: OnePlantTreasureV2 = (await upgrades.deployProxy(OnePlantTreasure, [POLLEN], { initializer: 'initialize' })) as unknown as OnePlantTreasureV2;
    await onePlantTreasure.setBaseURI("ipfs://");
    await pollen.transfer(await onePlantTreasure.getAddress(), ethers.parseEther("7000000"));

    return { onePlantTreasure, pollen, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should have correct name", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.name()).to.equal(name);
    });
    it("Should have correct symbol", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.symbol()).to.equal(symbol);
    });
    it("Should have correct MATURITY", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.MATURITY()).to.equal(MATURITY);
    });
    it("Should have correct DURATION", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.DURATION()).to.equal(DURATION);
    });
    it("Should have correct POLLEN", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.POLLEN()).to.equal(POLLEN);
    });
    it("Should have correct smartDev", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.smartDev()).to.equal(smartDev);
    });
    it("Should have correct frontDev", async function () {
      const { onePlantTreasure, owner } = await loadFixture(deploy);
      expect(await onePlantTreasure.frontDev()).to.equal(frontDev);
    });
  });

  describe("Mint", function () {
    it("Should mint", async function () {
      const { onePlantTreasure, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      // console.log("Mint Gas: ", await onePlantTreasure.connect(otherAccount).mint.estimateGas())
      await onePlantTreasure.connect(otherAccount).mint();
      expect(await onePlantTreasure.balanceOf(otherAccount.address)).to.equal(1);

    });

    it("Should fail if game not open", async function () {
      const { onePlantTreasure, owner, otherAccount } = await loadFixture(deploy);
      await expect(onePlantTreasure.connect(otherAccount).mint()).to.be.revertedWith("NOT OPEN");
    });
    it("Should fail if game is over", async function () {
      const { onePlantTreasure, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      await onePlantTreasure.connect(otherAccount).mint();
      expect(await onePlantTreasure.balanceOf(otherAccount.address)).to.equal(1);
      await mine(DURATION);
      await expect(
        onePlantTreasure.connect(otherAccount).mint()
      ).to.be.revertedWith("GAME OVER");
    });
    // it.skip("Should add to whitelist if more than >= 0.2 ETH", async function () {
    //   const { onePlantTreasure, owner, otherAccount } = await loadFixture(deploy);
    //   await onePlantTreasure.connect(owner).setOpen(true);
    //   await onePlantTreasure.connect(otherAccount).mint({  });
    //   expect(await onePlantTreasure.isWhitelisted(otherAccount.address)).to.equal(false);
    //   console.log("Mint with whitelist gas cost: ", await onePlantTreasure.connect(otherAccount).mint.estimateGas({ value: ethers.parseEther("0.2") }));
    //   await onePlantTreasure.connect(otherAccount).mint({ value: ethers.parseEther("0.2") });
    //   expect(await onePlantTreasure.isWhitelisted(otherAccount.address)).to.equal(true);
    // });

  });

  describe("claimRewards", function () {
    it("Should claimRewards", async function () {
      const { onePlantTreasure, pollen, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      await onePlantTreasure.connect(otherAccount).mint({ value: ethers.parseEther("0.01")});
      await mine(DURATION * 1000);
      await onePlantTreasure.connect(otherAccount).claimReward(1);
      expect(await pollen.balanceOf(otherAccount.address)).to.equal(ethers.parseEther("2"));
    });

    it("Should fail if token id doesnt exist", async function () {
      const { onePlantTreasure, pollen, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      await onePlantTreasure.connect(otherAccount).mint({ value: ethers.parseEther("0.01")});
      await mine(DURATION * 1000);
      await expect(
        onePlantTreasure.connect(otherAccount).claimReward(2)
      ).to.be.revertedWith("INVALID_TOKEN_ID");
    });
    it("Should fail if caller is not the owner", async function () {
      const { onePlantTreasure, pollen, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      await onePlantTreasure.connect(otherAccount).mint({ value: ethers.parseEther("0.01") });
      await mine(DURATION * 1000);
      await expect(
        onePlantTreasure.connect(owner).claimReward(1)
      ).to.be.revertedWith("NOT_OWNER");
    });
    it("Should fail if no ETH provided on mint", async function () {
      const { onePlantTreasure, pollen, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      await onePlantTreasure.connect(otherAccount).mint();
      await mine(DURATION * 1000);
      await expect(
        onePlantTreasure.connect(otherAccount).claimReward(1)
      ).to.be.revertedWith("NO_VALUE_PROVIDED");
    });
    it("Should fail if already claimed", async function () {
      const { onePlantTreasure, pollen, owner, otherAccount } = await loadFixture(deploy);
      await onePlantTreasure.connect(owner).setOpen(true);
      await onePlantTreasure.connect(otherAccount).mint({ value: ethers.parseEther("0.01")});
      await mine(DURATION * 1000);
      await onePlantTreasure.connect(otherAccount).claimReward(1);
      await expect(
        onePlantTreasure.connect(otherAccount).claimReward(1)
      ).to.be.revertedWith("OWNER_CLAIMED");
    });
  });

  describe.skip("tests", function () {
    it("URI test", async function () {
      const { onePlantTreasure, pollen, owner, otherAccount } = await loadFixture(deploy);
      console.log("BlockNumber: ", await owner.provider.getBlockNumber())
      await onePlantTreasure.connect(owner).setOpen(true);
      console.log("BlockNumber: ", await owner.provider.getBlockNumber())
      await onePlantTreasure.connect(otherAccount).mint();
      console.log("BlockNumber: ", await owner.provider.getBlockNumber())
      const ember = await onePlantTreasure.emberOf(1);
      const uri = await onePlantTreasure.tokenURI(1);
      const pollenEarned = await onePlantTreasure.connect(otherAccount).claimReward.staticCall(1);
      console.log("Index: ", 1,"Ember: ", ember, "URI: ", uri, "Pollen: ", ethers.formatEther(pollenEarned));

      for (let i = 2; i <= 76; i++) {
        await mine(i - 1)
        await onePlantTreasure.connect(otherAccount).mint();
        const ember = await onePlantTreasure.emberOf(i);
        const uri = await onePlantTreasure.tokenURI(i);
        const pollenEarned = await onePlantTreasure.connect(otherAccount).claimReward.staticCall(i);
        console.log("Index: ", i,"Ember: ", ember, "URI: ", uri, "Pollen: ", ethers.formatEther(pollenEarned));
      }
    });

  });
});
