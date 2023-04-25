// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract HYCOClaim is Ownable {

    event Claimed(address indexed account, uint256 amount);

    IERC20 private immutable _erc20;

    mapping(address => uint256) public claimList;

    address private _fromAddress = 0xd4B11779a2dDAb1B49bcC873b87501f0C1319BFa;
    address private _opAddress = 0xe604319dCF200bdc16e8e6d0BcFe9f0bF44f0BDD;
    
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

    function hycoClaimFromBatch(address[] memory addresses, uint256[] memory amounts) 
        public 
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            SafeERC20.safeTransferFrom(_erc20, _fromAddress, addresses[i], amounts[i]);
            emit Claimed(addresses[i], amounts[i]);
        }
    }

    function setClaimlist(address[] memory addresses, uint256[] memory amounts) 
        public 
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        require(addresses.length == amounts.length, "Wrong data!");

        for (uint256 i = 0; i < addresses.length; i++) {
            if (claimList[addresses[i]] > 0) claimList[addresses[i]] += amounts[i];
            else claimList[addresses[i]] = amounts[i];
        }
    }

    function resetClaimlist(address[] memory addresses)
        public
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
        for (uint256 i = 0; i < addresses.length; i++) {
            claimList[addresses[i]] = 0;
        }
    }

    function setApproveForClaim(address[] memory addresses, uint256[] memory amounts) 
        public 
    {
        require(msg.sender == _opAddress || msg.sender == owner(), "Caller is not the operator.");
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
    
    function setOpAddress(address opAddress)
        public onlyOwner
    {
        _opAddress = opAddress;
    }

    function getFromAddress()
        public view onlyOwner returns(address)
    {
        return _fromAddress;
    }
    
    function getOpAddress()
        public view onlyOwner returns(address)
    {
        return _opAddress;
    }

    function withdraw(address walletAddress) 
        external onlyOwner 
    { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));
    }

}
