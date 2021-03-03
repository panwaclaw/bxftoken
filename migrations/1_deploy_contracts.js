let BXFToken = artifacts.require("BXFToken");
const Web3 = require('web3');
const rpcURL = 'http://127.0.0.1:7545'


module.exports = async function(deployer, network, accounts) {
  let name = "BXFToken";
  let symbol = "BXF"
  if (network === "ropsten") {
    name = "BXFTokenRopsten"
    symbol = "BXFTR"
  }
  if (network === "development") {
    name = "BXFTokenDev"
    symbol = "BXFTD"
  }

  await deployer.deploy(BXFToken, name, symbol);
  let instance = await BXFToken.deployed();
  /*await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
  let batchSize = 21;
  let batches = [];
  let counter = 0;
  for (const [key, value] of Object.entries(users)) {
      if (counter % batchSize === 0) {
          batches.push([])
      }
      batches[(counter - counter % batchSize) / batchSize].push({
          account: key,
          sponsor: value.sponsor,
          tokensToMint: web3.utils.toWei(value.tokensToMint.toString(), "ether").toString(),
          directPartnersCount: value.directPartners,
          indirectPartnersCount: value.indirectPartners,
      })
      counter += 1;
  }
  console.log('Migrating data to blockchain');
  for (let i = 0; i < batches.length; i++) {
      console.log(i + 1, '/', batches.length);
      await instance.migrateAccountsInBatch(batches[i], {from: accounts[0]});
  }
  console.log('Finishing data migration');
  await instance.finishAccountMigration({from: accounts[0]});*/
};