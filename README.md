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
### Automated Testing

    truffle test

### Manual Testing
Note, this test matches addresses from my Ganache instance.

    $ truffle compile
    $ truffle migrate
    $ truffle console
    >
    TopTenBet.deployed().then(instance => ttb = instance)
    ttb.fund({from: "0xf17f52151EbEF6C7334FAD080c5704D77216b732", value: 10*10**18})
    ttb.fund({from: "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef", value: 10*10**18})

    ttb.oracleVote(0, {from: "0x2932b7A2355D6fecc4b5c0B6BD44cC31df247a2e"})
    ttb.oracleVote(0, {from: "0x2191eF87E392377ec08E7c08Eb105Ef5448eCED5"})
    ttb.oracleVote(0, {from: "0x0F4F2Ac550A1b4e2280d04c21cEa7EBD822934b5"})

    ttb.payout()

## Usage
### Owner
See the [deployment](#deployment) section.

### Bettor (Draft)

- call fund()
- wait
- call oracleVote(vote)
  - Ari: 0
  - Stefano: 1
- call payout()

## Deployment
TBD

## Documentation

### State Machine
The state machine is as follows:

    setup -> fund -> (implicit wait) -> vote -> payout -> end


### VoteOption
Since VoteOption is an enum, the votes are encoded. A vote for Ari is `0`, and a vote for Stefano is `1`.

### Expiry Date
After the `expiryDate`, both bettors can call `personalAbort()` to recover their funds. Please note that after the expiry date, a bettor that knows they've lost the vote can call `personalAbort()` to recover their funds. Both parties must be vigilant about calling `payout()` after `endDate` and before `expiryDate`.


## Discussion
- `panicRefund()` can be removed at the request of TE.


# Notes
- Events for transitionState
- Could add explicit wait state, and let oracleVote transition out f time satisfies
  - but then transition state doesn't become the only source of state changes.
- Timed voting period
