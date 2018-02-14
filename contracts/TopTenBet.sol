pragma solidity ^0.4.18;


import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


// TODO:
// - make oracles dynamic array
// - do mappings take more storage space than 3 arrays?
// - events

// Bet that top 10 market cap will shift by next year.
/// @title TopTenBet
/// @author dmdque
contract TopTenBet is Ownable {
  using SafeMath for uint;

  enum VoteOption {Alice, Bob}
  enum State {
    Setup,
    Fund,
    // Implicit wait
    Vote,
    Payout,
    End
  }

  struct VoteInfo {
    bool didVote;
    VoteOption vote;
  }

  mapping (address => uint) public _balances;
  address public _alice;
  address public _bob;
  address public _charityA;
  address public _charityB;
  address[3] public _oracles;
  mapping (address => VoteInfo) public _oracleVotes;
  uint public _betAmount;
  uint public _endDate;
  uint public _expiryDate;
  State public _state;
  uint QUORUM = 2;

  event LogUInt(uint n);

  modifier onlyBettor() {
    require(msg.sender == _alice || msg.sender == _bob);
    _;
  }

  modifier onlyOracle() {
    require(msg.sender == _oracles[0] ||
            msg.sender == _oracles[1] ||
            msg.sender == _oracles[2]);
    _;
  }

  modifier onlyAfterEndDate() {
    require(now > _endDate);
    _;
  }

  modifier onlyState(State state) {
    require(_state == state);
    _;
  }

  function transitionState() internal {
    if(_state == State.Setup) {
      _state = State.Fund;
    } else if(_state == State.Fund) {
      if(_balances[_alice] == _betAmount &&
           _balances[_bob] == _betAmount) {
        _state = State.Vote;
      }
    } else if(_state == State.Vote) {
      uint aliceVoteCount = 0;
      uint bobVoteCount = 0;
      for (uint i = 0; i < _oracles.length; i++) {
        VoteInfo memory voteInfo = _oracleVotes[_oracles[i]];
        if (!voteInfo.didVote) {
          continue;
        }
        if(voteInfo.vote == VoteOption.Alice) {
          aliceVoteCount = aliceVoteCount.add(1);
        } else if (voteInfo.vote == VoteOption.Bob) {
          bobVoteCount = bobVoteCount.add(1);
        }
      }
      if (aliceVoteCount >= QUORUM || bobVoteCount >= QUORUM) {
        _state = State.Payout;
      }
    } else if(_state == State.Payout) {
      _state = State.End;
    }
  }

  function TopTenBet(
    address alice,
    address bob,
    address charityA,
    address charityB,
    address oracle1,
    address oracle2,
    address oracle3,
    uint endDate,
    uint expiryDate,
    uint betAmount
  ) public onlyOwner {
    require(alice != address(0));
    require(bob != address(0));
    require(charityA != address(0));
    require(charityB != address(0));
    require(oracle1 != address(0));
    require(oracle2 != address(0));
    require(oracle3 != address(0));
    require(expiryDate > endDate);

    _alice = alice;
    _bob = bob;
    _charityA = charityA;
    _charityB = charityB;
    _oracles[0] = oracle1;
    _oracles[1] = oracle2;
    _oracles[2] = oracle3;
    _betAmount = betAmount;
    _endDate = endDate;
    _expiryDate = expiryDate;

    transitionState();
  }

  // Funds contract with bettor's bet
  function fund()
    public
    payable
    onlyBettor
    onlyState(State.Fund)
  {
    require(msg.value == _betAmount);
    require(_balances[msg.sender] == 0);
    _balances[msg.sender] = msg.value;
    transitionState();
  }

  // Allow _oracles to vote for Alice or Bob
  // Oracles can only vote once

  /// @notice
  /// @dev
  /// param
  function oracleVote(VoteOption vote)
    public
    onlyAfterEndDate
    onlyOracle
    onlyState(State.Vote)
  {
    require(!_oracleVotes[msg.sender].didVote);
    _oracleVotes[msg.sender] = VoteInfo(true, vote);

    transitionState();
  }

  // Returns the winner
  function determineWinner() internal view returns (address winner) {
    uint aliceVoteCount = 0;
    uint bobVoteCount = 0;
    for (uint i = 0; i < _oracles.length; i++) {
      address currentOracle = _oracles[i];
      if (_oracleVotes[currentOracle].vote == VoteOption.Alice) {
         aliceVoteCount = aliceVoteCount.add(1);
      } else if (_oracleVotes[currentOracle].vote == VoteOption.Bob) {
        bobVoteCount = bobVoteCount.add(1);
      }
    }
    if (aliceVoteCount >= QUORUM) {
      return _alice;
    } else if (bobVoteCount >= QUORUM) {
      return _bob;
    }
  }

  // Settles the bet between _alice and _bob by counting votes made by _oracles
  // Returns whether the payout is a success
  // is there a way to auto trigger this once the time has elapsed?
  function payout()
    public
    onlyState(State.Payout)
  {
    address winner = determineWinner();
    address winnerPayout;
    if (winner == _alice) {
      winnerPayout = _charityA;
    } else if (winner == _bob) {
      winnerPayout = _charityB;
    }
    assert(winnerPayout != address(0));

    _balances[_alice] = 0;
    _balances[_bob] = 0;
    winnerPayout.transfer(this.balance);
    transitionState();
  }

  // Refunds balances to bettors
  function abort()
    public
    onlyOwner
  {
    // Update balances before transferring
    uint aliceAmount = _balances[_alice];
    uint bobAmount = _balances[_bob];
    _balances[_alice] = 0;
    _balances[_bob] = 0;
    _alice.transfer(aliceAmount);
    _bob.transfer(bobAmount);
    _state = State.End;
  }

  // Refunds balance to bettor
  function personalAbort() public onlyBettor {
    require(now >= _expiryDate);
    uint amount = _balances[msg.sender];
    _balances[msg.sender] = 0;
    msg.sender.transfer(amount);
    _state = State.End;
  }

}
