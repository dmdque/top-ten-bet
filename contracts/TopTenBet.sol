// Bet that top 10 market cap will shift by next year.

// TODO:
// - make payout go directly to charity addresses
//   - add state variable and modify setup with charity addresses

pragma solidity ^0.4.17;


// Usage
// setup() -> bet() -> bet() -> wait -> settle()
contract TopTenBet {


  mapping (address => uint) public balances;
  address public owner = msg.sender;
  // pros of storing as address[2] bettors?
  address public alice;
  address public bob;
  // could remove these in favour of simple if statement that balances are nonzero
  bool public isAliceFunded;
  bool public isBobFunded;
  uint public endDate;
  // this should probably be a mapping instead
  // mapping (address => bool, VoteOption) public
  address[5] public oracles;
  bool[5] public haveOraclesVoted;  // still not sure about "is" naming convention for bools
  enum VoteOption {Alice, Bob}
  VoteOption[5] public oracleVotes;
  bool public areBettorsSetup;
  bool public isEndDateSetup;
  bool public areOraclesSetup;

  // Requires that function is being called by contract owner
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  // Sets up the bet by setting up bettors, oracles, and end date
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
    uint _endDate
  ) public onlyOwner {
    setupBettors(_alice, _bob);
    setupOracles(_oracle1, _oracle2, _oracle3, _oracle4, _oracle5);
    setupEndDate(_endDate);
  }


  // Sets up bettors with their addresses and sets areBettorsSetup to true
  // only alice and bob can participate
  // todo: setup charity addresses
  function setupBettors(address _alice, address _bob) public onlyOwner {
    alice = _alice;
    bob = _bob;
    areBettorsSetup = true;
  }

  // Sets up oracle addresses
  // can this accept an array address[4] instead?
  function setupOracles(
    address _oracle1,
    address _oracle2,
    address _oracle3,
    address _oracle4,
    address _oracle5
  ) public onlyOwner {
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
    areOraclesSetup = true;
  }

  // Sets up bet end date
  function setupEndDate(uint _endDate) public onlyOwner {
    endDate = _endDate;
    isEndDateSetup = true;
  }

  // Checks that setup is properly completed
  function isSetup() returns (bool) {
    return areBettorsSetup && areOraclesSetup && isEndDateSetup;
  }

  // need better name
  // basically is everything ready
  function isValid() returns (bool) {
    return isSetup() && isAliceFunded && isBobFunded;
  }

  // Allows bettors to make their bets
  // todo: add state variable set in setup to check that both bettors bet the same amount
  // is it good practice to return isSuccess?
  // todo: should I limit betting to only once?
  function bet() public payable returns (bool isSuccess) {
    if (msg.sender == alice) {
      balances[alice] += msg.value;
      isAliceFunded = true;
      return true;
    } else if (msg.sender == bob) {
      balances[bob] += msg.value;
      isBobFunded = true;
      return true;
    } else {
      return false;
    }
  }

  // Settles the bet between alice and bob by counting votes made by oracles
  // Returns whether the settle is a success
  // is there a way to auto trigger this once the time has elapsed?
  function settle() returns (bool isSuccess) {
    // Perform checks, in order of increasing cost
    if (now < endDate) {
      return false;
    }
    if (!isValid()) {
      // in this case, alice and bob should check to ensure things are set up
      // properly, or have the contract owner refund and cancel the contract
      return false;
    }
    bool _isSuccess;
    address winner;
    (_isSuccess, winner) = determineWinner();
    if (!_isSuccess) {
      return false;
    }
    if (winner == alice) {
      if (alice.send(this.balance)) {
        balances[alice] = 0;
      }
    } else if (winner == bob) {
      if (bob.send(this.balance)) {
        balances[bob] = 0;
      }
    }
  }

  // Checks who the winner is
  // Returns the winner's address
  // TODO: return the winner's charity's address
  function determineWinner() returns (bool isSuccess, address winner) {
    // TODO: doesn't necessarily need all votes if a majority is already reached

    if (!haveAllOraclesVoted()) {
      return (false, address(0));
    }
    uint _aliceVoteCount = 0;
    uint _bobVoteCount = 0;
    for (uint i = 0; i < oracleVotes.length; i++) {
      if (oracleVotes[i] == VoteOption.Alice) {
        _aliceVoteCount += 1;
      } else if (oracleVotes[i] == VoteOption.Bob) {
        _bobVoteCount += 1;
      }
    }
    // Assumes there can be no ties since there are an odd number of oracles
    if (_aliceVoteCount > _bobVoteCount) {
      return (true, alice);
    } else if (_bobVoteCount > _aliceVoteCount) {
      return (true, bob);
    }
  }

  // Checks if all oracles voted
  // Returns whether all oracles have voted
  function haveAllOraclesVoted() returns (bool) {
    for (uint i = 0; i < haveOraclesVoted.length; i++) {
      if(!haveOraclesVoted[i]) {
        return false;
      }
    }
    return true;
  }

  // Allow oracles to vote for Alice or Bob
  // Oracles can only vote once
  // Returns whether vote was successfully recorded
  function oracleVote(VoteOption _vote) returns (bool isSuccess) {
    bool _isContained;
    uint _index;
    // this can be simplified with a mapping from oracles to whether they voted
    // and the vote
    (_isContained, _index) = arrayVoteOptionsContains(oracles, msg.sender);
    if (!_isContained) {
      return false;
    }
    bool _hasOracleVoted = haveOraclesVoted[_index];
    if (_hasOracleVoted) {
      return false;
    }
    oracleVotes[_index] = _vote;
    haveOraclesVoted[_index] = true;
    return true;
  }

  // TODO: kill and refund functions

  // --
  // Tools
  // Checks if item is contained in array
  // Returns whether item is contained in array
  function arrayVoteOptionsContains(
    address[5] _oracles,
    address _oracle
  ) returns (bool isContained, uint index) {
    for (uint i = 0; i < _oracles.length; i++) {
      if (_oracles[i] == _oracle) {
        return (true, i);
      }
    }
    return (false, 0);  // is it possible to not return a value, and have it default to zero-values? ie. return (false, )
  }

}
