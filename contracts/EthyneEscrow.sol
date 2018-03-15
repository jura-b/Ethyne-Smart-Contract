pragma solidity ^0.4.18;

contract EthyneEscrow{
  address owner;
  uint256 ethyneRevenue;
  uint escrowCounter;

  struct Escrow {
    address seller;
    address buyer;
    bytes16 _tradeID;
    uint _value;
  }

  mapping (uint => Escrow) escrows;

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  // constructor for escrow
  // setup the owner of the contract
  function EthyneEscrow() public{
    owner = msg.sender;
  }

  function createEscrow(
    bytes16 _tradeID,
    address _buyer,
    uint256 _value
    ) payable public {
      require(msg.value > 0 && msg.value == _value);

      escrowCounter++;
      escrows[escrowCounter] = Escrow(
        msg.sender,
        _buyer,
        _tradeID,
        _value
      );
  }

  // the function below this line will be related to the company

  function setOwner(address _newOwner) onlyOwner external {
    //Change the owner of the contract
    //Can be called by owner only
    owner = _newOwner;
  }

  // withdraw the revenue from trading to specific account
  function withdrawRevenue(address _to, uint256 _amount) onlyOwner public {
    require(_amount < ethyneRevenue);
    ethyneRevenue = ethyneRevenue - _amount;
    _to.transfer(_amount);
  }

}
