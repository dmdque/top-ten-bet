# TopTenBet
## Motivation
Smart contract for bet that TokenEconomy mused about in one of their newsletters.

https://tokeneconomy.co/token-economy-30-gazing-into-the-crypstal-ball-3a02cf9fe778

> Stefano's personal prediction is that 2018 is the year it all comes crashing down. We are surely building the future and witnessing a revolution, but we’re doing so at the ground floor of the biggest casino ever invented and sometime soon it will close its doors and kick everyone out to go and build in their dusty garages.
>
> So, I think that aside from BTC and ETH, all of the other TOP 10 coins will disappear into oblivion. Staked 10 ETH for charity with Ari on Twitter as he took the over. (BTW, if you can help us write a smart escrow contract for this, we’d be happy to donate a part of the 10 ETH to a charity of your choosing).
>
> Yannick instead thinks we’re still at the very, very early days and the capital influx has just started.

## Testing
Automated tests are in progress, but a manual integration test can be run. Note, this test matches addresses from my Ganache instance.

    $ truffle compile
    $ truffle migrate
    $ truffle console
    >
    TopTenBet.deployed().then(instance => ttb = instance)
    ttb.setup("0xf17f52151ebef6c7334fad080c5704d77216b732", "0xc5fdf4076b8f3a5357c5e395ab970b5b54098fef", "0x821aea9a577a9b44299b9c15c88cf3087f3b5544", "0x0d1d4e623d10f9fba5db95830f7d3839406c6af2", "0x2932b7a2355d6fecc4b5c0b6bd44cc31df247a2e", "0x2191ef87e392377ec08e7c08eb105ef5448eced5", "0x0f4f2ac550a1b4e2280d04c21cea7ebd822934b5", 1517133054)
    ttb.bet({from: "0xf17f52151EbEF6C7334FAD080c5704D77216b732", value: 10*10**18})
    ttb.bet({from: "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef", value: 10*10**18})

    ttb.oracleVote(0, {from: "0x821aEa9a577a9b44299B9c15c88cf3087F3b5544"})
    ttb.oracleVote(1, {from: "0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2"})
    ttb.oracleVote(0, {from: "0x2932b7A2355D6fecc4b5c0B6BD44cC31df247a2e"})
    ttb.oracleVote(0, {from: "0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5"})
    ttb.oracleVote(0, {from: "0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5"})

    // checks
    // ttb.haveAllOraclesVoted.call()
    // ttb.determineWinner.call()
    ttb.settle()
