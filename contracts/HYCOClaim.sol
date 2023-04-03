// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract HYCOClaim is Ownable {

    event Claimed(address indexed account, uint256 amount);
    event Mining(address indexed account, uint256 amount, string source);

    IERC20 private immutable _erc20;

    mapping(address => uint256) public claimList;

    address private _fromAddress = 0x43694Fd007a068909aC0951cFec4DfC6E3De42cf;
    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address
    ) {
        _erc20 = IERC20(erc20Address);
    }

    function hycoClaim() 
        public 
    {

        require(claimList[msg.sender] > 0, "Address does not exist in Claimlist!");

        SafeERC20.safeTransfer(_erc20, msg.sender, claimList[msg.sender]);
        claimList[msg.sender] = 0;

        emit Claimed(msg.sender, claimList[msg.sender]);

    }

    function hycoClaimFrom() 
        public 
    {

        require(claimList[msg.sender] > 0, "Address does not exist in Claimlist!");

        SafeERC20.safeTransferFrom(_erc20, _fromAddress, msg.sender, claimList[msg.sender]);
        claimList[msg.sender] = 0;

        emit Claimed(msg.sender, claimList[msg.sender]);

    }

    function setClaimlist(address[] memory addresses, uint256[] memory amounts) 
        public onlyOwner 
    {
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (claimList[addresses[i]] > 0) claimList[addresses[i]] += amounts[i];
            else claimList[addresses[i]] = amounts[i];
        }
    }

    function setApproveForClaim(address[] memory addresses, uint256[] memory amounts) 
        public onlyOwner 
    {
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20.safeApprove(_erc20, addresses[i], amounts[i]);
        }
    }

    function setFromAddress(address fromAddress)
        public onlyOwner
    {
        _fromAddress = fromAddress;
    }

    function getFromAddress()
        public view onlyOwner returns(address)
    {
        return _fromAddress;
    }

    function withdraw(address walletAddress) 
        external onlyOwner 
    { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));
    }

}
