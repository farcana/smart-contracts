// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FarcanaToken is ERC20, Ownable {
    event Burn(address indexed burner, uint256 value);

	
    constructor(string memory name, string memory symbol) ERC20(name, symbol) Ownable(msg.sender) {
        uint256 _decimals = 18;
        uint256 totalSupply = 5000000000 * 10**_decimals;
        _mint(msg.sender, totalSupply);
    }
	
	function burn(uint256 _value) public onlyOwner {
		_burn(msg.sender, _value);
    emit Burn(msg.sender, _value);
	}
 
}