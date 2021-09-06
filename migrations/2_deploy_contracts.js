var PaymentContract = artifacts.require("PaymentContract");

module.exports = function(deployer) {
  deployer.deploy(PaymentContract);
};