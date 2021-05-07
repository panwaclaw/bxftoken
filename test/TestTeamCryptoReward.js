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
        //await instance.setStakingFee((0).toString(), {from: accounts[0]});

        let totalInvested = 0;

        for (let i = 0; i < accounts.length; i++) {
            let investedAmount = helpers.getRandomInt(1, 50);
            totalInvested += investedAmount;
            console.log('Buy:', i + 1, '/', accounts.length, 'Investing:', investedAmount, 'ETH');
            let st_fee = helpers.getRandomInt(1, 20);
            //console.log('New Staking Fee', st_fee)
            //await instance.setStakingFee((st_fee).toString(), {from: accounts[0]});

            await instance.buy({from: accounts[i], value: web3.utils.toWei(investedAmount.toString(), "ether")});
        }

        for (let j = 0; j < accounts.length; j++) {
            balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
            distribution[j] = web3.utils.fromWei((await instance.stakingBonusOf.call(accounts[j])).toString(), "ether");
        }
        console.log(balances);
        console.log(distribution);
        let distribution_sum = distribution.reduce((a, b) => parseFloat(a) + parseFloat(b), 0);
        console.log(distribution_sum)

        let toDistribute = 10;

        console.log('Tryin to distribute', toDistribute, 'ETH');

        await instance.teamCryptoRewardDistribution({from: accounts[0], value: web3.utils.toWei(toDistribute.toString(), "ether")});

        for (let j = 0; j < accounts.length; j++) {
            balances[j] = web3.utils.fromWei((await instance.balanceOf.call(accounts[j])).toString(), "ether");
            distribution[j] = web3.utils.fromWei((await instance.stakingBonusOf.call(accounts[j])).toString(), "ether");
        }
        //console.log(balances);
        let distribution_sum_new = distribution.reduce((a, b) => parseFloat(a) + parseFloat(b), 0);
        console.log(distribution);

        console.log(distribution_sum, distribution_sum_new, toDistribute);
        //assert.ok(contractBalance - r2 >= companyBalance, "Staking works wrong");
    }).timeout(36000000);
})
