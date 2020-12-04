const BXFToken = artifacts.require("BXFToken");

contract("BXFToken", accounts => {
    it("first test", async function() {
        let instance = await BXFToken.deployed();
        let isCreated = [];
        console.log(accounts);
        console.log(accounts[0]);
        await instance.registerAccount(accounts[0], "0x0000000000000000000000000000000000000000", {from: accounts[0]});
        isCreated[0] = await instance.hasRegistered(accounts[0]);
        for (let i = 1; i < accounts.length; i++) {
          await instance.registerAccount(accounts[i], accounts[0], {from: accounts[i]});
          isCreated[i] = await instance.hasRegistered(accounts[0]);
          console.log(isCreated);
        }
        for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");
    })
})