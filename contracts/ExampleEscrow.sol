// https://github.com/James-Sangalli/Solidity-Contract-Examples/blob/master/contracts/misc/escrow.sol
pragma solidity ^0.4.18;

contract ExampleEscrow{

  mapping (address => uint) public balances;

  address public seller;
  address public buyer;
  address public escrow = msg.sender;
  bool public sellerApprove;
  bool public buyerApprove;

  function setup(address s, address b){
    if(msg.sender == escrow){
        seller = s;
        buyer = b;
    }
  }

  function approve(){
    if(msg.sender == buyer) buyerApprove = true;
    else if(msg.sender == seller) sellerApprove = true;
    if(sellerApprove && buyerApprove) fee();
  }

  function abort(){ if(msg.sender == buyer) buyerApprove = false;
      else if (msg.sender == seller) sellerApprove = false;
      if(!sellerApprove && !buyerApprove) refund();
  }

  function payOut(){
    if(seller.send(this.balance)) balances[buyer] = 0;
  }

  function deposit() payable {
      if(msg.sender == buyer) balances[buyer] += msg.value;
      else throw;
  }

  function killContract() internal {
      selfdestruct(escrow);
      //kills contract and returns funds to buyer
  }

  function refund(){
    if(buyerApprove == false && sellerApprove == false) selfdestruct(buyer);
    //send money back to recipient if both parties agree contract is void
  }

  function fee(){
      escrow.send(this.balance / 100); //1% fee
      payOut();
  }

}
