//import  Deploy  from "/test/helpers.js"

const BXFToken = artifacts.require("BXFToken");
const web3 = require('web3');

function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min)) + min; //Максимум не включается, минимум включается
}

async function Deploy(accounts) {
  let instance = await BXFToken.deployed();
  await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
  await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
  await instance.finishAccountMigration({from: accounts[0]});
  return instance;
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

/*contract("BXFToken", accounts => {
  it("FirstBuy", async function () {
    let instance = Deploy(accounts);


  })
})*/


contract("BXFToken", accounts => {
  it("LineTree test", async function () {

    let instance = await BXFToken.deployed();
    await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
    await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
    await instance.grantRole(await instance.FOUNDER_MANAGER_ROLE(), accounts[0]);
    await instance.finishAccountMigration({from: accounts[0]});

    let isCreated = [];
    await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[0]});
    isCreated[0] = await instance.hasAccount(accounts[0]);

    for (let i = 1; i < accounts.length; i++) {
      await instance.createAccount(accounts[i - 1], {from: accounts[i]});
      isCreated[i] = await instance.hasAccount(accounts[i]);
    }

    for (let i = 0; i < 3; i++){
      let randomNumber = getRandomInt(1, accounts.length);
      await instance.addFounder(accounts[randomNumber]);
      let isFounder = await instance.isFounder(accounts[randomNumber])
      assert(isFounder === true, "something wrong with Founder add");
    }

    for (let test = 1; test < 30; test++) {
      let randomNumber = getRandomInt(0, accounts.length);
      let iterAccount = accounts[randomNumber];

      let contractAddress = await instance.address;
      let counter = 0;
      while (iterAccount !== contractAddress) {
        counter += 1;
        iterAccount = await instance.sponsorOf(iterAccount);
      }
      assert.equal(counter, randomNumber + 1, "tree was built wrong");
      for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");
    }

    await instance.startSale({from: accounts[0]});

    for (let test = 1; test < 30; test++) {
      console.log("test:", test);
      let random_number = getRandomInt(1, accounts.length);
      let account = accounts[random_number];
      let sponsor = await instance.sponsorOf(account);
      let sponsorSelfBuy  = web3.utils.fromWei(await instance.selfBuyOf.call(sponsor), "ether");

      let oldCompanyBalance = Number(web3.utils.fromWei(await instance.companyBalance.call(), "ether"));
      let oldSelfBuyOf = Number(web3.utils.fromWei(await instance.selfBuyOf.call(account), "ether"));
      let oldDirectBonus = Number(web3.utils.fromWei(await instance.directBonusOf.call(sponsor), "ether"));
      let oldFoundersBonus = 0;
      let founderNumber = 0;
      for (let i = 0; i < accounts.length; i++) if (await instance.isFounder(accounts[i])) {
        founderNumber += 1;
        oldFoundersBonus += Number(web3.utils.fromWei(await instance.founderBonusOf(accounts[i]), "ether"));
      } else {
        oldFoundersBonus += 0;
      }

      let etherNumber = 1;
      await instance.send(web3.utils.toWei(etherNumber.toString(), "ether"), {from: account});


      let newSelfBuyOf = Number(web3.utils.fromWei((await instance.selfBuyOf.call(account)), "ether"));
      let newCompanyBalance = Number(web3.utils.fromWei(await instance.companyBalance.call(), "ether"));
      let newDirectBonus = Number(web3.utils.fromWei(await instance.directBonusOf.call(sponsor), "ether"));
      let newFoundersBonus = 0;
      for (let i = 0; i < accounts.length; i++) if (await instance.isFounder(accounts[i])) {
        newFoundersBonus += Number(web3.utils.fromWei(await instance.founderBonusOf(accounts[i]), "ether"));
      } else {
        newFoundersBonus += 0;
      }

      /* Check add 30% to Company Balance */
      console.log("check Company Balance")
      console.log(oldCompanyBalance, "/", newCompanyBalance);
      let mustBe = Number(oldCompanyBalance) + 0.3 * etherNumber;
      assert(Math.abs(mustBe - newCompanyBalance) < 1e-7, "Company balance wrong");
      console.log("OK");

      /* Check add 10% to Sponsor */
      if (sponsor !== instance.address && sponsorSelfBuy > 0.05) {
        console.log("check sponsor bonus");
        console.log(oldDirectBonus, "/", newDirectBonus);
        mustBe = Number(oldDirectBonus) + 0.1 * etherNumber;
        assert(Math.abs(mustBe - newDirectBonus) < 1e-7, "Sponsor balance wrong");
        console.log("OK");
      }

      /* Check add 1% to Founder */
      if (founderNumber !== 0){
        console.log("check founder bonus");
        console.log(oldFoundersBonus, "/", newFoundersBonus);
        mustBe = Number(oldFoundersBonus) + 0.01 * etherNumber;
        assert(Math.abs(mustBe - newFoundersBonus) < 1e-7, "Founder balance wrong");
        console.log("OK");
      }

      /* Check accout Balance */
      console.log("check account balance");
      console.log(oldSelfBuyOf, "/", newSelfBuyOf);
      mustBe = Number(oldSelfBuyOf) + etherNumber;
      assert(mustBe === newSelfBuyOf, "account balance wrong");
    }
  });
})
