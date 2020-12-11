const BXFToken = artifacts.require("BXFToken");
const web3 = require('web3');

contract("BXFToken", accounts => {
    it("staking test", async function() {
        let instance = await BXFToken.deployed();
        await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
        await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
        await instance.finishAccountMigration({from: accounts[0]});
        await instance.startSale({from: accounts[0]});
        for (let i = 0; i < 3; i++) {
            await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[i]});
        }
        let result1 = await instance.send(web3.utils.toWei("1", "ether"), {from: accounts[1]});
        console.log("first transaction");
        console.log(result1);
        console.log("after first transaction\n==================")
        console.log(web3.utils.fromWei((await instance.balanceOf(accounts[1])).toString(), "ether" ));
        console.log(web3.utils.fromWei((await instance.balanceOf(accounts[2])).toString(), "ether" ));
        console.log(web3.utils.fromWei((await instance.distributionBonusOf(accounts[1])).toString(), "ether" ));
        console.log(web3.utils.fromWei((await instance.distributionBonusOf(accounts[2])).toString(), "ether" ));
        let result2 = await instance.send(web3.utils.toWei("1", "ether"), {from: accounts[2]});

        console.log("second transaction");
        console.log(result2);
        console.log("after second transaction\n==================")
        console.log(web3.utils.fromWei((await instance.balanceOf(accounts[1])).toString(), "ether" ));
        console.log(web3.utils.fromWei((await instance.balanceOf(accounts[2])).toString(), "ether" ));
        console.log(web3.utils.fromWei((await instance.distributionBonusOf(accounts[1])).toString(), "ether" ));
        console.log(web3.utils.fromWei((await instance.distributionBonusOf(accounts[2])).toString(), "ether" ));
    });
})