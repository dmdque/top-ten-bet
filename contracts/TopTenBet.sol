pragma solidity ^0.4.18;


import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";


/// @title TopTenBet
/// @author dmdque
/// @notice Bet that top 10 market cap will shift by next year between Ari and Stefano
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
  event TransitionState(State from, State to);

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
      TransitionState(State.Setup, State.Fund);
    } else if(_state == State.Fund) {
      if(_balances[_ari] == _betAmount &&
           _balances[_stefano] == _betAmount) {
        _state = State.Vote;
        TransitionState(State.Fund, State.Vote);
      }
    } else if(_state == State.Vote) {
      uint ariVoteCount;
      uint stefanoVoteCount;
      (ariVoteCount, stefanoVoteCount) = tallyVotes();
      if (ariVoteCount >= QUORUM || stefanoVoteCount >= QUORUM) {
        _state = State.Payout;
        TransitionState(State.Vote, State.Payout);
      }
    } else if(_state == State.Payout) {
      _state = State.End;
      TransitionState(State.Payout, State.End);
    }
  }

  /// @param ari Ari's address
  /// @param stefano Stefano's address
  /// @param payoutAri Address where payout should go if Ari wins
  /// @param stefano Address where payout should go if Stefano wins
  /// @param oracle1 First oracle's address (2 of 3 are Ari and Stefano)
  /// @param oracle2 Second oracle's address (2 of 3 are Ari and Stefano)
  /// @param oracle3 Third oracle's address (2 of 3 are Ari and Stefano)
  /// @param endDate The datetime that the three oracles can begin voting for the winner
  /// @param expiryDate The datetime after which the bettors can withdraw their money, a suggested value for this is a week or two
  /// @param betAmount The exact amount that each party has to bet
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

  /// @notice For the bettors, this function lets you fund the contract - and requires that you send the exact amount required
  /// @notice Once both parties call this, the bet is active
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

  /// @notice Allow the three oracles to vote for Ari or Stefano (2 of the 3 are Ari and Stefano)
  /// @notice Oracles can alter their vote as long as a quorum hasn't been reached
  /// @param vote Vote is an enum where 0 indicates Ari wins and 1 indicates Stefano wins
  function oracleVote(VoteOption vote)
    public
    onlyAfterEndDate
    onlyOracle
    onlyState(State.Vote)
  {
    _oracleVotes[msg.sender] = VoteInfo(true, vote);
    Vote(msg.sender, vote);
    transitionState();
  }

  /// @dev Tallies votes and returns the result
  /// @return (ariVoteCount, stefanoVoteCount) The number of votes for each bettor
  function tallyVotes() internal view returns (uint ariVoteCount, uint stefanoVoteCount) {
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

  /// @dev Returns the winner
  /// @return winner Address of the winner
  function determineWinner() internal view returns (address winner) {
    uint ariVoteCount;
    uint stefanoVoteCount;
    (ariVoteCount, stefanoVoteCount) = tallyVotes();
    if (ariVoteCount >= QUORUM) {
      return _ari;
    } else if (stefanoVoteCount >= QUORUM) {
      return _stefano;
    }
  }

  /// @notice Settles the bet between Ari and Stefano by counting votes made by the three oracles
  /// @notice At the end, the winner is paid the total balance in the contract
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

  /// @dev Refunds balances to bettors
  function refund() internal {
    uint ariRefund = _balances[_ari];
    uint stefanoRefund = _balances[_stefano];
    _balances[_ari] = 0;
    _balances[_stefano] = 0;
    _ari.transfer(ariRefund);
    _stefano.transfer(stefanoRefund);
  }

  /// @notice Refund in case no quorum is reached. Only Stefano or Ari can call this, once the expiry date has been reached
  /// @notice Both initial bets are refunded if this is called
  function expiryRefund()
    external
    onlyBettor
    onlyState(State.Vote)
  {
    require(now >= _expiryDate);
    refund();
    TransitionState(_state, State.End);
    _state = State.End;
  }

  /// @notice Refund for catastrophic scenario, only owner can call this - but at anytime
  /// @notice Funds are returned to Ari and Stefano
  function panicRefund()
    external
    onlyOwner
    {
      refund();
      TransitionState(_state, State.End);
      _state = State.End;
   }

}
