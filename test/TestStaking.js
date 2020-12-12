const BXFToken = artifacts.require("BXFToken");
const web3 = require('web3');

contract("BXFToken", accounts => {
    it("staking test", async function() {
        let instance = await BXFToken.deployed();
        await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
        await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
        await instance.finishAccountMigration({from: accounts[0]});
        await instance.startSale({from: accounts[0]});
        let balances = [];
        let distribution = [];
        for (let i = 0; i < accounts.length; i++) {
            await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[i]});
        }
        for (let i = 0; i < accounts.length; i++) {
            await instance.send(web3.utils.toWei("1", "ether"), {from: accounts[i]});
            for (let j = 0; j < accounts.length; i++) {
                balances[j] = web3.utils.fromWei((await instance.balanceOf(accounts[j])).toString(), "ether");
                distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf(accounts[j])).toString(), "ether");
            }
            console.log("==================");
            console.log(i + 1, '/', accounts.length);
            console.log('------------------');
            console.log(balances);
            console.log(distribution);
        }
        console.log("");
        console.log("EXIT");
        console.log("");
        for (let i = 0; i < accounts.length; i++) {
            await instance.exit({from: accounts[i]});
            for (let j = 0; j < accounts.length; i++) {
                balances[j] = web3.utils.fromWei((await instance.balanceOf(accounts[j])).toString(), "ether");
                distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf(accounts[j])).toString(), "ether");
            }
            console.log("==================");
            console.log(i + 1, '/', accounts.length);
            console.log('------------------');
            console.log(balances);
            console.log(distribution);
        }
    });
})
