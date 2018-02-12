var TopTenBet = artifacts.require("TopTenBet");

module.exports = function(deployer, _, accounts) {
  let nowDate = new Date();
  let endDate = new Date(nowDate.getTime() + 30*1000).getTime() / 1000;
  let expiryDate = new Date(nowDate.getTime() + 5*60*1000).getTime() / 1000;
  let betAmount = 10*10**18;
  deployer.deploy(
    TopTenBet,
    accounts[1],
    accounts[2],
    accounts[3],
    accounts[4],
    accounts[5],
    accounts[6],
    accounts[7],
    endDate,
    expiryDate,
    betAmount);
};
