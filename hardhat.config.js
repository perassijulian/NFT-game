require('@nomiclabs/hardhat-waffle');

module.exports = {
  solidity: '0.8.0',
  networks: {
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/Zdrep-6t4UyXYPXvVoC_pqoRzcfIH1qo",
      accounts: ["d2200023ede491803c51227ae5d6accfa1ca22474be3962d75a3c99c5f323872"],
    },
  },
};