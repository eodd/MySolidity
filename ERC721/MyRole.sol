//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./interface/IERC20.sol";
import "hardhat/console.sol";

contract MyRole {
    
    using Strings for uint256;

    uint256 public _tokenId;

    // uint256 public NFTAmount = 31;

    address public token;

    address public claimAccount;

    address _stakingAddress;

    address _owner;
    
    string public baseExtension = ".json";

    // string public baseURI;

    string private initURI;
    
    mapping(uint256 => bool) public nftLock;    

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _owners;

    mapping(uint256 => address) private _tokenApprovals;    

    mapping(address => mapping(address => bool)) private _operatorApprovals;       

    mapping(uint256 => string) myTokenURI;     
    // mapping(uint256 => uint256) private price;
    // mapping(uint256 => string) private _tokenURIs;
    
    bool private _notEntered = true;
    
    event BuyRole(address indexed account,uint256 amount,uint256 tokenId);

    event _mintChange(address indexed to,uint256 tokenId);

    event _approveChange(address indexed owner,address indexed to,uint256 tokenId);

    event _transferChange(address indexed from,address indexed to,uint256 tokenId);

    // event ClaimToken(address account, uint256 number);
    // event SetClaimAccount(address account);
    // event LockToken(address indexed account, uint256[] tokenId);
    // event UnLockToken(address indexed account, uint256[] tokenId);

    // constructor(address _token, address _claimAccount, address stakingAddress) ERC721("MyRole", "Role"){
    //     admin = msg.sender;
    //     token = _token;//ERC20代币token
    //     claimAccount = _claimAccount;//提钱账户
    //     _stakingAddress = stakingAddress;
    //     setBaseURI(_initBaseURI);//设置URI地址        
    // }

    constructor(address owner,string memory initBaseURI){
        _owner = owner;
        // token = _token;//ERC20代币token
        // claimAccount = _claimAccount;//提钱账户
        // _stakingAddress = stakingAddress;
        // setBaseURI(_initBaseURI);//设置URI地址     
        initURI = initBaseURI;
    }

    //非重入
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    function getTokenId() public view returns(uint256){
        return _tokenId;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _checkLock(uint256 tokenId) internal view {
        require(nftLock[tokenId] == false, "Nft lock by owner");
    }

    // //锁定
    // function lock(uint256[] memory tokenIds) public {
    //     for (uint256 _i = 0; _i < tokenIds.length; _i++) {
    //         uint256 tokenId = tokenIds[_i];
    //         require(_checkNftOwner(tokenId) && !nftLock[tokenId]);

    //         nftLock[tokenId] = true;
    //     }
    //     emit LockToken(msg.sender, tokenIds);
    // }

    // //解锁
    // function unlock(uint256[] memory tokenIds) public {
    //     for (uint256 _i = 0; _i < tokenIds.length; _i++) {
    //         uint256 tokenId = tokenIds[_i];
    //         require(_checkNftOwner(tokenId) && nftLock[tokenId]);

    //         nftLock[tokenId] = false;
    //     }
    //     emit UnLockToken(msg.sender, tokenIds);
    // }

    // function _checkNftOwner(uint256 tokenId) internal view returns (bool) {
    //     address owner = ERC721.ownerOf(tokenId);
    //     return owner == msg.sender;
    // }

    //购买角色
    function buyRole(
        address to
        // uint256 buyway,
        // uint256 amount//--
    ) public payable nonReentrant {

        require(msg.sender == _owner, "not owner.");

        // if(buyway == 0 ){//购买方式0，花200AS
        //     amount = 200 * 1e8; 
        // }else if(buyway == 1){//购买方式1，花400AS
        //     amount = 400 * 1e8;
        // }else if(buyway == 2){
        //     amount = 800 * 1e8;
        // }else{
        //     amount = 1000 * 1e8;
        // }

        // _inter_transfer(amount / 2);//50%进staking --
        // _inter_burn(amount / 2);//50%销毁 --

        _tokenId += 1;
        _mint(to,_tokenId);

        // emit BuyRole(msg.sender,amount,new_tokenid);
    }
    
    function setStaking(address account)public payable{
        require(msg.sender == _owner, "not owner.");
        _stakingAddress = account;
    }

    //销毁50%
    function _inter_burn(uint256 amount) internal{
        IERC20(token).transferFrom(msg.sender, address(0), amount);
    }

    //50%进staking质押
    function _inter_transfer(uint256 amount) internal {
        require(_stakingAddress != address(0), "staking address not address(0).");
        IERC20(token).transferFrom(msg.sender, _stakingAddress, amount);
    }

    // function claim_token(uint256 number) public onlyOwner {
    //     IERC20(token).transfer(claimAccount, number);
    //     emit ClaimToken(claimAccount, number);
    // }

    // function _setClaimAccount(address _account) public onlyOwner {
    //     claimAccount = _account;
    //     emit SetClaimAccount(_account);
    // }
    
    //铸币
    function _mint(address to,uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        // _checkLock(tokenId);
        // require(NFTAmount != 0,"NFT has been sold out");

        _balances[to] += 1;

        _owners[tokenId] = to;

        // NFTAmount - 1;

        emit _mintChange(to,tokenId);
    }

    function balanceOf(address owner)
        public
        view
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner,msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit _approveChange(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)internal view returns (bool){
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function getApproved(uint256 tokenId)public view returns (address){
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function transferFrom(address from,address to,uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender,tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function _transfer(address from,address to,uint256 tokenId) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _checkLock(tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit _transferChange(from, to, tokenId);
    }

    // function _mint(address recipient) internal returns (uint256) {
    //     currentTokenId.increment();
    //     uint256 newItemId = currentTokenId.current();
    //     _safeMint(recipient, newItemId);
    //     return newItemId;
    // }

    function setBaseURI(uint256[] memory tokenId,string[] memory newuri) public {
        require(_owner == msg.sender);
        // myTokenURI[tokenId] = newuri;
        for (uint256 i=0;i<tokenId.length;i++){

            myTokenURI[tokenId[i]] = newuri[i];
        }
    }

    function _initURI() internal view returns (string memory) {
        return initURI;
    }

    //tokenURI
    function tokenURI(uint256 tokenId)public view returns(string memory){
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent NFT"
        );
        return string(abi.encodePacked(initURI,myTokenURI[tokenId]));
    }
}
