const main = async () => {
    const gameContractFactory = await hre.ethers.getContractFactory('MultiMetaverse');

    const gameContract = await gameContractFactory.deploy(                     
      ["Plumbus", "Mr Meeseks Box", "Portal Gun"],       
      ["https://i.ibb.co/xzdVQLq/plumbus.jpg", 
      "https://i.ibb.co/kqsp9zC/mr-meeseks.jpg", 
      "https://i.ibb.co/nPrBgVx/portalgun.jpg"],
      [100, 200, 300],                    
      [100, 50, 25],
      'Abradolf Lincler',
      'https://i.imgur.com/VAeXKm5g.jpg',
      10000,
      75                         
    );
    
    await gameContract.deployed();
    console.log("Contract deployed to:", gameContract.address);
  
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();