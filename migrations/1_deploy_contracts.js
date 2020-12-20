let BXFToken = artifacts.require("BXFToken");

module.exports = function(deployer) {
    deployer.deploy(BXFToken, "BXFTokenTest", "BXFT");
};