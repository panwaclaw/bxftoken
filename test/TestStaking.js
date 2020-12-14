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
            console.log('Buy:', i + 1, '/', accounts.length)
            console.log(web3.utils.fromWei((await instance.buyPrice.call()).toString(), "ether"), web3.utils.fromWei((await instance.sellPrice.call()).toString(), "ether"))
            await instance.send(web3.utils.toWei("10", "ether"), {from: accounts[i]});
            for (let j = 0; j < accounts.length; j++) {
                balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
                distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf.call(accounts[j])).toString(), "ether");
            }
        }
        for (let i = 0; i < accounts.length ; i++) {
            console.log('Sell:', i + 1, '/', accounts.length)
            console.log(web3.utils.fromWei((await instance.buyPrice.call()).toString(), "ether"), web3.utils.fromWei((await instance.sellPrice.call()).toString(), "ether"))
            let r = await instance.sell((await instance.balanceOf(accounts[i])).toString(), {from: accounts[i]});
            for (let j = 0; j < accounts.length; j++) {
                balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
                distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf.call(accounts[j])).toString(), "ether");
            }
        }
        let returnedAmount = distribution.reduce((a, b) => parseFloat(a) + parseFloat(b), 0);
        console.log(distribution);
        console.log(returnedAmount);
        assert.ok(returnedAmount < 70, "Staking works wrong");
    });
})
