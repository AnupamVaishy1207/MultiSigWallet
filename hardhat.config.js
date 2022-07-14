require("@nomiclabs/hardhat-waffle");
const fs = require("fs");
const privateKey = fs.readFileSync(".secret").toString();
module.exports = {
    networks: {
        hardhat: {
            chainId: 1337,
        },
        mumbai: {
            url: "https://polygon-mumbai.g.alchemy.com/v2/mFzftzMHjuammqDLF4Kc8RjWNRnboFDJ",
            accounts: [privateKey],
        },
    },
    solidity: "0.8.0",
};