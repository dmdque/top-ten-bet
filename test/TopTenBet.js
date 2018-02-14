// TODO:
// use time freezing library for testing

const TopTenBet = artifacts.require('TopTenBet');

const BigNumber = web3.BigNumber;

var topTenBet;

contract('TopTenBet', function([owner, ari, stefano, payoutAri, payoutStefano, oracle1, oracle2, oracle3]) {

  // Setup
  let nowDate = new Date();
  // endDate is in the past to ensure
  let endDate = parseInt(new Date(nowDate.getTime() - 30*1000).getTime() / 1000);
  let expiryDate = parseInt(new Date(nowDate.getTime() + 5*60*1000).getTime() / 1000);
  let betAmount = 1*10**18;

  beforeEach(async () => {
    try {
      topTenBet = await TopTenBet.new(
        ari,
        stefano,
        payoutAri,
        payoutStefano,
        oracle1,
        oracle2,
        oracle3,
        endDate,
        expiryDate,
        betAmount,
        {from: owner}
      );
    } catch (e) {
      console.error(e.stack);
    }
  });

  // # Unit tests

  it('should be properly initialized', async () => {
    let state = await topTenBet._state();
    assert.equal(state.toNumber(), new BigNumber(1));
  });

  it('should fund bettors and advance the state', async () => {
    await topTenBet.fund({from: ari, value: betAmount});
    await topTenBet.fund({from: stefano, value: betAmount});

    let ariBalance = await topTenBet._balances(ari);
    let stefanoBalance = await topTenBet._balances(stefano);
    let state = await topTenBet._state();

    assert.equal(ariBalance.toNumber(), betAmount);
    assert.equal(stefanoBalance.toNumber(), betAmount);
    assert.equal(state, 2);
  });

  it('should not fund a bettor more than once', async () => {
    await topTenBet.fund({from: ari, value: betAmount});
    // todo: assert throw
    await topTenBet.fund({from: ari, value: betAmount});

    let ariBalance = await topTenBet._balances(ari);

    assert.equal(ariBalance.toNumber(), betAmount);
  });

  it('should not fund a bettor an amount other than betAmount', async () => {
    // todo: assert throw
    await topTenBet.fund({from: ari, value: 5*10**18});

    let ariBalance = await topTenBet._balances(ari);

    assert.equal(ariBalance.toNumber(), 0);
  });


  // only ari and stefano can fund
  // # Integration tests

  it('should work for happy case', async () => {
    let payoutAriBalance = await web3.eth.getBalance(payoutAri);
    let payoutStefanoBalance = await web3.eth.getBalance(payoutStefano);

    await topTenBet.fund({from: ari, value: betAmount});
    await topTenBet.fund({from: stefano, value: betAmount});
    await topTenBet.oracleVote(0, {from: oracle1});
    await topTenBet.oracleVote(0, {from: oracle2});
    await topTenBet.oracleVote(0, {from: oracle3});
    await topTenBet.payout()

    let ariBalance = await topTenBet._balances(ari);
    let payoutAriFinalBalance = await web3.eth.getBalance(payoutAri);
    let payoutStefanoFinalBalance = await web3.eth.getBalance(payoutStefano);

    assert.equal(payoutAriFinalBalance.toNumber() - payoutAriBalance.toNumber(), 2 * betAmount);
  });

});
