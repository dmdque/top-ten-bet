# TopTenBet
## Motivation
Smart contract for bet that TokenEconomy mused about in one of their newsletters.

https://tokeneconomy.co/token-economy-30-gazing-into-the-crypstal-ball-3a02cf9fe778

> Stefano's personal prediction is that 2018 is the year it all comes crashing down. We are surely building the future and witnessing a revolution, but we’re doing so at the ground floor of the biggest casino ever invented and sometime soon it will close its doors and kick everyone out to go and build in their dusty garages.
>
> So, I think that aside from BTC and ETH, all of the other TOP 10 coins will disappear into oblivion. Staked 10 ETH for charity with Ari on Twitter as he took the over. (BTW, if you can help us write a smart escrow contract for this, we’d be happy to donate a part of the 10 ETH to a charity of your choosing).
>
> Yannick instead thinks we’re still at the very, very early days and the capital influx has just started.

## Documentation
This smart contract sets up a bet between Ari and Stefano. The smart contract is set up as a state machine which transitions from setup to end.

### State Machine
The state machine is as follows:

    setup -> fund -> (implicit wait) -> vote -> payout -> end

### VoteOption
Since VoteOption is an enum, the votes are encoded. A vote for Ari is `0`, and a vote for Stefano is `1`.

### Expiry Date
After the `expiryDate` has passed, either bettor can call `expiryRefund()` to recover their funds. This is meant to be used if a quorum can't be reached for reasons such as an oracle losing their keys.

Note that after the expiry date, a dishonest bettor that knows they've lost the vote can call `expiryRefund()` to recover their funds. For this reason, it's important that oracles vote and `payout()` is called in a timely manner.

### Panic Refund
The `onlyOwner` method `panicRefund` is implemented to mitigate unforeseen complications. It can be removed if unwanted.

## Deployment
- Run `npm install`
- Deploy with a tool like Remix
  - Use `truffle-flattener contracts/TopTenBet.sol | pbcopy` (macOS) to copy contract code
  - Example constructor arguments:

    ```
    "0x1",  // ari
    "0x2",  // stefano
    "0x3",  // payoutAri
    "0x4",  // payoutStefano
    "0x5",  // oracle1
    "0x6",  // oracle2
    "0x7",  // oracle 3
    "1546300800",  // endDate (2019-01-01)
    "1548979200",  // expiryDate (2019-02-01)
    "10000000000000000000"  // 10 ETH in wei
    ```

## Usage
Use a tool like Remix to interact with the contract.

### Bettor
- Call `fund()` with 10 ETH
- Wait for `endDate`
- Wait for oracles to vote
- Call `payout()`

If no quorum is reached after `expiryDate`, call `expiryRefund()` to retrieve funds.

### Oracle
- Wait for `endDate`
- Call `oracleVote(vote)`
  - Vote for Ari: 0
  - Vote for Stefano: 1

## Testing
### Automated Testing

    truffle test

### Manual Testing Reference
Addresses are from the local Ganache instance.

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

## Future Work
- Make oracles dynamic array
- Use time freezing library for testing
- Timed voting period
