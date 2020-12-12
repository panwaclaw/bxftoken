//import {getRandomInt} from "/test/helpers.js"

const BXFToken = artifacts.require("BXFToken");

function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min)) + min; //Максимум не включается, минимум включается
}

class AccountData {
  constructor(props) {
    /*this.sponsor = ;
    this.balance;
    uint256 selfBuy;
    uint rank;
    uint256 turnover;
    uint256 maxChildTurnover;
    uint256 directBonus;
    uint256 indirectBonus;
    uint256 founderBonus;
    uint256 cryptoRewardBonus;
    uint256 reinvestedAmount;
    uint256 withdrawnAmount;
    int256 distributionBonus;
    */
  }

}

for (let i = 0; i < 5; i++) {
  contract("BXFToken", accounts => {
    let number = i + 1;
    it(number.toString() + " test", async function () {
      let instance = await BXFToken.deployed();
      await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
      await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
      await instance.finishAccountMigration({from: accounts[0]});
      let isCreated = [];
      console.log(accounts);
      await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[0]});
      isCreated[0] = await instance.hasAccount(accounts[0]);
      for (let i = 1; i < accounts.length; i++) {
        await instance.createAccount(accounts[i - 1], {from: accounts[i]});
        isCreated[i] = await instance.hasAccount(accounts[i]);
      }
      let random_number = getRandomInt(0, accounts.length);
      let iterAccount = accounts[random_number];
      console.log('=============');
      let contractAddress = await instance.address;
      let counter = 0;
      while (iterAccount !== contractAddress) {
        console.log(iterAccount);
        counter += 1;
        iterAccount = await instance.sponsorOf(iterAccount);
      }
      assert.equal(counter, random_number + 1, "tree was built wrong");
      assert.equal(isCreated.length, accounts.length, "not all accounts were registered");
      for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");
    });
  })
}
