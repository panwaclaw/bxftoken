const web3 = require('web3');
const helpers = require('./helpers');
const config = require('./config');

async function getSumSubtree(accountIndex, parents, accounts, startAccountIndex, instance){
  let res = 0;
  if (accountIndex !== startAccountIndex) {
    res += Number(web3.utils.fromWei(await instance.selfBuyOf.call(accounts[accountIndex]), "ether"));
  }

  for (let i = 0; i < parents.length; i++) if (parents[i] === accountIndex) {
    res += await getSumSubtree(i, parents, accounts, startAccountIndex, instance);
  }
  return res;
}

async function getRank(accountIndex, parents, accounts, instance) {
  let maxChildTurnover = 0;
  for (let i = 0; i < accounts.length; i++) if (parents[i] === accountIndex){
    let selfBuy = Number(web3.utils.fromWei(await instance.selfBuyOf.call(accounts[i]), "ether"));
    maxChildTurnover = Math.max(maxChildTurnover, await getSumSubtree(i, parents, accounts, i, instance) + selfBuy);
  }
  let turnover = await getSumSubtree(accountIndex, parents, accounts, accountIndex, instance)
  let selfBuy = Number(web3.utils.fromWei(await instance.selfBuyOf.call(accounts[accountIndex]), "ether"));

  let rank = 0;
  for (let i = 0; i < config.RANKS.length; i++){
    if (selfBuy >= config.RANKS[i][0] &&
        turnover >= config.RANKS[i][1] &&
        turnover * config.RANKS[i][3]/100 >= maxChildTurnover - 1e-6){
          rank = i;
        }
  }
  return rank;
}

contract("BXFToken", accounts => {
  it("Rank and Turnover test", async function () {
    let instance = await helpers.Deploy(accounts);
    const contractAddress = await instance.address;

    let parents = [ -1, 0, 0, 1, 2, 3, 3, 1, 6, 7 ];
    parents = await helpers.createTree(instance, accounts, contractAddress, parents);
    console.log('tree:', parents);

    await instance.startSale({from: accounts[0]});

    /* finding tree list */
    let isList = [];
    isList = isList.fill(0);
    for (let i = 0; i < accounts.length; i++) isList[parents[i]] += 1;
    let lists = [];
    for (let i = 0; i < accounts.length; i++) if (isList[i] === 0){
      lists.push(i);
    }

    let transactions = await helpers.generateTransaction(accounts, config.TRANSACTION_AMOUNT , instance);
    for (let i = 0; i < transactions.length; i++) {
      let oldRanks = []
      for (let i = 0; i < accounts.length; i++){
        oldRanks.push(Number(await instance.rankOf(accounts[i])));
      }

      if (transactions[i][0] === "buy"){
        let accountIndex = transactions[i][1];
        let numberEther = transactions[i][2];
        console.log("add to ", accountIndex, "-", numberEther, "ether");
        await instance.buy({from: accounts[accountIndex], value: web3.utils.toWei(numberEther.toString(), "ether")});
      } else {
        let accountIndex = transactions[i][1];
        let numberTokens = await helpers.getCanSell(accounts, accountIndex, instance);
        if (numberTokens === 0) continue;
        console.log("sell from ", accountIndex, "-", numberTokens, "tokens");
        await instance.sell(web3.utils.toWei(numberTokens.toString(), "ether"), {from: accounts[accountIndex]});
      }

      for (let account = 0; account < accounts.length; account++) {
        let rank = Math.max(oldRanks[account], Number(await getRank(account, parents, accounts, instance)));
        console.log(rank, '/', Number(await instance.rankOf(accounts[account])));
        assert(Number(await instance.rankOf(accounts[account])) === rank, "rank counting is incorrect")
      }
      let arr = [];
      for (let j = 0; j < accounts.length; j++) {
        arr.push(Number(web3.utils.fromWei(await instance.indirectBonusOf.call(accounts[j]), "ether")));
      }
      console.log('indirectBonus:', arr);

      arr = [];
      for (let j = 0; j < accounts.length; j++) {
        arr.push(Number(await instance.rankOf(accounts[j])));
      }
      console.log("ranks:", arr);
      console.log();
    }
  }).timeout(3600000);
})
