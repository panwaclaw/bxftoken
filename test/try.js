const helpers = require('./helpers');


contract("BXFToken", accounts => {
  it("try test", async function() {
    let instance = await helpers.Deploy(accounts);
    const contractAddress = await instance.address;
    await instance.startSale({from: accounts[0]});

    let parents = [-1];
    for (let i = 1; i < accounts.length; i++){
      parents.push(i-1);
    }
    await helpers.createTree(instance, accounts, contractAddress, parents);

    let etherNumber = 1;
    let transaction = {};
    for (let i = 0; i < accounts.length; i++){
      let txInfo = await instance.buy({from: accounts[i], value: web3.utils.toWei(etherNumber.toString(), "ether")});
      transaction[i] = txInfo.receipt.gasUsed;
    }
    console.log(transaction);
  });
})