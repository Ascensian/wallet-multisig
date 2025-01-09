// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletDeploy is Script {
    function run() external {
        vm.startBroadcast();
        address[] memory initialSigners = new address[](3);
        initialSigners[0] = 0x37666e193fE2dA22AF16BcBB83D613eA86844068;
        initialSigners[1] = 0x527216629CB807C0E6d40DbEf09f58bb7974a810;
        initialSigners[2] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

        MultiSigWallet wallet = new MultiSigWallet(initialSigners, 2);
        vm.stopBroadcast();
        console.log("MultiSigWallet deployed at:", address(wallet));
    }
}
