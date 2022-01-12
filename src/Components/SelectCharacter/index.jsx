import React, { useEffect, useState } from 'react';
import './SelectCharacter.css';
import { ethers } from 'ethers';
import { CONTRACT_ADDRESS, transformCharacterData } from '../../constants';
import MultiMetaverse from '../../utils/MultiMetaverse.json';

const SelectCharacter = ({ setWeaponNFT }) => {
  const [weapons, setWeapons] = useState([]);
  const [gameContract, setGameContract] = useState(null);

  // Actions
  const mintWeaponNFTAction = (weaponID) => async () => {
    try {
      if (gameContract) {
        console.log('Minting weapon in progress...');
        const mintTxn = await gameContract.mintCharacterNFT(weaponID);
        await mintTxn.wait();
        console.log('mintTxn:', mintTxn);
        alert(`Your NFT is all done -- see it here: https://testnets.opensea.io/assets/${gameContract}/${weaponID.toNumber()}`)
      }
    } catch (error) {
      console.warn('MintCharacterAction Error:', error);
    }
  };

  const renderWeapons = () =>
    weapons.map((weapon, index) => (
      <div className="character-item" key={weapon.name}>
        <div className="name-container">
          <p>{weapon.name}</p>
        </div>
        <img src={weapon.imageURI} alt={weapon.name} />
        <button
          type="button"
          className="character-mint-button"
          onClick={mintWeaponNFTAction(index)}
        >{`Mint ${weapon.name}`}</button>
      </div>
    ));

  useEffect(() => {
    const { ethereum } = window;
  
    if (ethereum) {
      const provider = new ethers.providers.Web3Provider(ethereum);
      const signer = provider.getSigner();
      const gameContract = new ethers.Contract(
        CONTRACT_ADDRESS,
        MultiMetaverse.abi,
        signer
      );
  
      /*
       * This is the big difference. Set our gameContract in state.
       */
      setGameContract(gameContract);
    } else {
      console.log('Ethereum object not found');
    }
  }, []);

  useEffect(() => {
    const getWeapons = async () => {
      try {
        console.log('Getting contract weapons to mint');
  
        /*
         * Call contract to get all mint-able weapons
         */
        const weaponsTxn = await gameContract.getAllDefaultWeapons();
        console.log('weaponsTxn:', weaponsTxn);
  
        /*
         * Go through all of our weapons and transform the data
         */
        const weapons = weaponsTxn.map((characterData) =>
          transformCharacterData(characterData)
        );
  
        /*
         * Set all mint-able weapons in state
         */
        setWeapons(weapons);
      } catch (error) {
        console.error('Something went wrong fetching weapons:', error);
      }
    };

    const onWeaponMint = async (sender, tokenId, weaponIndex) => {
      console.log(
        `WeaponNFTMinted - sender: ${sender} tokenId: ${tokenId.toNumber()} weaponIndex: ${weaponIndex.toNumber()}`
      );
  
      /*
       * Once our weapon NFT is minted we can fetch the metadata from our contract
       * and set it in state to move onto the Arena
       */
      if (gameContract) {
        const weaponNFT = await gameContract.checkIfUserHasNFT();
        console.log('WeaponNFT: ', weaponNFT);
        setWeaponNFT(transformCharacterData(weaponNFT));
      }
    };


    if (gameContract) {
      getWeapons();
  
      /*
       * Setup NFT Minted Listener
       */
      gameContract.on('WeaponNFTMinted', onWeaponMint);
    }
  
    return () => {
      /*
       * When your component unmounts, let;s make sure to clean up this listener
       */
      if (gameContract) {
        gameContract.off('WeaponNFTMinted', onWeaponMint);
      }
    };
  }, [gameContract]);


  return (
    <div className="select-character-container">
      <h2>Mint Your Weapon. Choose wisely.</h2>
      {/* Only show this when there are weapons in state */}
      {weapons.length > 0 && (
        <div className="character-grid">{renderWeapons()}</div>
      )}
    </div>
  );
};

export default SelectCharacter;