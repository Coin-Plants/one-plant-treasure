// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";


contract OnePlantTreasure is Initializable, OwnableUpgradeable {

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token BaseURI
    string private _baseURI;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping from user address to minted count
    mapping(address => uint256) private _mintedCount;

    // Mapping from token ID to minting block
    mapping(uint256 => uint256) private _mintingBlock;

    // Mapping from token ID to ember count
    mapping(uint256 => uint256) private _ember;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //Mint Availability
    bool public open;

    //$POLLEN token address
    address public POLLEN;


    //Current Max Token ID
    uint256 public maxTokenId;

    //Mint interval and Mature time
    uint256 public DURATION;
    uint256 public MATURITY;

    //Lowest Ember
    uint256 public lowestEmber;

    //Smart contract dev's Address
    address public scDev;

    //Frontend dev's address
    address public ftDev;

    //Equity for smart contract dev
    uint256 public equityForSC;

    //Equity for smart contract dev
    uint256 public equityForFT;

    //Length of the whitelist.
    uint256 public countWL;

    //Ratio of the Reward
    uint256 public rewardRatio;

    //Mapping for that user is whitelisted.
    mapping(address => bool) public isWhitelisted;

    //Mapping for that user is whitelisted.
    mapping(uint256 => address) public whitelist;

    //Mapping from address to the amount of $POLLEN token to claim.
    mapping(address => uint256) public rewardAmount;

    //Mapping from address and index to tokenId.
    mapping(address => mapping(uint256 => uint256)) public tokenIds;

    //Mapping from tokenId to the reward amount.
    mapping(uint256 => uint256) public rewardPerId;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enalbles `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enalbles or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Emitted when `tokenId` is minted to `owner`.
     */
    event Minted(address indexed owner, uint256 tokenId, uint256 indexed blockNumber, uint256 index);


    function initialize() public initializer {
        
        __Ownable_init();

        _name = "One Plant Treasure";
        _symbol = "$OPT";
        
        DURATION = 75;   // 15 minutes
        MATURITY = 7200; // 24 hours

        POLLEN = 0x8E7Dc902747F8450bd262E2A51B5030B6f1AD320;
        scDev = 0x372B95Ac394F7dbdDc90f7a07551fb75509346A8;
        ftDev = 0x5546e8e71fCcEc025265fB07D4d4bd46Cee55aa9;

        rewardRatio = 0.000005 ether;
        lowestEmber = 75;
    }


    /*////////////////////////////////////////////////
                     MODIEFIERS
    ////////////////////////////////////////////////*/


    /**
     * @dev Throws if an immature token is transferred.
     */
    modifier onlyMature(uint256 tokenId) {
        require(block.number >= _mintingBlock[tokenId] + MATURITY, "NOT MATURED");
        _;
    }

    /**
     * @dev Throws if caller is not management team
     */
    modifier onlyManager() {
        require(_msgSender() == owner() || _msgSender() == scDev, "NOT_ALLOWED");
        _;
    }


    /*////////////////////////////////////////////////
                    VIEW FUNCTIONS
    ////////////////////////////////////////////////*/


    /**
     * @dev See the token name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev See the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See the token base URI.
     */
    function baseURI() public view returns(string memory) {
        return _baseURI;
    }

    /**
     * @dev See the token ID owner.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Invalid tokenID");
        return _owners[tokenId];
    }

    /**
     * @dev See the minted count.
     */
    function mintedCountOf(address owner) public view returns(uint256) {
        require(owner != address(0), "INVALID_ADDRESS");
        return _mintedCount[owner];
    }

    /**
     * @dev See the block number where token was issued.
     */
    function mintingBlockOf(uint256 tokenId) public view returns(uint256) {
        require(_exists(tokenId), "Invalid tokenID");
        return _mintingBlock[tokenId];
    }

    /**
     * @dev See the ember for which the token was issued.
     */
    function emberOf(uint256 tokenId) public view returns(uint256) {
        require(_exists(tokenId), "Invalid tokenID");
        return _ember[tokenId];
    }

    /**
     * @dev See the balance of token.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Zero Address");
        return _balances[owner];
    }

    /**
     * @dev See the token ID approval.
     */
    function getApproved(uint256 tokenId) public view returns(address) {
        require(_exists(tokenId), "Invalid tokenID");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See the token ID approval for all.
     */
    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See METADATA
     */
    function tokenURI(uint256 tokenId) public view returns(string memory) {
        require(_exists(tokenId), "NOT_EXIST");
        
        return string(abi.encodePacked(baseURI(), tokenId, ".json"));
    }

    /**
     * @dev See the last minted block number
     */
    function lastMinted() public view returns(uint256) {
      return maxTokenId == 0 ? block.number : _mintingBlock[maxTokenId];
    }


    /*////////////////////////////////////////////////
                  ERC721 UTILITY FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @dev Mint One Plant NFT
     */
    function mint() external payable {
        require(open,                                    "NOT OPEN");
        require(block.number <= lastMinted() + DURATION, "GAME OVER");

        maxTokenId++;
        uint256 index = getEmber();
        if(index < lowestEmber) lowestEmber = index;

        if(msg.value > 0) {
          uint256 amount = msg.value / rewardRatio;
          rewardAmount[_msgSender()] += amount;
          rewardPerId[maxTokenId] = amount;
        }
        
        if(msg.value >= 0.02 ether) {
          addWhitelist(_msgSender());
        }

        equityForSC += msg.value / 10;
        equityForFT += msg.value / 20;

        emit Minted(_msgSender(), maxTokenId, block.number, index);
        _safeMint(_msgSender(), maxTokenId, index);
    }

    /**
     * @dev Function to claim the reward in $POLLEN token.
     */
    function claimReward() external {
      address owner = _msgSender();
      require(rewardAmount[owner] > 0, "NO_REWARD");
      uint256 value = 0;
      for(uint256 i = 1; i <= _mintedCount[owner]; i ++) {
        uint256 index = tokenIds[owner][i];
        uint256 mintedBlock = _mintingBlock[index];

        if(block.number < mintedBlock + MATURITY) break;
        value += rewardPerId[index];
        rewardAmount[owner] -= rewardPerId[index];
        rewardPerId[index] = 0;
      }

      require(value > 0, "NOT_IN_TIME");
      IERC20Upgradeable(POLLEN).transfer(_msgSender(), value * 10**18);
    }

    /**
     * @dev Token owner approves `to` to manage `tokenId` token.
     */
    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "Approval to owner");
        require(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()), "NOT_AUTHORIZED");
        
        _tokenApprovals[tokenId] = to;
        emit Approval(owner_, to, tokenId);
    }

    /**
     * @dev Owner approves `operator` to manage all of its assets.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(_msgSender() != operator, "Approve to owner");
        _operatorApprovals[_msgSender()][operator] = approved;

        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev transferFrom function implementation.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyMature(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "WRONG_FROM");
        require(to != address(0), "INVALID_RECEIVER");

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev safeTransferFrom implementation.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public onlyMature(tokenId) {

        safeTransferFrom(from, to, tokenId, "");

    }

    /**
     * @dev safeTransferFrom other implementation.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyMature(tokenId) {

        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );

    }

    /*////////////////////////////////////////////////
                  ADDITIONAL FUNCTIONS
    ////////////////////////////////////////////////*/
    
    /**
     * @dev Set the mint availability.
     */
    function setOpen(bool _open) external onlyManager {
      open = _open;
    }

    /**
     * @dev Set token base URI
     */
    function setBaseURI(string memory _uri) external onlyManager {
        _baseURI = _uri;
    }

    /**
     * @dev Set the ratio of the reward.
     */
    function setRewardRatio(uint256 _value) external onlyOwner {
      rewardRatio = _value * 10**18;
    }

    /**
     * @dev Get the number of blocks left.
     */
    function getEmber() public view returns(uint256) {
        uint256 elapsed = block.number - lastMinted();

        require(DURATION > elapsed, "GAME OVER");

        return DURATION - elapsed;
    }


    /**
     * @dev Withdraw ETH for frontend dev.
     */
    function withdrawForFT() external {
      require(_msgSender() == ftDev, "NOT_DEV");
      (bool success, ) = payable(ftDev).call{value: equityForFT}("");
      require(success, "Transfer Failed");
      equityForFT = 0;
    }

    /**
     * @dev Withdraw ETH for smart contract dev.
     */
    function withdrawForSC() external {
      require(_msgSender() == scDev, "NOT_DEV");
      (bool success, ) = payable(scDev).call{value: equityForSC}("");
      require(success, "Transfer Failed");
      equityForSC = 0;
    }

    /**
     * @dev Withdraw ETH for Owner.
     */
    function withdrawAllForOwner() external onlyOwner {
      uint256 amount = address(this).balance - ( equityForSC + equityForFT );
      (bool success, ) = payable(_msgSender()).call{value: amount}("");
      require(success, "Transfer Failed!");
    }


    /*////////////////////////////////////////////////
                  INTERNAL FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @dev Internal mint function
     */
    function _mint(address to, uint256 tokenId, uint256 ember_) private {
        require(to != address(0), "INVALID_RECEIVER");

        unchecked {
            _balances[to]++;   
            _mintedCount[to]++;
        }
        
        _owners[tokenId] = to;
        _mintingBlock[tokenId] = block.number;
        _ember[tokenId] = ember_;

        tokenIds[to][_mintedCount[to]] = tokenId;
    }

    function _safeMint(address to, uint256 id, uint256 index) private {
       _safeMint(to, id, index, "");
    }

    function _safeMint(
        address to,
        uint256 id,
        uint256 index,
        bytes memory data
    ) private {
        _mint(to, id, index);

        require(
            _checkOnERC721Received(address(0), to, id, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Add user to whitelist.
     */
    function addWhitelist(address user) private {
        isWhitelisted[user] = true;
        whitelist[++countWL] = user;
    }

    /**
     * @dev See the token ID existence.
     */
    function _exists(uint256 tokenId) private view returns(bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     *@dev Returns whether `spender` is allowed to manage `tokenID`
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns(bool) {
        address owner_ = ownerOf(tokenId);
        return ( spender == owner_ || isApprovedForAll(owner_, spender) || getApproved(tokenId) == spender );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}