//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./interface/IERC20.sol";
import "./interface/Counters.sol";
// import "@nomiclabs/buidler/console.sol";
import "hardhat/console.sol";

contract MyRole is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    address public token;
    address public claimAccount;
    mapping(uint256 => uint256) private price;
    // mapping(address => uint256) private nonce;
    uint256 public uid;//记录用户创建角色个数
    
    string public baseExtension = ".json";
    string public baseURI;
    string _initBaseURI = "http://agestrategy.io/";
    Counters.Counter private currentTokenId;
    mapping(uint256 => string) private _tokenURIs;
    bool private _notEntered = true;
    address admin;
    address stakingAddress;
    
    event BuyRole( 
        address account,
        uint256 amount,
        uint256 tokenid
    );

    event ClaimToken(address account, uint256 number);
    event SetClaimAccount(address account);
    event LockToken(address indexed account, uint256[] tokenId);
    event UnLockToken(address indexed account, uint256[] tokenId);

    constructor(address _token, address _claimAccount) ERC721("MyRole", "Role"){
        setBaseURI(_initBaseURI);//设置URI地址
        token = _token;//ERC20代币token
        claimAccount = _claimAccount;//提钱账户
        // uint256 chainId;
        // assembly {
        //     chainId := chainid()//获取链的id
        // }
        admin = msg.sender;
    }
    //非重入
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    //返回nonce
    // function nonceOf(address account) public view returns (uint256) {
    //     return nonce[account];
    // }
    function getUid() public view returns(uint256){
        return uid;
    }

    //锁定
    function lock(uint256[] memory tokenIds) public {
        for (uint256 _i = 0; _i < tokenIds.length; _i++) {
            uint256 tokenId = tokenIds[_i];
            require(_checkNftOwner(tokenId) && !nftLock[tokenId]);

            nftLock[tokenId] = true;
        }
        emit LockToken(msg.sender, tokenIds);
    }
    //解锁
    function unlock(uint256[] memory tokenIds) public {
        for (uint256 _i = 0; _i < tokenIds.length; _i++) {
            uint256 tokenId = tokenIds[_i];
            require(_checkNftOwner(tokenId) && nftLock[tokenId]);

            nftLock[tokenId] = false;
        }
        emit UnLockToken(msg.sender, tokenIds);
    }

    function _checkNftOwner(uint256 tokenId) internal view returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return owner == msg.sender;
    }

    //购买角色
    function buyRole(
        uint256 buyway,
        uint256 amount//--
    ) public payable nonReentrant {

        if(buyway == 0 ){//购买方式0，花200AS
            amount = 200 * 1e8; 
        }else if(buyway == 1){//购买方式1，花400AS
            amount = 400 * 1e8;
        }else if(buyway == 2){
            amount = 800 * 1e8;
        }else{
            amount = 1000 * 1e8;
        }

        _inter_transfer(amount / 2);//50%进staking --
        _inter_burn(amount / 2);//50%销毁 --
        uint256 new_tokenid = _mint(msg.sender);
        uid++;

        emit BuyRole(
            msg.sender,
            amount,
            new_tokenid
        );
    }
    
    function setStaking(address account)public payable{
        require(msg.sender == admin, "not owner.");
        stakingAddress = account;
    }

    //销毁50%
    function _inter_burn(uint256 amount) internal{
        IERC20(token).transferFrom(msg.sender, address(0), amount);
    }

    //50%进staking质押
    function _inter_transfer(uint256 amount) internal {
        require(stakingAddress != address(0), "staking address not address(0).");
        IERC20(token).transferFrom(msg.sender, stakingAddress, amount);
    }

    function claim_token(uint256 number) public onlyOwner {
        IERC20(token).transfer(claimAccount, number);
        emit ClaimToken(claimAccount, number);
    }

    function _setClaimAccount(address _account) public onlyOwner {
        claimAccount = _account;
        emit SetClaimAccount(_account);
    }
    //铸币
    function _mint(address recipient) internal returns (uint256) {
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }
    //设置初始URI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    //初始URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    //tokenURI
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent NFT"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
}
