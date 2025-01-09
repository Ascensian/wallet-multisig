// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletDeploy is Script {
    function run() external {
        // Vérifiez que toutes les variables d'environnement requises sont définies
        require(
            bytes(vm.envString("SIGNER0")).length > 0,
            "SIGNER0 environment variable is empty"
        );
        require(
            bytes(vm.envString("SIGNER1")).length > 0,
            "SIGNER1 environment variable is empty"
        );
        require(
            bytes(vm.envString("SIGNER2")).length > 0,
            "SIGNER2 environment variable is empty"
        );

        vm.startBroadcast();

        // Récupération des adresses depuis les variables d'environnement
        address;
        initialSigners[0] = vm.envAddress("SIGNER0");
        initialSigners[1] = vm.envAddress("SIGNER1");
        initialSigners[2] = vm.envAddress("SIGNER2");

        // Instanciation du contrat MultiSigWallet
        MultiSigWallet wallet = new MultiSigWallet(initialSigners, 2);

        vm.stopBroadcast();

        // Affichage de l'adresse du contrat déployé
        console.log("MultiSigWallet deployed at:", address(wallet));
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletDeploy is Script {
    function run() external {
        require(
            bytes(vm.envString("SIGNER0")).length > 0,
            "SIGNER0 environment variable is empty"
        );
        require(
            bytes(vm.envString("SIGNER1")).length > 0,
            "SIGNER1 environment variable is empty"
        );
        require(
            bytes(vm.envString("SIGNER2")).length > 0,
            "SIGNER2 environment variable is empty"
        );

        vm.startBroadcast();

        address;
        initialSigners[0] = vm.envAddress("SIGNER0");
        initialSigners[1] = vm.envAddress("SIGNER1");
        initialSigners[2] = vm.envAddress("SIGNER2");

        MultiSigWallet wallet = new MultiSigWallet(initialSigners, 2);
        vm.stopBroadcast();
        console.log("MultiSigWallet deployed at:", address(wallet));
    }
}
