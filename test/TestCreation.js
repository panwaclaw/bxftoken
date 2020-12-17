const BXFToken = artifacts.require("BXFToken");

contract("BXFToken", accounts => {
    it("CreationAccounts test", async function() {

        let instance = await BXFToken.deployed();
        await instance.grantRole(await instance.MIGRATION_MANAGER_ROLE(), accounts[0]);
        await instance.grantRole(await instance.SALE_MANAGER_ROLE(), accounts[0]);
        await instance.finishAccountMigration({from: accounts[0]});

        let isCreated = [];
        await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[0]});
        isCreated[0] = await instance.hasAccount(accounts[0]);

        for (let i = 1; i < accounts.length; i++) {
          await instance.createAccount(accounts[0], {from: accounts[i]});
          isCreated[i] = await instance.hasAccount(accounts[i]);
        }

        assert.equal(isCreated.length, accounts.length, "not all accounts were registered");
        for (let i = 0; i < isCreated.length; i++) assert.equal(isCreated[i], true, i.toString() + " not created");
    });
})