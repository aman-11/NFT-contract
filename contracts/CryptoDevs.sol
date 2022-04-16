// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable {
    //address of owner of this contract
    address public owner;

    string _baseTokenURI;

    enum State {
        beforeStarted,
        preSaleStarted,
        resume,
        paused,
        preSaleEnded
    }
    State public NFTstate;

    //set the price of the NFT
    uint256 public NFTpresalePrice = 0.02 ether;
    uint256 public NFTprice = 0.04 ether;

    //max no of NFT allowed  --> property of NFT --> Scarcity i.e limited
    uint256 public maxTokenId = 20; //tokenID is used to identify the uniqueness in each NFT
    //making a track of NFT getting minted
    uint256 public tokenIds;

    //Whitelist contract instance
    IWhitelist whitelist;

    //track of the preSale for the whitelisted
    uint256 public preSaleStarted;
    uint256 public preSaleEnded;

    //check for the paused state
    modifier onlyWhenNotPaused() {
        require(NFTstate != State.paused, "Contract currently paused");
        _;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only owner of this contract can acccess."
        );
        _;
    }

    constructor(string memory baseURI, address _whitelistContract)
        ERC721("Useless Nfts", "USENFT")
    {
        //initialize whitelist  owner, contarct and baseURI
        NFTstate = State.beforeStarted;
        owner = msg.sender;
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(_whitelistContract);
    }

    //start preSale by owner
    function startPresale() public onlyOwner {
        NFTstate = State.preSaleStarted;

        //timesatamp
        preSaleStarted = block.timestamp;
        preSaleEnded = block.timestamp + (3600 * 24 * 2); //2day
    }

    //making NFT sale paused
    function pauseSale() public onlyOwner {
        NFTstate = State.paused;
    }

    //making NFT sale paused
    function resumeSale() public onlyOwner {
        NFTstate = State.resume;
    }

    //preSalemint allow users to mint
    function presaleMint() public payable onlyWhenNotPaused {
        //check if event is started, not ended, supply is there, amount paid is correct
        require(NFTstate == State.preSaleStarted, "Sale has not been started");
        require(block.timestamp < preSaleEnded, "Sorry, Sales ended");
        require(
            whitelist.whitelistedAddress(msg.sender),
            "You are not whitelisted"
        );
        require(
            tokenIds < maxTokenId,
            "We have reached the maximum token supply."
        );
        require(msg.value >= NFTpresalePrice, "Please send the corect amount");

        //_safeMint(address to, uint256 tokenId)
        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
        tokenURI(tokenIds);
    }

    //mint(),after the preSale ended
    function mint() public payable onlyWhenNotPaused {
        require(NFTstate == State.preSaleStarted, "Sale has not been started");
        require(block.timestamp >= preSaleEnded, "Sorry, Sales ended");
        require(
            tokenIds < maxTokenId,
            "We have reached the maximum token supply."
        );
        require(msg.value >= NFTprice, "Please send the corect amount");

        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    //tokenURI is need in order to make nft valuable
    //TODO 1. compute baseURI to get TokenURI
    //for that openZepllin has _baseURI which return the string.concat of tokenIDs and baseURI
    //Base URI for computing tokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //withdraw ether from this contract by owner it can be another address
    function withdraw(address _ownerWithdrawAddress) public onlyOwner {
        uint256 _amount = address(this).balance;
        (bool success, ) = _ownerWithdrawAddress.call{value: _amount}("");
        require(success, "Transfer of ether failed");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
