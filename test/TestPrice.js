const BXFToken = artifacts.require("BXFToken");
const Web3 = require('web3');
const rpcURL = 'http://127.0.0.1:7545'
const web3 = new Web3(rpcURL);

contract("BXFToken", accounts => {
    it("price test", async function() {
        let instance = await BXFToken.deployed();
        await instance.grantRole(await instance.ACCOUNT_MANAGER_ROLE(), accounts[0]);
        await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
        await instance.finishAccountMigration({from: accounts[0]});
        await instance.startSale({from: accounts[0]});
        for (let i = 0; i < 1; i++) {
            await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[i]});
        }

        let invest_array = [2,2,2,2,1,1,1,1,1,1,1,1,1,1,(210.5375155674769878650051285)/0.41];
        for (let k in invest_array) {
            console.log(invest_array[k]);
            let result = await instance.buy({from: accounts[0], value: web3.utils.toWei(invest_array[k].toString(), "ether")});
            let totalSupply = await instance.totalSupply()
            console.log(web3.utils.fromWei(totalSupply, 'wei'), web3.utils.fromWei(totalSupply, 'ether'));
        }
        /*console.log(result);
        result = await instance.reinvest(web3.utils.toWei("0.01", "ether"), {from: accounts[0]});
        console.log(result);
        result = await instance.withdraw(web3.utils.toWei("0.01", "ether"), {from: accounts[0]});
        console.log(result);
        result = await instance.sell(web3.utils.toWei("1000", "ether"), {from: accounts[0]});
        console.log(result);*/
    }).timeout(36000000);
})
