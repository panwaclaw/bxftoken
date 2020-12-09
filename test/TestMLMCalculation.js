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

for (let i = 0; i < 3; i++) {
  contract("BXFToken", accounts => {
    let number = i + 1;
    it(number.toString() + " test", async function () {
      let instance = await BXFToken.deployed();
      instance.finishAccountMigration()
      let balances = {};
      console.log(accounts);
      await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[0]});
      isCreated[0] = await instance.hasAccount(accounts[0]);
      for (let i = 1; i < accounts.length; i++) {
        let random_number = getRandomInt(0, i)
        await instance.createAccount(accounts[random_number], {from: accounts[i]});
        isCreated[i] = await instance.hasAccount(accounts[i]);
      }
      assert.equal(isCreated.length, accounts.length, "not all accounts were registered");
      for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");
    });
  })
}
