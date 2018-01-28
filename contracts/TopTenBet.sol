// Bet that top 10 market cap will shift by next year.

// TODO:
// - make payout go directly to charity addresses
//   - add state variable and modify setup with charity addresses

pragma solidity ^0.4.17;

// does it have to be exactly 10 ETH?

contract TopTenBet {

  mapping (address => uint) public balances;
  address public owner = msg.sender;
  // pros of storing as address[2] bettors?
  address public alice;
  address public bob;
  // initialized as false
  // other good names: arePuntersSetup or isBettorSetup?
  // https://english.stackexchange.com/questions/221086/what-do-you-call-a-person-placing-bets?newreg=fd96d96dafa344abac3f0b64e9ff4e78
  bool public isBettorSetup;
  bool public isOracleSetup;
  // could remove these in favour of simple if statement that balances are nonzero
  bool public isAliceFunded;
  bool public isBobFunded;
  address[5] oracles;
  uint endDate;

  //modifier isOwner {
    //msg.sender == owner
    //_;
  //}

  // need a way for them to choose which side of the bet they're on
  // -> this can be hardcoded: alice always bets outcome A
  // or an enum can be supplied in setup()
  // or enum can be supplied in bet(), but would have to check it's valid ie. they're not betting the same thing
  function setup(
    address _alice,
    address _bob,
    address _oracle1,
    address _oracle2,
    address _oracle3,
    address _oracle4,
    address _oracle5,
    uint _endDate,
  ) public {
    setupBettors(_alice, _bob);
    setupOracles(_oracle1, _oracle2, _oracle3, _oracle4, _oracle5);
    endDate = _endDate;
    isEndDateSetup = true;
  }

  function isSetup() {
    return isBettorSetup && isOracleSetup && isEndDateSetup;
  }

  // need better name
  // bascially is everything ready
  function isValid() {
    return isSetup() && isAliceFunded && isBobFunded;
  }

  // only alice and bob can participate
  function setupBettors(address _alice, address _bob) public {
    require isOwner(msg.sender) {
      alice = _alice;
      bob = _bob;
      isBettorSetup = true;
    }
  }

  // can this accept an array address[4] instead?
  function setupOracles(
    address _oracle1,
    address _oracle2,
    address _oracle3,
    address _oracle4,
    address _oracle5,
  ) public {
    // todo: check that none of these addresses are "0x0"
    // check that they're all unique (not required)
    //   actually kinda required since if there's a collision, only the
    //   one that appears first will get to vote, due to sequence of ifs
    // check that none are the same as alice or bob
    oracles[0] = _oracle1;
    oracles[1] = _oracle2;
    oracles[2] = _oracle3;
    oracles[3] = _oracle4;
    oracles[4] = _oracle5;
    isOracleSetup = true;
  }

  // what should this return?
  // could add state variable set in setup, and check so that both bettors bet the same amount
  function bet() public payable {
    if (msg.sender == alice) {
      balances[alice] += msg.value;
      isAliceFunded = true;
    } else if (msg.sender == bob) {
      balances[alice] += msg.value;
      isBobFunded = true;
    } else {
      throw;  // todo: this is outdated
    }
  }

  // is there a way to auto trigger this once the time has elapsed?
  function settle() {
    // do a bunch of checks
    if (now < endDate) {
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
    if (winner == alice) {
      if (alice.send(this.balance)) {
        balances[alice] = 0;
      }
    } else if (winner == bob) {
      if (bob.send(this.balance)) {
        balances[bob] = 0;
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
