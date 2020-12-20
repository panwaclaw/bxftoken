const web3 = require('web3');
const helpers = require('./helpers');


contract("BXFToken", accounts => {
  it("Rank & Turnover test", async function () {
    let instance = await helpers.Deploy(accounts);
    const contractAddress = await instance.address;

    let parents = await helpers.createTree(instance, accounts, contractAddress);
    await instance.startSale({from: accounts[0]});

    /* finding tree list */
    let isList = [];
    isList = isList.fill(0);
    for (let i = 0; i < accounts.length; i++) isList[parents[i]] += 1;
    let lists = [];
    for (let i = 0; i < accounts.length; i++) if (isList[i] === 0){
      lists.push(i);
    }

    console.log("check indirect bonus");
    console.log('tree:');
    console.log(parents);
    console.log('indirectBonus:');
    for (let i = 0; i < accounts.length; i++) {
      console.log(Number(web3.utils.fromWei(await instance.indirectBonusOf.call(accounts[i]), "ether")));
    }
    console.log('ranks:');
    for (let i = 0; i < accounts.length; i++) console.log(await instance.rankOf(accounts[i]));
  });
})