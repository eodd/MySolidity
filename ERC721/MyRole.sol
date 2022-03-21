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

    uint256 rults;
    address public token;
    address public claimAccount;
    mapping(uint256 => uint256) private price;
    mapping(address => uint256) private nonce;
    uint256 private roleId;
    mapping(address => mapping(uint256 => Role)) public role;
    
    string public baseExtension = ".json";
    string public baseURI;
    string _initBaseURI = "http://agestrategy.io/";
    Counters.Counter private currentTokenId;
    mapping(uint256 => string) private _tokenURIs;
    bool private _notEntered = true;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)"
            )
        );
    bytes32 public constant BUYROLE_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "BuyRole(string name, uint256 level, address account, uint256 nonce)"
            )
        );

    event BuyRole( 
        address account,
        uint256 amount,
        uint256 tokenid,
        string  name,
        uint256 level 
    );

    event ClaimToken(address account, uint256 number);
    event SetClaimAccount(address account);
    event LockToken(address indexed account, uint256[] tokenId);
    event UnLockToken(address indexed account, uint256[] tokenId);

    struct Role{//角色属性
        string  name;
        uint256 level;//等级
    }

    constructor(address _token, address _claimAccount)//初始化合约名字、符号
        ERC721("MyRole", "Role")
    {
        // _mint(_claimAccount);//铸币

        setBaseURI(_initBaseURI);//设置URI地址

        token = _token;//NFTtoken
        claimAccount = _claimAccount;//账户
        // uint256 chainId = 3;
        // assembly {
        //     chainId := chainid()//获取链的id
        // }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,//"EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)"
                keccak256(bytes("Role")),
                keccak256(bytes("1"))
                // chainId
                // address(0xd9145CCE52D386f254917e481eB44e9943F39138)
            )
        );
    }
    //非重入
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    //返回nonce
    function nonceOf(address account) public view returns (uint256) {
        return nonce[account];
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
        address account, 
        uint256 _nonce,
        uint256 amount,
        string memory name, 
        uint256 level, 
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable nonReentrant {
        // bytes32 digest = keccak256(//将传入的内容与 DOMAIN_SEPARATOR 一起编码成hash串
        //     abi.encodePacked(
        //         // "\x19\x01",
        //         // "\x19Ethereum Signed Message:\n32",
        //         // DOMAIN_SEPARATOR,
        //         keccak256(
        //             abi.encode(
        //                 BUYROLE_TRANSACTION_TYPEHASH,//"BuyRole(string name, uint256 level, address account, uint256 nonce)"
        //                 name,
        //                 level,
        //                 account,
        //                 _nonce            
        //             )
        //         )
        //     )
        // );
        // address recoveredAddress = ecrecover(digest, v, r, s);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix,hash));
        address recoveredAddress = ecrecover(prefixedHash, v, r, s);
        //require(rult != msg.sender);

        // console.log("CCC");
        // console.log("qianming",recoveredAddress);
        // console.log("yongyouzhe",owner());
        // console.log("account",account);//对
        // console.log("msg",msg.sender);
        // console.log("nonce",nonce[account]);
        require(
            // recoveredAddress == owner() && //签名是否是拥有者
            recoveredAddress == 0x6F90F16d4Fdbf221556d9737324AeCd9bF7179D9 && //签名是否是拥有者
            account == msg.sender && //是否是当前调用者
            _nonce > nonce[account] //nonce是否大于上一次nonce
        );
        nonce[account]++;
        console.log("ruls=",rults);
        _inter_transfer(amount);
        uint256 new_tokenid = _mint(account);
        console.log("BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB");
        role[msg.sender][roleId] = Role (
            name,
            level
        );
        roleId++;

        emit BuyRole(
            msg.sender,
            amount,
            new_tokenid,
            name, 
            level
        );
        console.log("AAA");
    }
    //购买角色时调用
    function _inter_transfer(uint256 amount) internal {
        console.log("token=",token);
        console.log("meg=",msg.sender);
        console.log("address(this)=",address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
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
