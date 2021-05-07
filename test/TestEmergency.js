const helpers = require('./helpers');


contract("BXFToken", accounts => {
  it("Test Emergency test", async function() {
    let instance = await helpers.Deploy(accounts);
    const contractAddress = await instance.address;
    //let parents = await helpers.createTree(instance, accounts, contractAddress);

    for (let i = 0; i < accounts.length; i++) {
      await instance.createAccount("0x0000000000000000000000000000000000000000", {from: accounts[i]});
    }

    await instance.addFounder(accounts[2], {from: accounts[0]});
    await instance.addFounder(accounts[5], {from: accounts[0]});
    await instance.addFounder(accounts[7], {from: accounts[0]});

    await instance.grantRole(await instance.EMERGENCY_MANAGER_ROLE(), accounts[9], {from: accounts[0]});

    await instance.sendTransaction({from: accounts[0], to: contractAddress, value: web3.utils.toWei('30', "ether")});

    await instance.startEmergencyVote(2, {from: accounts[9]});
    await instance.voteForEmergencyCase({from: accounts[2]});
    await instance.voteForEmergencyCase({from: accounts[5]});

    await instance.emergencyContractBalanceWithdraw({from: accounts[9]});

    //if (parents) console.log("OK");
  });
})