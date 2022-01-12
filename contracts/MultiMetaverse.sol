// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import 'base64-sol/base64.sol';

import "hardhat/console.sol";

contract MultiMetaverse is ERC721 {

  struct WeaponAttributes {
    uint weaponIndex;
    string name;
    string imageURI;        
    uint hp;
    uint maxHp;
    uint attackDamage;
  }

  // The tokenId is the NFTs unique identifier, it's just a number that goes
  // 0, 1, 2, 3, etc.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  WeaponAttributes[] defaultWeapons;

  // We create a mapping from the nft's tokenId => that NFTs attributes.
  mapping(uint256 => WeaponAttributes) public nftHolderAttributes;

  struct BigBoss {
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }

  BigBoss public bigBoss;


  // A mapping from an address => the NFTs tokenId. Gives me an ez way
  // to store the owner of the NFT and reference it later.
  mapping(address => uint256) public nftHolders;

  event WeaponNFTMinted(address sender, uint256 tokenId, uint256 weaponIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);

  constructor(
    string[] memory weaponNames,
    string[] memory weaponImageURIs,
    uint[] memory weaponHP,
    uint[] memory weaponAttackDmg,
    string memory bossName,
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage
  )
    ERC721("Weapons", "WPN")
  {
    // Initialize the boss. Save it to our global "bigBoss" state variable.
    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage
    });

    console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);
    for(uint i = 0; i < weaponNames.length; i += 1) {
      defaultWeapons.push(WeaponAttributes({
        weaponIndex: i,
        name: weaponNames[i],
        imageURI: weaponImageURIs[i],
        hp: weaponHP[i],
        maxHp: weaponHP[i],
        attackDamage: weaponAttackDmg[i]
      }));

      WeaponAttributes memory c = defaultWeapons[i];
      
      // Hardhat's use of console.log() allows up to 4 parameters in any order of following types: uint, string, bool, address
      console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
    }

    // I increment _tokenIds here so that my first NFT has an ID of 1.
    // More on this in the lesson!
    _tokenIds.increment();
  }

  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }

  function getAllDefaultWeapons() public view returns (WeaponAttributes[] memory) {
    return defaultWeapons;
  }

  function checkIfUserHasNFT() public view returns (WeaponAttributes memory) {
    // Get the tokenId of the user's character NFT
    uint256 userNftTokenId = nftHolders[msg.sender];
    // If the user has a tokenId in the map, return their character.
    if (userNftTokenId > 0) {
      return nftHolderAttributes[userNftTokenId];
    }
    // Else, return an empty character.
    else {
      WeaponAttributes memory emptyStruct;
      return emptyStruct;
    }
  }

  function attackBoss() public {
    // Get the state of the player's NFT.
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    WeaponAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];

    console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
    console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
    
    // Make sure the player has more than 0 HP.
    require (
      player.hp > 0,
      "Error: character must have HP to attack boss."
    );

    // Make sure the boss has more than 0 HP.
    require (
      bigBoss.hp > 0,
      "Error: boss must have HP to attack boss."
    );
    
    // Allow player to attack boss.
    if (bigBoss.hp < player.attackDamage) {
      bigBoss.hp = 0;
    } else {
      bigBoss.hp = bigBoss.hp - player.attackDamage;
    }

    // Allow boss to attack player.
    if (player.hp < bigBoss.attackDamage) {
      player.hp = 0;
    } else {
      player.hp = player.hp - bigBoss.attackDamage;
    }
    
    // Console for ease.
    console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
    console.log("Boss attacked player. New player hp: %s\n", player.hp);

    emit AttackComplete(bigBoss.hp, player.hp);
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    WeaponAttributes memory weapAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(weapAttributes.hp);
    string memory strMaxHp = Strings.toString(weapAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(weapAttributes.attackDamage);

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        weapAttributes.name,
        ' -- NFT #: ',
        Strings.toString(_tokenId),
        '", "description": "This is an NFT that lets people play in the game Save the MultiMetaverse!", "image": "',
        weapAttributes.imageURI,
        '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
        strAttackDamage,'} ]}'
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
    
    return output;
  }

  // Users would be able to hit this function and get their NFT based on the
  // characterId they send in!
  function mintCharacterNFT(uint _weaponIndex) external {
    // Get current tokenId (starts at 1 since we incremented in the constructor).
    uint256 newItemId = _tokenIds.current();

    // The magical function! Assigns the tokenId to the caller's wallet address.
    _safeMint(msg.sender, newItemId);

    // We map the tokenId => their character attributes. More on this in
    // the lesson below.
    nftHolderAttributes[newItemId] = WeaponAttributes({
      weaponIndex: _weaponIndex,
      name: defaultWeapons[_weaponIndex].name,
      imageURI: defaultWeapons[_weaponIndex].imageURI,
      hp: defaultWeapons[_weaponIndex].hp,
      maxHp: defaultWeapons[_weaponIndex].maxHp,
      attackDamage: defaultWeapons[_weaponIndex].attackDamage
    });

    console.log("Minted NFT w/ tokenId %s and weaponIndex %s", newItemId, _weaponIndex);
    
    // Keep an easy way to see who owns what NFT.
    nftHolders[msg.sender] = newItemId;

    // Increment the tokenId for the next person that uses it.
    _tokenIds.increment();

    emit WeaponNFTMinted(msg.sender, newItemId, _weaponIndex);
  }
}