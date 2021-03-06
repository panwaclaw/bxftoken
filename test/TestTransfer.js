const web3 = require('web3');
const helpers = require('./helpers');

contract("BXFToken", accounts => {
    it("staking test", async function() {
        let instance = await helpers.Deploy(accounts);

        await instance.startSale({from: accounts[0]});
        let balances = [];
        let distribution = [];
        for (let i = 0; i < accounts.length; i++) {
            await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[i]});
        }

        await instance.buy({from: accounts[0], value: web3.utils.toWei("1", "ether")});
        for (let j = 0; j < 2; j++) {
            balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
            distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf.call(accounts[j])).toString(), "ether");
        }
        console.log(balances);
        console.log(distribution);

        await instance.transfer(accounts[1], web3.utils.toWei(balances[0], "ether"), {from: accounts[0]});
        for (let j = 0; j < 2; j++) {
            balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
            distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf.call(accounts[j])).toString(), "ether");
        }
        console.log(balances);
        console.log(distribution);

        await instance.sell(web3.utils.toWei(balances[1], "ether"), {from: accounts[1]})
        for (let j = 0; j < 2; j++) {
            balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
            distribution[j] = web3.utils.fromWei((await instance.distributionBonusOf.call(accounts[j])).toString(), "ether");
        }
        console.log(balances);
        console.log(distribution);
        //assert.ok(returnedAmount < web3.utils.toWei("0.63", "ether"), "Staking works wrong");
    });
})
