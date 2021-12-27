// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./Strings.sol";
import "./HeroLibrary.sol";
import "./ERC721URIStorage.sol";
import "./AccessControl.sol";

contract CharacterPeeSale is AccessControl, ERC721, ERC721URIStorage {
  using Strings for uint256;

  bytes32 public constant GAME_ADMIN = keccak256("GAME_ADMIN");
  bytes32 public constant NO_OWNED_LIMIT = keccak256("NO_OWNED_LIMIT");

  uint256[] public heroRaritys;
  uint256[] public heroNames;
  uint256[][] public randomTable;
  uint8[4] public heroTypeLength;
  // amount of hero in same type

  // Follow pattern ERC721 Enumerable
  HeroLibrary.Hero[] private _heroes;
  mapping(address => uint256[]) _ownedTokens;
  mapping(uint256 => uint256) _ownedTokensIndex;

  string private baseURI;

  constructor() ERC721("BNBHCharacter", "BHC") {
    HeroLibrary.Hero memory fillGapHero = HeroLibrary.Hero(
      0,
      0,
      0
    );

    _heroes.push(fillGapHero);

    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(GAME_ADMIN, DEFAULT_ADMIN_ROLE);
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not admin");
    _;
  }

  modifier onlyOwnerOf(address account, uint256 _heroId) {
    require(ownerOf(_heroId) == account, "Must be owner of hero to battle");
    _;
  }

  modifier restricted() {
    _restricted();
    _;
  }

  function _restricted() internal view {
    require(hasRole(GAME_ADMIN, msg.sender), "Does not have role");
  }

  function setGameAdmin(address _gameAdmin) external onlyOwner {
    _grantRole(GAME_ADMIN, _gameAdmin);
  }

  function setHeroRarity(uint256[] memory values) external onlyOwner {
    heroRaritys = values;
  }

  function setRandomTable(uint256[][] memory values) external onlyOwner {
    randomTable = values;
  }

  function setHeroTypeLength(uint8[4] memory values) external onlyOwner {
    heroTypeLength = values;
  }

  function tokensOfOwner(address owner)
    external
    view
    returns (uint256[] memory)
  {
    return _ownedTokens[owner];
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256)
  {
    require(
      index < balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][index];
  }

  function totalSupply() public view returns (uint256) {
    return _heroes.length;
  }

  function tokenByIndex(uint256 index)
    external
    view
    returns (HeroLibrary.Hero memory)
  {
    require(
      index < totalSupply(),
      "ERC721Enumerable: global index out of bounds"
    );
    return _heroes[index];
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  function getHero(uint256 _heroId)
    external
    view
    returns (HeroLibrary.Hero memory)
  {
    return _getHero(_heroId);
  }

  function getRarity(uint256 _heroId) external view returns (uint256) {
    return _heroes[_heroId].heroRarity;
  }

  function _getHero(uint256 _heroId)
    internal
    view
    returns (HeroLibrary.Hero memory)
  {
    require(_heroId < _heroes.length, "Does not exist hero");
    HeroLibrary.Hero memory hero = _heroes[_heroId];
    return hero;
  }

  function getRandomInRange(
    uint256 seed,
    uint256 min,
    uint256 max
  ) internal pure returns (uint256) {
    uint256 range = max - min + 1;
    return (seed % range) + min;
  }

  function mint(address minter, uint256 seed, uint256 typeBox)
    external
    restricted
    returns (uint256)
  {
    uint256 id = _heroes.length;
    uint256 seedNum = randomTable[seed % 100][typeBox];
    uint256 heroNameNum = seed % heroTypeLength[seedNum];
    _heroes.push(
      HeroLibrary.Hero(
        seedNum,
        heroNames[heroNameNum],
        id
      )
    );
    _safeMint(minter, id);
    return id;
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    require(_exists(tokenId), "Cannot query non-existent token");

    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}
