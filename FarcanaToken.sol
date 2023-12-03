// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 private token;
    
    struct VestingSchedule {
        uint256 cliff; // cliff time of the vesting start in seconds since the UNIX epoch
        uint256 duration; // duration of the vesting period in seconds
        uint256 start; // start time of the vesting period in seconds since the UNIX epoch
        uint256 totalAmount; // total amount of tokens to be released at the end of the vesting
        uint256 released;  // amount of tokens released
    }

    uint256 tgetime;

    mapping(address => VestingSchedule[]) private vestingSchedules;

    event TokensReleased(address indexed beneficiary, uint256 amount);

    constructor(address token_address) {
        token = IERC20(token_address);
        tgetime = block.timestamp + 14 * 86400;
    }

    function setTGEtime(uint256 new_tge_time) external onlyOwner{
        tgetime = new_tge_time;
    }

    function getTGEtime() external view returns (uint256){
        return tgetime;
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    function addVestingSchedule(
        address beneficiary,
        uint256 cliff,
        uint256 duration,
        uint256 start,
        uint256 totalAmount
    ) external onlyOwner {
        VestingSchedule memory schedule = VestingSchedule({
            cliff: cliff,
            duration: duration,
            start: start,
            totalAmount: totalAmount,
            released: 0
        });

        vestingSchedules[beneficiary].push(schedule);
    }

    function claim() external {
        
        uint256 unreleased = prepareAvailableTokensForRelease(msg.sender);

        require(unreleased > 0, "No tokens are due for release");

        token.transfer(msg.sender, unreleased);
    }

    function getReleasedTokens(address beneficiary) external view returns(uint256) {
        
        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];

        uint256 released = 0;

        for (uint256 i = 0; i < schedules.length; i++) {
            
            VestingSchedule storage schedule = schedules[i];

            if(schedule.released > 0){
                released = released.add(schedule.released);
            }
        }

        return released;
    }

    function getAvailableTokens(address beneficiary) external view returns(uint256) {

        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];

        uint256 unreleased = 0;

        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];

            if (block.timestamp < schedule.start.add(schedule.cliff)) {
                continue;
            }

            uint256 vestedAmount = calculateVestedAmount(schedule);
            uint256 releaseable = vestedAmount.sub(schedule.released);
            
            if (releaseable > 0) {
                unreleased = unreleased.add(releaseable);
            }
        }

        return unreleased;
    }

    function prepareAvailableTokensForRelease(address beneficiary) internal returns(uint256) {

        VestingSchedule[] storage schedules = vestingSchedules[beneficiary];

        uint256 unreleased = 0;

        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage schedule = schedules[i];

            if (block.timestamp < schedule.start.add(schedule.cliff)) {
                continue;
            }

            uint256 vestedAmount = calculateVestedAmount(schedule);
            uint256 releaseable = vestedAmount.sub(schedule.released);
            
            if (releaseable > 0) {
                unreleased = unreleased.add(releaseable);
                schedule.released = schedule.released.add(releaseable);
                emit TokensReleased(msg.sender, releaseable);
            }
        }

        return unreleased;
    }

    function calculateVestedAmount(VestingSchedule storage schedule) internal view returns (uint256) {
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp < schedule.start) {
            return 0;
        } else if (currentTimestamp >= schedule.start.add(schedule.duration)) {
            return schedule.totalAmount;
        } else {
            return schedule.totalAmount.mul(currentTimestamp.sub(schedule.start)).div(schedule.duration);
        }
    }

    function changeBeneficiaryAddress(address lost_address, address new_address) external onlyOwner{
        
        VestingSchedule[] storage schedules = vestingSchedules[lost_address];

        vestingSchedules[new_address] = schedules;

        delete vestingSchedules[lost_address];
    }

    function getFullDataOfBeneficiary(address beneficiary) external view onlyOwner returns(VestingSchedule[] memory) {
        return vestingSchedules[beneficiary];
    }
}
