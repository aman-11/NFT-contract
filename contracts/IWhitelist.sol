// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//since already deployed the whitelist contract so just make interface instead of creating whole contract and then deploying
//as this will use more gas which we dont want

interface IWhitelist {
    function whitelistedAddress(address) external view returns (bool);
}
