// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

contract OnePlantTreasureV2 is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    mapping(uint256 => bool) public isClaimed;
    mapping(uint256 => uint256) public mintingBlockOf;
    mapping(uint256 => uint256) public emberOf;
    mapping(uint256 => bool) public didProvideValue;
    CountersUpgradeable.Counter public maxTokenId;
    uint256 public DURATION;
    uint256 public MATURITY;
    address public POLLEN;

    address public smartDev;
    address public frontDev;
    bool public open;
    uint256 public lowestEmber;
    string internal baseURI_;

    /**
     * @dev Emitted when mint is opened.
     */
    event OpenMint(bool indexed flag);

    /**
     * @dev Emitted when a token is minted, providing supplimentary details.
     */
    event MintMeta(
        address to,
        uint256 indexed tokenId,
        uint256 indexed ember,
        uint256 indexed value
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _pollen) public initializer {
        __ERC721_init("One Plant Treasure", "$OPT");
        __Ownable_init();
        __UUPSUpgradeable_init();

        DURATION = 75; // 15 minutes
        MATURITY = 7200; // 24 hours

        POLLEN = _pollen;
        smartDev = 0x372B95Ac394F7dbdDc90f7a07551fb75509346A8;
        frontDev = 0x5546e8e71fCcEc025265fB07D4d4bd46Cee55aa9;
    }

    /**
     * @dev Throws if an immature token is transferred.
     */
    modifier onlyMature(uint256 tokenId) {
        require(
            block.number >= mintingBlockOf[tokenId] + MATURITY,
            "NOT MATURED"
        );
        _;
    }

    /**
     * @dev Throws if caller is not management team
     */
    modifier onlyManager() {
        require(
            _msgSender() == owner() || _msgSender() == smartDev,
            "NOT_ALLOWED"
        );
        _;
    }

    function _sendEtherTo(address payable _to, uint256 _amount) private {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        uint256 ember = emberOf[tokenId];
        return
            bytes(baseURI_).length > 0
                ? string(abi.encodePacked(baseURI_, ember.toString(), ".json"))
                : "";
    }

    /**
     * @dev See the block number of the first open block
     */
    function firstOpenBlock() external view returns (uint256) {
        return mintingBlockOf[0];
    }

    /**
     * @dev See the last minted block number
     */
    function lastMinted() public view returns (uint256) {
        return mintingBlockOf[maxTokenId.current()];
    }

    /**
     * @dev Set token base URI
     */
    function setBaseURI(string memory _uri) external onlyManager {
        baseURI_ = _uri;
    }

    /**
     * @dev Get the number of blocks left.
     */
    function currentEmber() public view returns (uint256) {
        require(_gameIsNotOver(), "GAME OVER");
        return DURATION - (block.number - lastMinted());
    }

    function mint() external payable {
        require(open, "NOT OPEN");
        require(_gameIsNotOver(), "GAME OVER");
        uint256 ember = currentEmber();
        maxTokenId.increment();
        uint256 tokenId = maxTokenId.current();
        if (ember < lowestEmber) lowestEmber = ember;

        // Ether Distribution
        if (msg.value > 0) {
            didProvideValue[tokenId] = true;
            uint256 equityForSmartDev = (msg.value * 10) / 100;
            uint256 equityForFrontDev = (msg.value * 20) / 100;
            _sendEtherTo(payable(smartDev), equityForSmartDev);
            _sendEtherTo(payable(frontDev), equityForFrontDev);
            _sendEtherTo(
                payable(owner()),
                msg.value - equityForSmartDev - equityForFrontDev
            );
        }

        // Token Meta
        mintingBlockOf[tokenId] = block.number;
        emberOf[tokenId] = ember;
        emit MintMeta(msg.sender, tokenId, ember, msg.value);

        // Mint
        _safeMint(msg.sender, tokenId);
    }

    /**
     * @dev Function to claim the reward in $POLLEN token.
     */
    function claimReward(
        uint256 tokenId
    ) external onlyMature(tokenId) returns (uint256) {
        require(_exists(tokenId), "INVALID_TOKEN_ID");
        require(!isClaimed[tokenId], "OWNER_CLAIMED");
        require(ownerOf(tokenId) == _msgSender(), "NOT_OWNER");
        require(didProvideValue[tokenId], "NO_VALUE_PROVIDED");

        isClaimed[tokenId] = true;
        IERC20 token = IERC20(POLLEN);
        uint256 amount = getAmountOfReward(tokenId) * 10 ** token.decimals();
        token.transfer(msg.sender, amount);
        return amount;
    }

    function getAmountOfReward(uint256 tokenId) public view returns (uint256) {
        if (!didProvideValue[tokenId]) return 0;
        uint256 value = DURATION - emberOf[tokenId];
        uint256 index = value / 5;
        uint256 mainValue = (index == 0) ? 0 : 2 ** (index - 1) * 10;
        uint256 restValue = (value % 5) + 1;

        uint256 amount = mainValue + restValue;
        if (value == 74) amount += 18075;

        return amount;
    }

    /**
     * @dev Set the mint availability.
     */
    function setOpen(bool _open) external onlyManager {
        open = _open;
        mintingBlockOf[0] = block.number;
        emit OpenMint(_open);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyManager {}

    function _gameIsNotOver() internal view returns (bool) {
        return block.number < _gameOverBlock();
    }

    function _gameOverBlock() internal view returns (uint256) {
        return lastMinted() + DURATION;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable) {
        require(
            from == address(0) ||
                block.number >= mintingBlockOf[tokenId] + MATURITY,
            "NOT MATURED"
        );
        // Require game is not over
        // Or token was minted 24hrs before the game ended
        require(
            _gameIsNotOver() ||
                mintingBlockOf[tokenId] + MATURITY <= _gameOverBlock(),
            "TOKEN FROZEN"
        );
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
