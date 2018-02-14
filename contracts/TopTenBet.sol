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

  enum VoteOption {
    Ari,  // 0
    Stefano  // 1
  }
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
  address public _ari;
  address public _stefano;
  address public _payoutAri;
  address public _payoutStefano;
  address[3] public _oracles;
  mapping (address => VoteInfo) public _oracleVotes;
  uint public _betAmount;
  uint public _endDate;
  uint public _expiryDate;
  State public _state;
  uint QUORUM = 2;

  event Fund(address bettor, uint amount);
  event Vote(address oracle, VoteOption vote);
  event Payout(address winner, address winnerPayout, uint amount);

  modifier onlyBettor() {
    require(msg.sender == _ari || msg.sender == _stefano);
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
      if(_balances[_ari] == _betAmount &&
           _balances[_stefano] == _betAmount) {
        _state = State.Vote;
      }
    } else if(_state == State.Vote) {
      uint ariVoteCount;
      uint stefanoVoteCount;
      (ariVoteCount, stefanoVoteCount) = tallyVotes();
      if (ariVoteCount >= QUORUM || stefanoVoteCount >= QUORUM) {
        _state = State.Payout;
      }
    } else if(_state == State.Payout) {
      _state = State.End;
    }
  }

  function TopTenBet(
    address ari,
    address stefano,
    address payoutAri,
    address payoutStefano,
    address oracle1,
    address oracle2,
    address oracle3,
    uint endDate,
    uint expiryDate,
    uint betAmount
  ) public {
    require(ari != address(0));
    require(stefano != address(0));
    require(payoutAri != address(0));
    require(payoutStefano != address(0));
    require(oracle1 != address(0));
    require(oracle2 != address(0));
    require(oracle3 != address(0));
    require(expiryDate > endDate);

    _ari = ari;
    _stefano = stefano;
    _payoutAri = payoutAri;
    _payoutStefano = payoutStefano;
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
    Fund(msg.sender, msg.value);
    transitionState();
  }

  // Allow oracles to vote for Ari or Stefano
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
    Vote(msg.sender, vote);
    transitionState();
  }

  // TODO: make internal before deploy
  function tallyVotes() view returns (uint ariVoteCount, uint stefanoVoteCount) {
    for (uint i = 0; i < _oracles.length; i++) {
      VoteInfo memory voteInfo = _oracleVotes[_oracles[i]];
      if (!voteInfo.didVote) {
        continue;
      }
      if(voteInfo.vote == VoteOption.Ari) {
        ariVoteCount = ariVoteCount.add(1);
      } else if (voteInfo.vote == VoteOption.Stefano) {
        stefanoVoteCount = stefanoVoteCount.add(1);
      }
    }
    return (ariVoteCount, stefanoVoteCount);
  }

  // Returns the winner
  // TODO: make internal before deploy
  function determineWinner() view returns (address winner) {
    uint ariVoteCount;
    uint stefanoVoteCount;
    (ariVoteCount, stefanoVoteCount) = tallyVotes();
    if (ariVoteCount >= QUORUM) {
      return _ari;
    } else if (stefanoVoteCount >= QUORUM) {
      return _stefano;
    }
  }

  // Settles the bet between ari and stefano by counting votes made by oracles
  // Returns whether the payout is a success
  // is there a way to auto trigger this once the time has elapsed?
  function payout()
    public
    onlyState(State.Payout)
  {
    address winner = determineWinner();
    address winnerPayout;
    if (winner == _ari) {
      winnerPayout = _payoutAri;
    } else if (winner == _stefano) {
      winnerPayout = _payoutStefano;
    }
    assert(winnerPayout != address(0));

    uint payoutAmount = this.balance;
    _balances[_ari] = 0;
    _balances[_stefano] = 0;
    winnerPayout.transfer(payoutAmount);
    Payout(winner, winnerPayout, payoutAmount);
    transitionState();
  }

  // Refunds balances to bettors
  function refund() internal {
    uint ariRefund = _balances[_ari];
    uint stefanoRefund = _balances[_stefano];
    _balances[_ari] = 0;
    _balances[_stefano] = 0;
    _ari.transfer(ariRefund);
    _stefano.transfer(stefanoRefund);
  }

  // Refund in case no quorum is reached
  function expiryRefund()
    external
    onlyBettor
    onlyState(State.Vote)
  {
    require(now >= _expiryDate);
    refund();
    _state = State.End;
  }

  // Refund for catastrophic scenario
  function panicRefund()
    external
    onlyOwner
   {
     refund();
    _state = State.End;
   }

}
