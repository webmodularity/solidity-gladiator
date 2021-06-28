require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.3",
  networks: {
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/8c6ed301e95847798eeaf1a2dbf3d5ec",
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};

