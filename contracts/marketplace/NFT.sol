// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../heros/CharacterPeeSale.sol";

contract NFT is CharacterPeeSale {
	uint private _tokenId = 0;

	function mint() external returns (uint) {
		_tokenId++;
		_mint(msg.sender, _tokenId);
		return _tokenId;
	}
}