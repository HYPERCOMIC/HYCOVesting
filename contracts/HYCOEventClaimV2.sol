// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HYCOEventClaimV2 is Ownable {

    event Claimed(address indexed account, uint256 amount);

    IERC20 private immutable _erc20;

    uint256 endTimestamp = 1701428400;
    uint public eventTimes = 1;

    mapping(address => uint) public claimedList;
    mapping(uint => bytes32) public merkleRootMap;

    address public fromAddress = 0x643FF6fe36a18bF0d705fb89CEfC42deD01CF28d;

    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address
    ) {
        _erc20 = IERC20(erc20Address);
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in Claimlist!"
        );
        _;
    }

    function hycoClaimForWhite(bytes32[] calldata merkleProof, uint _claimAmount) public 
        isValidMerkleProof(merkleProof, merkleRootMap[_claimAmount])
    {
        require(endTimestamp > block.timestamp, "The claim period has ended.");
        require(claimedList[msg.sender] < eventTimes, "Aleady Claimed!");

        SafeERC20.safeTransferFrom(_erc20, fromAddress, msg.sender, _claimAmount*1000000000000000000);
        claimedList[msg.sender] = eventTimes;

        emit Claimed(msg.sender, _claimAmount*1000000000000000000);
    }

    function setFromAddress(address _fromAddress) external onlyOwner
    {
        fromAddress = _fromAddress;
    }

    function setClaimInfo(bytes32 _merkleRoot, uint _claimAmount) external onlyOwner {
        merkleRootMap[_claimAmount] = _merkleRoot;
    }

    function setEventTimes(uint _times) external onlyOwner {
        eventTimes = _times;
    }

    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        endTimestamp = _endTimestamp;
    } 

    function withdraw(address walletAddress) external onlyOwner 
    { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));
    }

}
