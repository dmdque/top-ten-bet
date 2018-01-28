// Bet that top 10 market cap will shift by next year.

// TODO:
// - make payout go directly to charity addresses
//   - add state variable and modify setup with charity addresses
// Notes:
// - prepend _ to state variables

pragma solidity ^0.4.17;

// does it have to be exactly 10 ETH?

contract TopTenBet {

  mapping (address => uint) public _balances;
  address public _owner = msg.sender;
  // pros of storing as address[2] bettors?
  address public _alice;
  address public _bob;
  // initialized as false
  // other good names: _arePuntersSetup or _isBettorSetup?
  // https://english.stackexchange.com/questions/221086/what-do-you-call-a-person-placing-bets?newreg=fd96d96dafa344abac3f0b64e9ff4e78
  bool public _isBettorSetup;
  bool public _isOracleSetup;
  // could remove these in favour of simple if statement that _balances are nonzero
  bool public _isAliceFunded;
  bool public _isBobFunded;
  address[5] _oracles;
  uint _endDate;

  //modifier isOwner {
    //msg.sender == owner
    //_;
  //}

  // need a way for them to choose which side of the bet they're on
  // -> this can be hardcoded: alice always bets outcome A
  // or an enum can be supplied in setup()
  // or enum can be supplied in bet(), but would have to check it's valid ie. they're not betting the same thing
  function setup(
    address alice,
    address bob,
    address oracle1,
    address oracle2,
    address oracle3,
    address oracle4,
    address oracle5,
    uint endDate,
  ) public {
    setupBettors(alice, bob);
    setupOracles(oracle1, oracle2, oracle3, oracle4, oracle5);
    _endDate = endDate;
    _isEndDateSetup = true;
  }

  function isSetup() {
    return _isBettorSetup && _isOracleSetup && _isEndDateSetup;
  }

  // need better name
  // bascially is everything ready
  function isValid() {
    return isSetup() && _isAliceFunded && _isBobFunded;
  }

  // only alice and bob can participate
  function setupBettors(address alice, address bob) public {
    require isOwner(msg.sender) {
      _alice = alice;
      _bob = bob;
      _isBettorSetup = true;
    }
  }

  // can this accept an array address[4] instead?
  function setupOracles(
    address oracle1,
    address oracle2,
    address oracle3,
    address oracle4,
    address oracle5,
  ) public {
    // todo: check that none of these addresses are "0x0"
    // check that they're all unique (not required)
    //   actually kinda required since if there's a collision, only the
    //   one that appears first will get to vote, due to sequence of ifs
    // check that none are the same as alice or bob
    oracles[0] = oracle1;
    oracles[1] = oracle2;
    oracles[2] = oracle3;
    oracles[3] = oracle4;
    oracles[4] = oracle5;
    _isOracleSetup = true;
  }

  // what should this return?
  // could add state variable set in setup, and check so that both bettors bet the same amount
  function bet() public payable {
    if (msg.sender == _alice) {
      _balances[_alice] += msg.value;
      _isAliceFunded = true;
    } else if (msg.sender == _bob) {
      _balances[_alice] += msg.value;
      _isBobFunded = true;
    } else {
      throw;  // todo: this is outdated
    }
  }

  // is there a way to auto trigger this once the time has elapsed?
  function settle() {
    // do a bunch of checks
    if (now < _endDate) {
      revert;  // is this right?
    }
    if (!isValid()) {
      // return money to owners
      // and halt
      throw;
    }
    if (!isOraclesVoted()) {
      throw;
    }
    address winner = determineWinner();
    if (winner == _alice) {
      if (_alice.send(this.balance)) {
        _balances[_alice] = 0;
      }
    } else if (winner == _bob) {
      if (_bob.send(this.balance)) {
        _balances[_bob] = 0;
      }
    } else {
      // dunno wat
    }
  }

  // check winner
  function determineWinner() {
    // oracle magic
    // oracles can only vote after time has elapsed
  }

  // have all oracles voted
  function isOraclesVoted() bool {
    // todo
  }

}
