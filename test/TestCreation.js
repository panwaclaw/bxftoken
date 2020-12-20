const helpers = require('./helpers');

contract("BXFToken", accounts => {
    it("CreationAccounts test", async function() {
        let instance = await helpers.Deploy(accounts);
        const contractAddress = await instance.address;
        let parents = await helpers.createTree(instance, accounts, contractAddress);
        if (parents) console.log("OK");
    });
})