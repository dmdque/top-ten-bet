// Bet that top 10 market cap will shift by next year.

// TODO:
// - make payout go directly to charity addresses
//   - add state variable and modify setup with charity addresses

pragma solidity ^0.4.17;


contract TopTenBet {

  mapping (address => uint) public balances;
  address public owner = msg.sender;
  // pros of storing as address[2] bettors?
  address public alice;
  address public bob;
  // could remove these in favour of simple if statement that balances are nonzero
  bool public isAliceFunded;
  bool public isBobFunded;
  bool public areBettorsSetup;
  bool public areOraclesSetup;
  uint public endDate;
  address[5] public oracles;
  bool[5] public haveOraclesVoted;  // still not sure about "is" naming convention for bools
  enum VoteOption {Alice, Bob};
  VoteOption[5] public oracleVotes;

   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

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
  ) public onlyOwner {
    setupBettors(_alice, _bob);
    setupOracles(_oracle1, _oracle2, _oracle3, _oracle4, _oracle5);
    endDate = _endDate;
    isEndDateSetup = true;
  }

  function isSetup() {
    return areBettorsSetup && areOraclesSetup && isEndDateSetup;
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
      areBettorsSetup = true;
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
    areOraclesSetup = true;
  }

  // Allows bettors to make their bets
  // todo: add state variable set in setup to check that both bettors bet the same amount
  // is it good practice to return isSuccess?
  function bet() public payable (bool isSuccess) {
    if (msg.sender == alice) {
      balances[alice] += msg.value;
      isAliceFunded = true;
      return true;
    } else if (msg.sender == bob) {
      balances[alice] += msg.value;
      isBobFunded = true;
      return true;
    } else {
      return false;
    }
  }

  // Settles the bet between alice and bob by counting votes made by oracles
  // Returns whether the settle is a success
  // is there a way to auto trigger this once the time has elapsed?
  function settle() (bool isSuccess) {
    // Perform checks, in order of increasing cost
    if (now < endDate) {
      return false;
    }
    if (!isValid()) {
      // in this case, alice and bob should check to ensure things are set up
      // properly, or have the contract owner refund and cancel the contract
      return false;
    }
    (bool _isSuccess, address winner) = determineWinner();
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
  function determineWinner() (bool isSuccess, address winner) {
    if (!haveAllOraclesVoted()) {
      return (false, address(0));
    }
    uint _aliceVoteCount = 0;
    uint _bobVoteCount = 0;
    for (uint i = 0; i < oracleVotes; i++) {
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
  function haveAllOraclesVoted() bool {
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
  function oracleVote(VoteOption _vote) (bool isSuccess) {
    (bool _isContained, uint _index) = arrayVoteOptionsContains(oracleVotes, _vote);
    if (!_isContained) {
      return false;
    }
    bool _hasOracleVoted = haveOraclesVoted[_index];
    if (_hasOracleVoted) {
      return false;
    }
    oracleVotes[_index] = vote;
    haveOraclesVoted[_index] = true;
    return true;
  }

  // TODO: kill and refund functions

  // --
  // Tools
  // Checks if item is contained in array
  // Returns whether item is contained in array
  function arrayVoteOptionsContains(VoteOption[5] _oracleVotes, VoteOption _vote) (bool isContained, uint index) {
    for (uint i = 0; i < _oracleVotes.length; i++) {
      if (_oracleVotes[i] == vote) {
        return (true, i);
      }
    }
    return (false, 0);  // is it possible to not return a value, and have it default to zero-values? ie. return (false, )
  }

}
