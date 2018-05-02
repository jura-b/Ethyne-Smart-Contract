pragma solidity ^0.4.18;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EthyneEscrow{
  using SafeMath for uint;
  using SafeMath for uint256;
  
  address public owner;
  address public relayer;
  uint256 public ethyneCollectedFees;
  bool public  isOverrideFees;
  uint public overrideFees;

  uint constant ETHYNE_FEES = 10;
  uint8 constant STAGE_SELLER_CREATE_ESCROW = 0x01;
  uint8 constant STAGE_BUYER_CONFIRM_TX = 0x02;

  struct Escrow {
    address _seller;
    address _buyer;
    bytes16 _tradeID;
    bool _isActive;
    uint _value;
    uint8 _stage;
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
  function EthyneEscrow() public{
    owner = msg.sender;
    overrideFees = 0;
    isOverrideFees = false;
  }

  function createEscrow(
    bytes16 _tradeID,
    address _buyer,
    uint256 _value
    ) payable public {
      address _seller = msg.sender;
      bytes32 _hashed = keccak256(_tradeID, _seller, _buyer, _value);
      require(msg.sender == _seller);
      require(!escrows[_hashed]._isActive);
      require(msg.value > 0 && msg.value == _value);

      escrows[_hashed] = Escrow(
        msg.sender,
        _buyer,
        _tradeID,
        true,
        _value,
        STAGE_SELLER_CREATE_ESCROW
      );

      LogCreated(_hashed);
  }

  function release(
    bytes16 _tradeID,
    address _buyer,
    uint256 _value
    ) public {
      bytes32 _hashed = keccak256(_tradeID, msg.sender, _buyer, _value);
      require(escrows[_hashed]._isActive);
      transferWithFees(escrows[_hashed]._buyer, escrows[_hashed]._value, ETHYNE_FEES);
      escrows[_hashed]._isActive = false;
      delete escrows[_hashed];
    }

  /* Seller cancelled the trade.
  ** Condition:
  ** Buyer must not confirm the transactino on ethyne.network yet.
  ** 1) If seller willing to cancel BEFORE buyer confirm tx, then let him cancel.
  ** 2) If seller willing to cancel AFTER buyer confirm tx, then relay is needed.
  ** Aftermath:
  ** 1) The trade must be cancelled and remove the trade out of array.
  ** 2) If the function called by relayer, the trade must be removed.
  */
  function sellerCancelTrade(
    bytes16 _tradeID,
    address _seller,
    address _buyer,
    uint256 _value
    ) public {
      bytes32 _hashed = keccak256(_tradeID, _seller, _buyer, _value);
      require(escrows[_hashed]._isActive);
      if(escrows[_hashed]._stage == STAGE_SELLER_CREATE_ESCROW) {
        require(escrows[_hashed]._stage == STAGE_SELLER_CREATE_ESCROW);
        require(escrows[_hashed]._seller == msg.sender);
        escrows[_hashed]._isActive = false;
        delete escrows[_hashed];
      } else {
        require(escrows[_hashed]._stage == STAGE_BUYER_CONFIRM_TX);
        require(msg.sender == relayer);
        escrows[_hashed]._isActive = false;
        delete escrows[_hashed];
      }
      transferWithFees(_seller, _value, ETHYNE_FEES);
  }

  /* Confirm that buyer already transfer fiat to the seller.
  ** Condition:
  ** The trade must be at the STAGE_SELLER_CREATE_ESCROW only.
  ** Only buyer can confirm the transaction.
  ** Aftermath:
  ** The stage of the trade must be updated.
  */
  function buyerConfirmTx(
    bytes16 _tradeID,
    address _buyer,
    uint256 _value
    ) public {
      bytes32 _hashed = keccak256(_tradeID, msg.sender, _buyer, _value);
      require(escrows[_hashed]._isActive);
      require(escrows[_hashed]._buyer == msg.sender);
      require(escrows[_hashed]._stage == STAGE_SELLER_CREATE_ESCROW);
      escrows[_hashed]._stage = STAGE_BUYER_CONFIRM_TX;
  }

  /* Buyer cancel the trade.
  ** Condition:
  ** The trade must be at the STAGE_SELLER_CREATE_ESCROW only.
  ** Only buyer can called this function
  ** Aftermath:
  ** Return ETH back to seller.
  ** Remove the trade out of array.
  */
  function buyerCancelTrade(
    bytes16 _tradeID,
    address _seller,
    address _buyer,
    uint256 _value
    ) public {
      bytes32 _hashed = keccak256(_tradeID, _seller, _buyer, _value);
      require(escrows[_hashed]._isActive);
      if(escrows[_hashed]._stage == STAGE_SELLER_CREATE_ESCROW) {
        require(escrows[_hashed]._stage == STAGE_SELLER_CREATE_ESCROW);
        require(escrows[_hashed]._buyer == msg.sender);
        escrows[_hashed]._isActive = false;
        delete escrows[_hashed];
      } else {
        require(escrows[_hashed]._stage == STAGE_BUYER_CONFIRM_TX);
        require(msg.sender == relayer);
        escrows[_hashed]._isActive = false;
        delete escrows[_hashed];
      }
      transferWithFees(_seller, _value, ETHYNE_FEES);
  }

  function transferWithFees(address _to, uint256 _value, uint _fees) private {
      uint256 _finalFees = 0;
      if(!isOverrideFees){
        _finalFees = _value.mul(_fees).div(10000);
        require(_value.sub(_finalFees) < _value); // prevent overflow/underflow
      } else {
        _finalFees = overrideFees;
      }
      ethyneCollectedFees = _finalFees.add(ethyneCollectedFees);
      _to.transfer(_value.sub(_finalFees));
  }

  // :=== the functions below this line will be related to the company ===:

  function setOwner(address _newOwner) onlyOwner external {
    //Change the owner of the contract
    //Can be called by owner only
    owner = _newOwner;
  }

  // withdraw the revenue from trading to specific account
  function getRevenue() onlyOwner view external returns(uint256) {
    return ethyneCollectedFees;
  }

  function withdrawRevenue(address _to, uint256 _amount) onlyOwner external {
    require(_amount < ethyneCollectedFees);
    ethyneCollectedFees = ethyneCollectedFees.sub(_amount);
    _to.transfer(_amount);
  }

  // Change the overrideFees when we have a promo/or in beta test
  // override fees will not be ever over ETHYNE_FEES
  function setOverrideFees(uint16 _newOverrideFees) onlyOwner external {
    require(ETHYNE_FEES > _newOverrideFees);
    overrideFees = _newOverrideFees;
  }

}
