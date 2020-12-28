const web3 = require('web3');
const BXFToken = artifacts.require("BXFToken");

module.exports = {
  getRandomInt: function(min, max){
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min)) + min; //Максимум не включается, минимум включается
  },

  Deploy: async function Deploy(accounts) {
    let instance = await BXFToken.deployed();
    await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
    await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
    await instance.grantRole(await instance.FOUNDER_MANAGER_ROLE(), accounts[0]);
    await instance.finishAccountMigration({from: accounts[0]});
    return instance;
  },

  createTree: async function (instance, accounts, contractAddress, parents = []) {
    let isCreated = [];

    await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[0]});
    isCreated[0] = await instance.hasAccount(accounts[0]);
    parents[0] = -1;

    console.log(parents);
    if (parents.length > 1){
      for (let i = 1; i < accounts.length; i++){
        await instance.createAccount(accounts[parents[i]], {from: accounts[i]});
        isCreated[i] = await instance.hasAccount(accounts[i]);
      }
    } else {
      for (let i = 1; i < accounts.length; i++) {
        let randomNumber = this.getRandomInt(0, i - 1);
        parents[i] = randomNumber;
        await instance.createAccount(accounts[randomNumber], {from: accounts[i]});
        isCreated[i] = await instance.hasAccount(accounts[i]);
      }
    }

    for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");

    /* availability check */
    for (let i = 1; i < accounts.length; i++) {
      let iterAccount = accounts[i];

      let counter = 0;
      while (iterAccount !== contractAddress) {
        counter += 1;
        if (counter > 100) break;
        iterAccount = await instance.sponsorOf(iterAccount);
      }
      assert.equal(iterAccount, contractAddress, "tree was built wrong");
    }

    return parents;
  },

  generateTransaction : async function(accounts, count , instance) {
    let res = [];
    for (let i = 0; i < count; i++) {
      let type = this.getRandomInt(0, 4);
      let account = this.getRandomInt(0, accounts.length);
      if (type <= 2) {
        let tokenAmount = 25 * Math.random();
        res.push(["buy", account, tokenAmount]);
      } else {
        let balanceOf = Number(web3.utils.fromWei(await instance.selfBuyOf.call(accounts[account]), "ether"));
        let index = Math.random();
        res.push(["sell", account, index * balanceOf]);
      }
    }
    return res;
  },

  getCanSell : async  function(accounts, accountIndex, instance){
    let index = Math.random();
    let numberTokens = Number(web3.utils.fromWei(await instance.selfBuyOf.call(accounts[accountIndex]), "ether"));
    numberTokens *= index;
    return numberTokens;
  }
};
