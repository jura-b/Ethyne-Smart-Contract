pragma solidity ^0.4.18;

contract EthyneEscrow{
  address owner;
  uint256 revenue;

  modifier onlyOwer(){
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
    uint256 _value,
    uint32 _expireTime
    ) public{
      require(msg.sender > 0 && msg.sender == _value);
      require(block.timestamp < _expireTime);
      
  }

  // the function below this line will be related to the company

  function setOwner(address _newOwner) onlyOwner external {
    //Change the owner of the contract
    //Can be called by owner only
    owner = _newOwner;
  }

  // withdraw the revenue from trading to specific account
  function withdrawRevenue(address _to, uint256 _amount) {
    require(_amount < revenue);
    revenue = revenue - _amount;
    _to.transfer(_amount);
  }

}
