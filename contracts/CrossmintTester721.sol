// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CrossmintTester721 is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    event Mint(uint256 tokenId);
    event Airdrop(uint256 tokenId);
    event NewURI(string oldURI, string newURI);

    Counters.Counter internal nextId;

    IERC20 public usdc;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public priceUSDC = 1 * 10 ** 6; // 1 USDC (because usdc is a 6 decimal ERC20 token)
    uint256 public priceNative = 0.001 ether; // 0.001 MATIC
    string public baseUri = "https://bafkreic6xug4ia6n2ogb5b5vfmjmrvjuhypii6cek4uwaf7wi4mgyupse4.ipfs.nftstorage.link/";

    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");
    bytes32 public constant CROSSMINT_ROLE = keccak256("CROSSMINT_ROLE");

    constructor(address _usdcAddress, address _crossmintAddress) payable ERC721("Crossmint Tester 721", "XMINT") {
        usdc = IERC20(_usdcAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROPPER_ROLE, msg.sender);
        _grantRole(CROSSMINT_ROLE, msg.sender);
        _grantRole(CROSSMINT_ROLE, _crossmintAddress);
    }
        
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // MODIFIERS

    modifier isCorrectPayment(uint256 _quantity) {
        require(msg.value >= (priceNative * _quantity), "Incorrect Payment Sent");
        _;
    }

    modifier isAvailable(uint256 _quantity) {
        require(nextId.current() + _quantity <= MAX_SUPPLY, "Not enough tokens left for quantity");
        _;
    }

    // PUBLIC

    function mintUSDC(address _to, uint256 _quantity) 
        external  
        isAvailable(_quantity) 
    {
        usdc.transferFrom(msg.sender, address(this), priceUSDC * _quantity);

        mintInternal(_to, _quantity);
    }

    function mintNative(address _to, uint256 _quantity)
      external
      payable
      isAvailable(_quantity)
      isCorrectPayment(_quantity)
    {
        mintInternal(_to, _quantity);
    }

    function crossmintUSDC(address _to, uint256 _quantity) 
        external
        onlyRole(CROSSMINT_ROLE)
        isAvailable(_quantity) 
    {
        usdc.transferFrom(msg.sender, address(this), priceUSDC * _quantity);

        mintInternal(_to, _quantity);
    }

    function crossmint(address _to, uint256 _quantity) 
        external 
        payable
        onlyRole(CROSSMINT_ROLE)
        isAvailable(_quantity) 
        isCorrectPayment(_quantity)
    {
        mintInternal(_to, _quantity);
    }

    // INTERNAL

    function mintInternal(address _to, uint256 _quantity) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = nextId.current();
            nextId.increment();

            _safeMint(_to, tokenId);

            emit Mint(tokenId);
        }
    }   

    // ADMIN

    function airdrop(address _to, uint256 _quantity)
        external 
        onlyRole(AIRDROPPER_ROLE)
        isAvailable(_quantity)
    {
        mintInternal(_to, _quantity);
    }

    /**
     * uint256 _newPrice - this price must include 6 decimal points
     * for example: 10 USDC == 10_000_000
     */
    function setPriceUSDC(uint256 _newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceUSDC = _newPrice;
    }

    function setPriceNative(uint256 _newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceNative = _newPrice;
    }

    function setUri(string calldata _newUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit NewURI(baseUri, _newUri);

        baseUri = _newUri;
    }

    function setUsdcAddress(IERC20 _usdc) public onlyRole(DEFAULT_ADMIN_ROLE) {
        usdc = _usdc;
    }

    function withdrawUSDC() public onlyRole(DEFAULT_ADMIN_ROLE) {
        usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // VIEW

    function tokenURI(uint256 /*_tokenId*/) public view override returns (string memory) {
        return baseUri; 
    }
}