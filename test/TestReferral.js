const BXFToken = artifacts.require("BXFToken");

contract("BXFToken", accounts => {
    it("first test", async function() {
        let instance = await BXFToken.deployed();
        let isCreated = [];
        console.log(accounts);
        await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[0]});
        isCreated[0] = await instance.hasAccount(accounts[0]);
        for (let i = 1; i < accounts.length; i++) {
          await instance.createAccount(accounts[0], {from: accounts[i]});
          isCreated[i] = await instance.hasAccount(accounts[i]);
        }
        assert.equal(isCreated.length, accounts.length, "not all accounts were registered");
        for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");
    })
})