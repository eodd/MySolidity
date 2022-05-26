// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./interface/SafeERC20.sol";

contract AS {

    using SafeMath for uint256;

    string public constant name = "AS";

    string public constant symbol = "AS";

    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = 10000000000000000000000000000;

    uint256 internal constant MASK = type(uint256).max;

    address private _owner;

    mapping(address => mapping(address => uint256)) internal allowances;//查询授权余额

    mapping(address => uint256) internal balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner,address indexed spender,uint256 amount);

    constructor(address owner) {
        _owner = owner;

        balances[address(this)] = totalSupply;

        emit Transfer(address(0), address(this), totalSupply);

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

    function takeOut(address to, uint256 amount) public returns(bool){
        require(to != address(0), "deposit address not address(0).");
        require(_owner == msg.sender, "Not a contract caller");
        IERC20(address(this)).transferFrom(address(this),to,amount);

        return true;
    }
}
