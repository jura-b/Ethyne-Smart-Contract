pragma solidity ^0.4.18;

contract EthyneEscrow{
  address owner;
  uint256 ethyneRevenue;
  bool isOverrideFees;
  uint overrideFees;

  struct Escrow {
    address seller;
    address buyer;
    bytes16 _tradeID;
    bool _isActive;
    uint _value;
    uint16 _ethyneFees;
  }

  mapping (bytes32 => Escrow) public escrows;

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

  //events
  event LogCreated(
    bytes32 _hashed
    );

  // constructor for escrow
  // setup the owner of the contract
  function EthyneEscrow() public{
    owner = msg.sender;
    overrideFees = 0;
    isOverrideFees = false;
  }

  function createEscrow(
    bytes16 _tradeID,
    address _buyer,
    uint256 _value,
    uint16 _ethyneFees
    ) payable public {
      bytes32 _hashed = keccak256(_tradeID, msg.sender, _buyer, _value, _ethyneFees);
      require(!escrows[_hashed]._isActive);
      require(msg.value > 0 && msg.value == _value);

      escrows[_hashed] = Escrow(
        msg.sender,
        _buyer,
        _tradeID,
        true,
        _value,
        _ethyneFees
      );

      LogCreated(_hashed);
  }

  function release(
    bytes16 _tradeID,
    address _buyer,
    uint256 _value,
    uint16 _ethyneFees
    ) public {
      bytes32 _hashed = keccak256(_tradeID, msg.sender, _buyer, _value, _ethyneFees);
      require(escrows[_hashed]._isActive);
      LogCreated(_hashed);

      transferToBuyerWithFees(escrows[_hashed].buyer, escrows[_hashed]._value, escrows[_hashed]._ethyneFees);
    }

  function transferToBuyerWithFees(address _to, uint256 _value, uint _fees) private returns (uint256){
      uint256 _finalFees = 0;
      if(!isOverrideFees){
        _finalFees = (_value * _fees/10000);
        require(_value - _finalFees < _value);
      } else {
        _finalFees = overrideFees;
      }
      ethyneRevenue = _finalFees + ethyneRevenue;
      _to.transfer(_value - _finalFees);
  }

  // the function below this line will be related to the company

  function setOwner(address _newOwner) onlyOwner external {
    //Change the owner of the contract
    //Can be called by owner only
    owner = _newOwner;
  }

  // withdraw the revenue from trading to specific account
  function getRevenue() onlyOwner returns(uint256) {
    return ethyneRevenue;
  }

  function withdrawRevenue(address _to, uint256 _amount) onlyOwner {
    require(_amount < ethyneRevenue);
    ethyneRevenue = ethyneRevenue - _amount;
    _to.transfer(_amount);
  }

  // Change the overrideFees when we have a promo/or in beta test
  function setOverrideFees(uint16 _newOverrideFees) onlyOwner {
    overrideFees = _newOverrideFees;
  }

}
