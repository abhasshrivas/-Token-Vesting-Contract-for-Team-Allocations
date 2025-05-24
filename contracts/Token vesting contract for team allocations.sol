// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable {
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 amountClaimed;
    }

    IERC20 public token;
    mapping(address => VestingSchedule) public schedules;

    event VestingAdded(address indexed beneficiary, uint256 amount, uint256 start, uint256 cliff, uint256 duration);
    event TokensClaimed(address indexed beneficiary, uint256 amount);

    // Pass owner to Ownable constructor here
    constructor(address _token, address _owner) Ownable(_owner) {
        token = IERC20(_token);
    }

    function addVestingSchedule(
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _startTime,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) external onlyOwner {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_totalAmount > 0, "Amount must be > 0");
        require(schedules[_beneficiary].totalAmount == 0, "Schedule already exists");
        require(_vestingDuration > 0, "Vesting duration must be > 0");
        require(_cliffDuration <= _vestingDuration, "Cliff must be <= vesting duration");

        schedules[_beneficiary] = VestingSchedule({
            totalAmount: _totalAmount,
            startTime: _startTime,
            cliffDuration: _cliffDuration,
            vestingDuration: _vestingDuration,
            amountClaimed: 0
        });

        emit VestingAdded(_beneficiary, _totalAmount, _startTime, _cliffDuration, _vestingDuration);
    }

    function claimTokens() external {
        VestingSchedule storage schedule = schedules[msg.sender];
        require(schedule.totalAmount > 0, "No vesting schedule");

        uint256 vested = getVestedAmount(msg.sender);
        uint256 claimable = vested - schedule.amountClaimed;
        require(claimable > 0, "Nothing to claim");

        schedule.amountClaimed += claimable;
        require(token.transfer(msg.sender, claimable), "Token transfer failed");

        emit TokensClaimed(msg.sender, claimable);
    }

    function getVestedAmount(address _beneficiary) public view returns (uint256) {
        VestingSchedule memory schedule = schedules[_beneficiary];

        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            return 0;
        }

        uint256 elapsed = block.timestamp - schedule.startTime;
        if (elapsed >= schedule.vestingDuration) {
            return schedule.totalAmount;
        }

        return (schedule.totalAmount * elapsed) / schedule.vestingDuration;
    }
}
