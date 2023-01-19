// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Confirmer.sol";

contract HYCOVesting is Ownable, Confirmer {
    event SetVesting(address indexed account, uint256 amount, uint256 startTime, uint256 duration);
    event UpdateVesting(address indexed account, uint256 valueIndex, uint256 value);
    event Released(address indexed account, uint256 amount);

    struct VestingInfo {
        uint256 amount;    
        uint256 startTime;
        uint256 releaseMonths;
        uint256 released;
    }
    mapping(address => VestingInfo) private _vestingInfos;
    address[] private _vestingWallets;

    IERC20 private immutable _erc20;
    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address erc20Address,
        address confirmer1, 
        address confirmer2
    ) {
        _erc20 = IERC20(erc20Address);

        _confirmers.push(msg.sender);
        _confirmers.push(confirmer1);
        _confirmers.push(confirmer2);
        _resetConfirmed();        
    }

    function transferOwnership(address newOwner) public isConfirmer(msg.sender) isConfirmed override
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        super._transferOwnership(newOwner);
        _resetConfirmed();
    }

    function renounceOwnership() public onlyOwner isConfirmed override
    {
        super.renounceOwnership();
        _resetConfirmed();
    }    

    /**
     * @dev Setter for the VestingInfo.
     */
    function setVestingInfo (address beneficiaryAddress, uint256 amount, uint256 startTime, uint256 releaseMonths) external onlyOwner isConfirmed {
        require(_vestingInfos[beneficiaryAddress].amount < 1, "Aleady exist vestig info.");
        require(beneficiaryAddress != address(0), "Beneficiary cannot be address zero.");
        require(block.timestamp < startTime, "ERC20 : Current time is greater than start time");
        require(releaseMonths > 0, "ERC20 : ReleaseMonths is smaller than 0");
        require(amount > 0, "ERC20: Amount is smaller than 0");
        
        _vestingInfos[beneficiaryAddress] = VestingInfo(amount, startTime, releaseMonths, 0);
        _vestingWallets.push(beneficiaryAddress);

        emit SetVesting( beneficiaryAddress, amount, startTime, releaseMonths );
        _resetConfirmed();
    }
    function setVestingAmount (address beneficiaryAddress, uint256 value) external onlyOwner isConfirmed {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");
        require(value > 0, "ERC20: Amount is smaller than 0.");
        _vestingInfos[beneficiaryAddress].amount = value;

        emit UpdateVesting( beneficiaryAddress, 1, value );
        _resetConfirmed();
    }
    function setVestingStartTime (address beneficiaryAddress, uint256 value) external onlyOwner isConfirmed {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");
        require(block.timestamp < value, "ERC20 : Current time is greater than start time");
        _vestingInfos[beneficiaryAddress].startTime = value;

        emit UpdateVesting( beneficiaryAddress, 2, value );
        _resetConfirmed();
    }
    function setVestingDuration(address beneficiaryAddress, uint256 value) external onlyOwner isConfirmed {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");
        require(value > 0, "ERC20 : ReleaseMonths is smaller than 0");
        _vestingInfos[beneficiaryAddress].releaseMonths = value;

        emit UpdateVesting( beneficiaryAddress, 3, value );
        _resetConfirmed();
    }

    /**
     * @dev Getter for the VestingInfo.
     */
    function getVestingInfo(address beneficiaryAddress) public view virtual returns (uint256 amount, uint256 startTime, uint256 duration, uint256 released) {
        return (_vestingInfos[beneficiaryAddress].amount, _vestingInfos[beneficiaryAddress].startTime, _vestingInfos[beneficiaryAddress].releaseMonths, _vestingInfos[beneficiaryAddress].released);
    }
    function getVestingWallets() public view virtual onlyOwner returns (address[] memory) {
        return (_vestingWallets);
    }

    /**
     * @dev Release the tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function release(address beneficiaryAddress) public virtual {
        require(_vestingInfos[beneficiaryAddress].amount > 0, "Not exist vesting info.");

        uint256 releasable = _vestingSchedule(beneficiaryAddress, uint256(block.timestamp)) - _vestingInfos[beneficiaryAddress].released;
        
        SafeERC20.safeTransfer(_erc20, beneficiaryAddress, releasable);

        _vestingInfos[beneficiaryAddress].released += releasable;

        emit Released(beneficiaryAddress, releasable);
    }

    function releaseSchedule() public virtual onlyOwner {
        uint256 releaseTime = block.timestamp;
        for (uint8 i = 0; i < _vestingWallets.length; i++) {

            uint256 releasable = _vestingSchedule(_vestingWallets[i], releaseTime) - _vestingInfos[_vestingWallets[i]].released;
            if (releasable > 0) {
                SafeERC20.safeTransfer(_erc20, _vestingWallets[i], releasable);
                _vestingInfos[_vestingWallets[i]].released += releasable;

                emit Released(_vestingWallets[i], releasable); 
            }               

        }        
    }

    /**
     * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(address beneficiaryAddress, uint256 timestamp) public view virtual returns (uint256) {
        return _vestingSchedule(beneficiaryAddress, timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(address beneficiaryAddress, uint256 timestamp) internal view virtual returns (uint256) {

        uint256 vestingAmount = _vestingInfos[beneficiaryAddress].amount;
        uint256 vestingStartTime = _vestingInfos[beneficiaryAddress].startTime;
        uint256 releaseMonths = _vestingInfos[beneficiaryAddress].releaseMonths;

        if (timestamp < vestingStartTime) return 0;

        uint256 checkReleasedSecond = timestamp - vestingStartTime;
        uint256 checkReleasedMonth = checkReleasedSecond / (86400 * 30);  //per 30day        

        if (releaseMonths <= checkReleasedMonth) {
            return vestingAmount;
        } else if (checkReleasedMonth < 1) {
            return 0;
        } else {
            return vestingAmount * checkReleasedMonth / releaseMonths;
        }        
    }

    function withdraw(address walletAddress) external onlyOwner isConfirmed { 
        SafeERC20.safeTransfer(_erc20, walletAddress, IERC20(_erc20).balanceOf(address(this)));
    }

}
