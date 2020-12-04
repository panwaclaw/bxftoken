const BXFToken = artifacts.require("BXFToken");

contract("BXFToken", accouts => {
    it("first test", () =>
        BXFToken.deployed().then(instance => {
            instance.registerAccount.call(accouts[0], 0);
            for (let i = 1; i < accouts.length; i++) instance.registerAccount.call(accouts[i], accouts[0]);
            return addresses
        })
    )
})