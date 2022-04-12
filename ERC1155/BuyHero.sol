// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./introspection/Context.sol";
import "./introspection/Strings.sol";
// import "hardhat/console.sol";

contract BuyHero is Context{
    using Strings for uint256;

    string private _uri;
    address private _owner;
    uint256 private tokenId;
    uint256[] private tokenIdResult;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) tokenUri;

    event _mintBatchChange(uint256[] tokenIdResult,address indexed to,uint256[] amounts,string data);
    event _safeTransferFromChange(address indexed operator, address indexed from,address indexed to,uint256 id,uint256 amount);
    event _safeBatchTransferFromChange(address indexed operator,address indexed from,address indexed to,uint256[] ids,uint256[] amounts);
    event _setApprovalForAllChange(address indexed owner,address indexed operator,bool approved);

    constructor(address owner) {
        // _setURI(_uri);
        _owner = owner;
    }

    function uri(uint256) public view returns (string memory) {
        return _uri;
    }

    function _setURI(string memory newuri) public {
        require(_owner == msg.sender);
        _uri = newuri;
    }

    function _mintBatch(
        address to,
        // uint256[] memory ids,
        uint256[] memory amounts,
        string memory data
        // string[] memory _uri
    ) public {
        require(_owner == msg.sender);
        require(to != address(0), "ERC1155: mint to the zero address");
        // require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        // address operator = _msgSender();
        // _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < amounts.length; i++) {
            // _balances[ids[i]][to] += amounts[i];
            // tokenUri[ids[i]] = _uri[i];
            // tokenId += 1;
            tokenId += 1;
            _balances[tokenId][to] += amounts[i];
            tokenIdResult.push(tokenId);
        }

        emit _mintBatchChange(tokenIdResult,to,amounts,data);

        delete tokenIdResult;
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit _setApprovalForAllChange(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory data
    ) public {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string memory data
    ) public {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory data
    ) internal {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        // uint256[] memory ids = _asSingletonArray(id);
        // uint256[] memory amounts = _asSingletonArray(amount);
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit _safeTransferFromChange(operator, from, to, id, amount);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string memory data
    ) internal {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit _safeBatchTransferFromChange(operator, from, to, ids, amounts);
    }

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function getTokenId()public view returns(uint256){
        return tokenId;
    }

    function _baseURI()public view returns(string memory){
        return _uri;
    }

    /**
    * @dev Returns an URI for a given token ID
    */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI,_tokenId.toString()));
    }

}