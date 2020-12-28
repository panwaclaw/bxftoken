const web3 = require('web3');
const helpers = require('./helpers');

contract("BXFToken", accounts => {
  it("LineTree test", async function () {

    let instance = await helpers.Deploy(accounts);
    const contractAddress = await instance.address;

    await helpers.createTree(instance, accounts, contractAddress);
    await instance.startSale({from: accounts[0]});

    /* Adding 3 founders */
    for (let i = 0; i < 3; i++){
      let randomNumber = helpers.getRandomInt(1, accounts.length);
      await instance.addFounder(accounts[randomNumber]);
      let isFounder = await instance.isFounder(accounts[randomNumber])
      assert(isFounder === true, "something wrong with Founders add");
    }


    for (let test = 1; test < 100; test++) {
      console.log("test:", test);
      let random_number = helpers.getRandomInt(1, accounts.length);
      let account = accounts[random_number];
      let sponsor = await instance.sponsorOf(account);
      let sponsorSelfBuy  = web3.utils.fromWei(await instance.selfBuyOf.call(sponsor), "ether");

      let oldCompanyBalance = Number(web3.utils.fromWei(await instance.companyBalance.call(), "ether"));
      let oldSelfBuyOf = Number(web3.utils.fromWei(await instance.selfBuyOf.call(account), "ether"));
      let oldDirectBonus = Number(web3.utils.fromWei(await instance.directBonusOf.call(sponsor), "ether"));
      let oldFoundersBonus = 0;
      let founderNumber = 0;
      for (let i = 0; i < accounts.length; i++) if (await instance.isFounder(accounts[i])) {
        founderNumber += 1;
        oldFoundersBonus += Number(web3.utils.fromWei(await instance.founderBonusOf(accounts[i]), "ether"));
      } else {
        oldFoundersBonus += 0;
      }


      let etherNumber = 1;
      await instance.buy({from: account, value: web3.utils.toWei(etherNumber.toString(), "ether")});


      let newSelfBuyOf = Number(web3.utils.fromWei((await instance.selfBuyOf.call(account)), "ether"));
      let newCompanyBalance = Number(web3.utils.fromWei(await instance.companyBalance.call(), "ether"));
      let newDirectBonus = Number(web3.utils.fromWei(await instance.directBonusOf.call(sponsor), "ether"));
      let newFoundersBonus = 0;
      for (let i = 0; i < accounts.length; i++) if (await instance.isFounder(accounts[i])) {
        newFoundersBonus += Number(web3.utils.fromWei(await instance.founderBonusOf(accounts[i]), "ether"));
      } else {
        newFoundersBonus += 0;
      }

      /* Check add 30% to Company Balance */
      console.log("check Company Balance")
      console.log(oldCompanyBalance, "/", newCompanyBalance);
      let mustBe = Number(oldCompanyBalance) + 0.3 * etherNumber;
      assert(Math.abs(mustBe - newCompanyBalance) < 1e-7, "Company balance wrong");
      console.log("OK");

      /* Check add 10% to Sponsor */
      if (sponsor !== instance.address && sponsorSelfBuy > 0.05) {
        console.log("check sponsor bonus");
        console.log(oldDirectBonus, "/", newDirectBonus);
        mustBe = Number(oldDirectBonus) + 0.1 * etherNumber;
        assert(Math.abs(mustBe - newDirectBonus) < 1e-7, "Sponsor balance wrong");
        console.log("OK");
      }

      /* Check add 1% to Founder */
      if (founderNumber !== 0){
        console.log("check founder bonus");
        console.log(oldFoundersBonus, "/", newFoundersBonus);
        mustBe = Number(oldFoundersBonus) + 0.01 * etherNumber;
        assert(Math.abs(mustBe - newFoundersBonus) < 1e-7, "Founder balance wrong");
        console.log("OK");
      }

      /* Check accout Balance */
      console.log("check account balance");
      console.log(oldSelfBuyOf, "/", newSelfBuyOf);
      mustBe = Number(oldSelfBuyOf) + etherNumber;
      assert(mustBe === newSelfBuyOf, "account balance wrong");

      /* Check deleting from founder when selling */
      console.log("Check deleting from founder when selling");
      for (let i = 0; i < accounts.length; i++) if (await instance.isFounder(accounts[i])) {
        await instance.buy({from: accounts[i], value: web3.utils.toWei(etherNumber.toString(), "ether")});
        let numberTokens = await helpers.getCanSell(accounts, i, instance);
        await instance.sell(web3.utils.toWei(numberTokens.toString(), "ether"), {from: accounts[i]});
        let isFounder = await instance.isFounder(accounts[i]);
        assert(isFounder === false, "founder not deleted when sell");
        console.log("OK");
      }
    }
  });
})
