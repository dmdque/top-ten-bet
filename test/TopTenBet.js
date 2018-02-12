// TODO:
// use time freezing library for testing

const TopTenBet = artifacts.require('TopTenBet');

const BigNumber = web3.BigNumber;

var topTenBet;

contract('TopTenBet', function([owner, alice, bob, charityA, charityB, oracle1, oracle2, oracle3]) {

  // Setup
  let nowDate = new Date();
  // endDate is in the past to ensure
  let endDate = parseInt(new Date(nowDate.getTime() - 30*1000).getTime() / 1000);
  let expiryDate = parseInt(new Date(nowDate.getTime() + 5*60*1000).getTime() / 1000);
  let betAmount = 1*10**18;

  beforeEach(async () => {
    try {
      console.log(
        endDate,
        expiryDate,
        betAmount,
      );
      topTenBet = await TopTenBet.new(
        alice,
        bob,
        charityA,
        charityB,
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

  it('should be properly initialized', async () => {
    let state = await topTenBet.state();
    assert.equal(state.toNumber(), new BigNumber(1));
  });

  it('should fund bettors and advance the state', async () => {
    await topTenBet.fund({from: alice, value: betAmount});
    await topTenBet.fund({from: bob, value: betAmount});

    let aliceBalance = await topTenBet.balances(alice);
    let bobBalance = await topTenBet.balances(bob);
    let state = await topTenBet.state();

    assert.equal(aliceBalance.toNumber(), betAmount);
    assert.equal(bobBalance.toNumber(), betAmount);
    assert.equal(state, 2);
  });

  it('should not fund a bettor more than once', async () => {
    topTenBet.fund({from: alice, value: betAmount});
    // todo: assert throw
    topTenBet.fund({from: alice, value: betAmount});

    let aliceBalance = await topTenBet.balances(alice);

    assert.equal(aliceBalance.toNumber(), betAmount);
  });

  it('should not fund a bettor an amount other than betAmount', async () => {
    // todo: assert throw
    topTenBet.fund({from: alice, value: 5*10**18});

    let aliceBalance = await topTenBet.balances(alice);

    assert.equal(aliceBalance.toNumber(), 0);
  });

});
