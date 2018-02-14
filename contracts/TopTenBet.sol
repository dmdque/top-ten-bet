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

  mapping (address => uint) public balances;
  address public alice;
  address public bob;
  address public charityA;
  address public charityB;
  address[3] public oracles;
  mapping (address => VoteInfo) public oracleVotes;
  uint public betAmount;
  uint public endDate;
  uint public expiryDate;
  State public state;
  uint QUORUM = 2;

  event LogUInt(uint n);

  modifier onlyBettor() {
    require(msg.sender == alice || msg.sender == bob);
    _;
  }

  modifier onlyOracle() {
    require(msg.sender == oracles[0] ||
            msg.sender == oracles[1] ||
            msg.sender == oracles[2]);
    _;
  }

  modifier onlyAfterEndDate() {
    require(now > endDate);
    _;
  }

  modifier onlyState(State _state) {
    require(state == _state);
    _;
  }

  function transitionState() internal {
    if(state == State.Setup) {
      state = State.Fund;
    } else if(state == State.Fund) {
      if(balances[alice] == betAmount &&
           balances[bob] == betAmount) {
        state = State.Vote;
      }
    } else if(state == State.Vote) {
      uint _aliceVoteCount = 0;
      uint _bobVoteCount = 0;
      for (uint i = 0; i < oracles.length; i++) {
        address voteInfo = oracleVotes[oracles[i]];
        if (!voteInfo.didVote) {
          continue;
        }
        if(voteInfo.vote == VoteOption.Alice) {
          _aliceVoteCount = _aliceVoteCount.add(1);
        } else if (voteInfo.vote == VoteOption.Bob) {
          _bobVoteCount = _bobVoteCount.add(1);
        }
      }
      if (_aliceVoteCount >= QUORUM || _bobVoteCount >= QUORUM) {
        state = State.Payout;
      }
    } else if(state == State.Payout) {
      state = State.End;
    }
  }

  function TopTenBet(
    address _alice,
    address _bob,
    address _charityA,
    address _charityB,
    address _oracle1,
    address _oracle2,
    address _oracle3,
    uint _endDate,
    uint _expiryDate,
    uint _betAmount
  ) public onlyOwner {
    require(_alice != address(0));
    require(_bob != address(0));
    require(_charityA != address(0));
    require(_charityB != address(0));
    require(_oracle1 != address(0));
    require(_oracle2 != address(0));
    require(_oracle3 != address(0));
    require(_expiryDate > _endDate);

    alice = _alice;
    bob = _bob;
    charityA = _charityA;
    charityB = _charityB;
    oracles[0] = _oracle1;
    oracles[1] = _oracle2;
    oracles[2] = _oracle3;
    betAmount = _betAmount;
    endDate = _endDate;
    expiryDate = _expiryDate;

    transitionState();
  }

  // Funds contract with bettor's bet
  function fund()
    public
    payable
    onlyBettor
    onlyState(State.Fund)
  {
    require(msg.value == betAmount);
    require(balances[msg.sender] == 0);
    balances[msg.sender] = msg.value;
    transitionState();
  }

  // Allow oracles to vote for Alice or Bob
  // Oracles can only vote once

  /// @notice
  /// @dev
  /// param
  /// @return
  function oracleVote(VoteOption _vote)
    public
    onlyAfterEndDate
    onlyOracle
    onlyState(State.Vote)
  {
    require(!oracleVotes[msg.sender].didVote);
    oracleVotes[msg.sender] = VoteInfo(true, _vote);

    transitionState();
  }

  // Returns the winner
  function determineWinner() internal view returns (address winner) {
    uint _aliceVoteCount = 0;
    uint _bobVoteCount = 0;
    for (uint i = 0; i < oracles.length; i++) {
      address currentOracle = oracles[i];
      if (oracleVotes[currentOracle].vote == VoteOption.Alice) {
         _aliceVoteCount = _aliceVoteCount.add(1);
      } else if (oracleVotes[currentOracle].vote == VoteOption.Bob) {
        _bobVoteCount = _bobVoteCount.add(1);
      }
    }
    if (_aliceVoteCount >= QUORUM) {
      return alice;
    } else if (_bobVoteCount >= QUORUM) {
      return bob;
    }
  }

  // Settles the bet between alice and bob by counting votes made by oracles
  // Returns whether the payout is a success
  // is there a way to auto trigger this once the time has elapsed?
  function payout()
    public
    onlyState(State.Payout)
  {
    address winner = determineWinner();
    address payout;
    if (winner == alice) {
      payout = charityA;
    } else if (winner == bob) {
      payout = charityB;
    }
    assert(payout != address(0));

    balances[alice] = 0;
    balances[bob] = 0;
    payout.transfer(this.balance);
    transitionState();
  }

  // Refunds balances to bettors
  function abort()
    public
    onlyOwner
  {
    // Update balances before transferring
    uint aliceAmount = balances[alice];
    uint bobAmount = balances[bob];
    balances[alice] = 0;
    balances[bob] = 0;
    alice.transfer(aliceAmount);
    bob.transfer(bobAmount);
    state = State.End;
  }

  // Refunds balance to bettor
  function personalAbort() public onlyBettor {
    require(now >= expiryDate);
    uint amount = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(amount);
    state = State.End;
  }

}
