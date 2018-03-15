var EthyneEscrow = artifacts.require("./EthyneEscrow.sol");

module.exports = function(deployer) {
  deployer.deploy(EthyneEscrow);
}
