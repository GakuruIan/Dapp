const VotingDapp = artifacts.require("VotingDApp");

module.exports = function (deployer){
    deployer.deploy(VotingDapp)
}