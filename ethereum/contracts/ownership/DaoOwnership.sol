pragma solidity 0.4.24;

import '../database/Database.sol';
// @title A contract which allows for multi-sig ownership
// @notice Two owners are required to agree on a function to be called
// @dev An owner has already been initialized when database is deployed
// @author Kyle Dewhurst, MyBit Foundation
contract DaoOwnership {
  Database public database;

  // NOTE: Local contract variables only here as a reference

  // @notice bytes32 key is sha3(contractAddress, methodID)    methodID = bytes4(sha3("functionName(parameterType, parameterType, etc...)) ")
  mapping (bytes32 => uint) public quorumLevel;     // Percentage of how many owners need to sign this function

  // @notice bytes32 key is sha3(contractAddress, methodID, sha3(parameter(s)))
  mapping (bytes32 => bool) public functionCallAuthorized;     // has enough signatures for this contract to call that function
  mapping (bytes32 => uint) public numberOfSignatures; 

  uint public numberOfOwners; 


  constructor(bytes32[] restrictedFunctions, uint[] quorumLevel)
  public { 
    // TODo: set the quorum level for these functions 
  }

  function addOwner(address _newOwner)
  external
  anyOwner {
    database.setBool(keccak256(abi.encodePacked("owner", _newOwner)), true);
  }

  function removeOwner(address _owner)
  external
  anyOwner {
    database.deleteBool(keccak256(abi.encodePacked("owner", _owner)));
  }

  // If restricted it will have to be called from address(this) using a voting proccess on signForFunctionCall
  function addRestrictedFunction(address _contractAddress, bytes4 _methodID, uint _quorumLevel)
  external 
  anyOwner { 
    require(_quorumLevel > 0); 
    bytes32 functionID = keccak256(abi.encodePacked(_contractAddress, _methodID));
    database.setUint(functionID, _quorumLevel); 
  }

  // @param (bytes32) _parameterHash = The hash of the exact parameter to be called for function...ie sha3(0x3b443c34, 55)
  function signForFunctionCall(address _contractAddress, bytes4 _methodID, bytes32 _parameterHash)
  external
  anyOwner {
    bytes32 sigRequestID = keccak256(abi.encodePacked(_contractAddress, _methodID, _parameterHash)); 
  }


  //------------------------------------------------------------------------------------------------------------------
  //                                                Modifiers
  //------------------------------------------------------------------------------------------------------------------


  //------------------------------------------------------------------------------------------------------------------
  // Verifies that sender is an owners
  //------------------------------------------------------------------------------------------------------------------
  modifier anyOwner {
    require(database.boolStorage(keccak256(abi.encodePacked("owner", msg.sender))));
    _;
  }

  modifier isFunctionRestricted(bytes4 _methodID, bytes32 _parameterHash) { 
    if (database.boolStorage(keccak256(abi.encodePacked(address(this), _methodID)))) { 
      require(database.boolStorage(keccak256(abi.encodePacked(address(this), _methodID, _parameterHash))));  // owners must have agreed on function + parameters
    }
    _;
  }

  //------------------------------------------------------------------------------------------------------------------
  // Verifies no empty addresses are input
  //------------------------------------------------------------------------------------------------------------------
  modifier noZeroAddress(address _param) {
    require (_param != address(0));
    _;
  }


  //------------------------------------------------------------------------------------------------------------------
  //                                              Events
  //------------------------------------------------------------------------------------------------------------------
  event LogOwnerChanged(address indexed _previousOwner, address indexed _newOwner);
  event LogFunctionAuthorized(address indexed _owner, string indexed _functionName, bytes32 indexed _beneficiary, bytes32 _authHash);
}
