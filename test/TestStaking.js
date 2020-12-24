const Web3 = require('web3');
const rpcURL = 'http://127.0.0.1:7545'
const web3 = new Web3(rpcURL);
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

        let investedAmount = 90;
        for (let i = 0; i < accounts.length; i++) {
            console.log('Buy:', i + 1, '/', accounts.length)
            //console.log(web3.utils.fromWei((await instance.buyPrice.call()).toString(), "ether"), web3.utils.fromWei((await instance.sellPrice.call()).toString(), "ether"))
            await instance.buy({from: accounts[i], value: web3.utils.toWei(investedAmount.toString(), "ether")});
            for (let j = 0; j < accounts.length; j++) {
                balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
                distribution[j] = web3.utils.fromWei((await instance.stakingBonusOf.call(accounts[j])).toString(), "ether");
            }
            console.log(balances);
            console.log(distribution);
        }

        for (let i = 0; i < accounts.length; i++) {
            console.log('Sell:', i + 1, '/', accounts.length)
            //console.log(web3.utils.fromWei((await instance.buyPrice.call()).toString(), "ether"), web3.utils.fromWei((await instance.sellPrice.call()).toString(), "ether"))
            let result = await instance.sell((await instance.balanceOf.call(accounts[i])).toString(), {from: accounts[i]});
            //console.log(result);
            for (let j = 0; j < accounts.length; j++) {
                balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
                distribution[j] = web3.utils.fromWei((await instance.stakingBonusOf.call(accounts[j])).toString(), "ether");
            }
            console.log(balances);
            console.log(distribution);
        }

        //console.log(web3.utils.fromWei((await instance.buyPrice.call()).toString(), "ether"), web3.utils.fromWei((await instance.sellPrice.call()).toString(), "ether"))
        let returnedAmount = balances.reduce((a, b) => parseFloat(a) + parseFloat(b), 0);
        let r2 = distribution.reduce((a, b) => parseFloat(a) + parseFloat(b), 0);
        console.log(web3.utils.fromWei((await web3.eth.getBalance(instance.address)).toString(), "ether"), returnedAmount, r2);
        assert.ok(r2 < investedAmount * accounts.length * 0.16, "Staking works wrong");
    });
})
