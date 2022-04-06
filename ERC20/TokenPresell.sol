// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./interface/IERC20.sol";

contract TokenPresell {
    
    using SafeMath for uint256;

    address private _owner;
    address private _AOSLPToken;
    uint256 private BNBbalance;
    uint256 internal constant MASK = type(uint256).max;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;
    mapping(address => address) public delegates;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event DepositTokenChanged(address indexed from, address indexed to ,uint256 amount);
    event DithdrawTokenChanged(address indexed to ,uint256 amount);
    event RollOutLPChanged(address indexed user, uint256 amount);
    event DepositBNB(address indexed sender,uint256 value);
    event extractLPChanged(address indexed to,uint256 amount);

    constructor(address AOSLPToken,address owner){
        _owner = owner;
        _AOSLPToken = AOSLPToken;
    }

    function allowance(address account, address spender)
        external
        view
        returns (uint256)
    {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];
        if (spender != src && spenderAllowance != MASK) {
            uint256 newAllowance = spenderAllowance.sub(amount);
            allowances[src][spender] = newAllowance;
            emit Approval(src, spender, newAllowance);
        }
        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) internal {
        require(
            src != address(0),
            "_transferTokens: cannot transfer from the zero address"
        );
        require(
            dst != address(0),
            "_transferTokens: cannot transfer to the zero address"
        );
        balances[src] = balances[src].sub(amount);
        balances[dst] = balances[dst].add(amount);
        emit Transfer(src, dst, amount);
    }

    receive() external payable {
        require(msg.value >= 0.3 ether,"Amount cannot be less than 0.3");
        require(msg.value <= 5.0 ether,"Amount cannot be greater than 5.0");
        emit DepositBNB(msg.sender,msg.value);
        BNBbalance += msg.value;
        IERC20(_AOSLPToken).transferFrom(address(this), msg.sender, msg.value);
        emit RollOutLPChanged(msg.sender, msg.value);
    }

    function withdrawToken(uint256 amount) public payable returns(bool){
        require(_owner == msg.sender, "Not a contract caller");
        payable(msg.sender).transfer(amount);
        BNBbalance -= amount;
        emit DithdrawTokenChanged(_owner,amount);
        return true;
    }

    function extractLP(address to,uint256 amount) public returns(bool){
        require(_owner == msg.sender, "Not a contract caller");
        IERC20(_AOSLPToken).transferFrom(address(this),to,amount);
        emit extractLPChanged(to,amount);
        return true;
    }

    function getBNBbalance() public view returns(uint256){
        return BNBbalance;
    }

    function getAOSLPToken() public view returns(address){
        return _AOSLPToken;
    }
}