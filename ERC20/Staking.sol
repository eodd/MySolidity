// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract Staking {
    using SafeMath for uint256;

    address public token;
    address public owner;
    uint256 public totalSupply;
    uint256 internal stakingRuleId = 1;
    uint256 internal recordDetailId = 0;

    mapping(address => uint256) public myLockeds;
    mapping(address => RecordDetail[]) public myRecords;
    mapping(address => mapping(uint256 => RecordDetail)) public recordDetails;
    struct RecordDetail {
        uint256 amount;
        uint256 stakingRule;
        uint256 stakeDate;
        uint256 redemptionDate;
        uint256 totalReward;
        bool claim;
    }

    StakingRule[] public stakingRules;
    mapping(uint256 => StakingRule) internal stakingRule;
    struct StakingRule {
        uint256 id;
        string cycleStr;
        uint256 cycle;
        uint256 ratio;
    }

    event ConfirmStaking(
        address account,
        uint256 amount,
        uint256 stakingRuleId
    );
    event Claim(address account, uint256 recordId, uint256 totalReward);

    constructor(address _token, address _owner) {
        token = _token;
        owner = _owner;

        _initStakingRule();
    }
    //初始化staking规则
    function _initStakingRule() internal {
        StakingRule memory stakingRuleOne = StakingRule({
            id: stakingRuleId,
            cycleStr: "1 week",
            cycle: 4 * 60 * 24 * 7 * 15,
            ratio: 10000000
        });
        stakingRules.push(stakingRuleOne);

        stakingRuleId++;
        StakingRule memory stakingRuleTwo = StakingRule({
            id: stakingRuleId,
            cycleStr: "1 month",
            cycle: 4 * 60 * 24 * 30 * 15,
            ratio: 12000000
        });
        stakingRules.push(stakingRuleTwo);
    }
    //初始化报酬金额
    function _rewardAmountInit(uint256 _amount) public {
        require(msg.sender == owner);

        _doTransferInToken(msg.sender, _amount);
    }
    //取出报酬金额
    function _rewardAmountWithdraw(address payable account) public {
        require(msg.sender == owner);

        uint256 _amount = IERC20(token).balanceOf(address(this)).sub(
            totalSupply
        );
        _doTransferOutToken(account, _amount);
    }
    //批准staking
    function confirmStaking(uint256 _amount, uint256 _stakingRuleId) public {
        StakingRule memory _stakingRule = stakingRule[_stakingRuleId];
        require(_stakingRule.id > uint256(0));

        _doTransferInToken(msg.sender, _amount);
        myLockeds[msg.sender] = myLockeds[msg.sender].add(_amount);
        totalSupply = totalSupply.add(_amount);

        recordDetailId++;
        uint256 _time = block.timestamp;
        uint256 _totalReward = _stakingRule.ratio.mul(_amount).add(_amount).div(
            10**IERC20(token).decimals()
        );
        recordDetails[msg.sender][recordDetailId] = RecordDetail({
            amount: _amount,
            stakingRule: _stakingRuleId,
            stakeDate: _time,
            redemptionDate: _time.add(_stakingRule.cycle),
            totalReward: _totalReward,
            claim: false
        });

        emit ConfirmStaking(msg.sender, _amount, _stakingRuleId);
    }
    //认领
    function claim(address payable account, uint256 recordId) public {
        RecordDetail storage _recordDetail = recordDetails[account][recordId];
        require(_recordDetail.amount > uint256(0) && !_recordDetail.claim);

        _doTransferOutToken(account, _recordDetail.totalReward);
        _recordDetail.claim = true;
        totalSupply = totalSupply.sub(_recordDetail.totalReward);

        emit Claim(account, recordId, _recordDetail.totalReward);
    }
    //转入Token
    function _doTransferInToken(address _from, uint256 _amount)
        internal
        returns (uint256)
    {
        IERC20 erc20 = IERC20(token);
        uint256 balanceBefore = erc20.balanceOf(address(this));
        erc20.transferFrom(_from, address(this), _amount);
        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                success := not(0)
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
        require(success, "doTransferIn failure");

        uint256 balanceAfter = erc20.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "doTransferIn::balanceAfter >= balanceBefore failure"
        );
        return balanceAfter - balanceBefore;
    }
    //转出Token
    function _doTransferOutToken(address payable _to, uint256 _amount)
        internal
    {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(_to, _amount);
        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                success := not(0)
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
        require(success, "dotransferOut failure");
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
