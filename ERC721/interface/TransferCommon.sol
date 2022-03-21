// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TransferCommon {
    function _doTransferInToken(
        address _from,
        address _to,
        uint256 _amount,
        address _token
    ) internal returns (uint256) {
        IERC20 token = IERC20(_token);
        uint256 balanceBefore = token.balanceOf(_to);
        token.transferFrom(_from, _to, _amount);
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

        uint256 balanceAfter = token.balanceOf(_to);
        require(
            balanceAfter >= balanceBefore,
            "doTransferIn::balanceAfter >= balanceBefore failure"
        );
        return balanceAfter - balanceBefore;
    }

    function _doTransferOutToken(
        address payable _to,
        uint256 _amount,
        address _token
    ) internal {
        IERC20 token = IERC20(_token);
        token.transfer(_to, _amount);
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
