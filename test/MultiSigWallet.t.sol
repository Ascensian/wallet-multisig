// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

/**
 * @title MultiSigWalletTest
 * @notice Tests pour couvrir toutes les fonctionnalités de MultiSigWallet
 */
contract MultiSigWalletTest is Test {
    // --- Définition des adresses de test ---
    address internal sign1 = address(0x1111);
    address internal sign2 = address(0x2222);
    address internal sign3 = address(0x3333);
    address internal sign4 = address(0x4444); // servira de nouveau signataire
    address internal nonSigner = address(0x9999);

    MultiSigWallet internal wallet;

    // --------------------------------
    // setUp : initialisation du test
    // --------------------------------
    function setUp() public {
        // On prépare un tableau avec 3 signataires initiaux
        address[] memory initialSigners = new address[](3);
        initialSigners[0] = sign1;
        initialSigners[1] = sign2;
        initialSigners[2] = sign3;

        // Déploiement du wallet avec 2 confirmations requises
        wallet = new MultiSigWallet(initialSigners, 2);

        // On envoie 1 ETH au contrat pour avoir de la balance
        // (on envoie depuis l'adresse "this" – le contrat de test)
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        require(success, "Funding failed");
    }

    // --------------------------------
    // 1. Tests sur le déploiement
    // --------------------------------
    function testInitialParameters() public view {
        // Vérifier qu'il y a bien 3 signataires
        // et que la valeur requiredConfirmations = 2
        assertEq(wallet.signers(0), sign1);
        assertEq(wallet.signers(1), sign2);
        assertEq(wallet.signers(2), sign3);
        assertEq(wallet.requiredConfirmations(), 2);

        // Vérifier que le wallet a bien 1 ETH
        assertEq(address(wallet).balance, 1 ether);
    }

    // --------------------------------
    // 2. Tests sur submitTransaction
    // --------------------------------
    function testSubmitTransactionBySigner() public {
        // On se fait passer pour sign1
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // Vérifier que la transaction est créée correctement
        // On attend que cette nouvelle transaction soit la 1ère (index 0 si c'est la première)
        (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        ) = wallet.transactions(txId);

        assertEq(to, address(0xABC));
        assertEq(value, 0.1 ether);
        assertEq(data, bytes("0x1234"));
        assertEq(executed, false);
        assertEq(numConfirmations, 0);
    }

    function testSubmitTransactionByNonSignerShouldRevert() public {
        // On se fait passer pour une adresse non signataire
        vm.prank(nonSigner);
        vm.expectRevert("Not a signer");
        wallet.submitTransaction(address(0xABC), 0.1 ether, "0x1234");
    }

    // --------------------------------
    // 3. Tests sur confirmTransaction
    // --------------------------------
    function testConfirmTransaction() public {
        // 1) sign1 crée une transaction
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // 2) sign2 confirme la transaction
        vm.prank(sign2);
        wallet.confirmTransaction(txId);

        // On vérifie que la confirmation a été prise en compte
        (, , , , uint numConfirmations) = wallet.transactions(txId);
        assertEq(numConfirmations, 1);

        // On vérifie aussi que sign2 ne peut pas confirmer 2 fois
        vm.expectRevert("Transaction already confirmed by this signer");
        vm.prank(sign2);
        wallet.confirmTransaction(txId);
    }

    function testConfirmTransactionByNonSigner() public {
        // 1) sign1 crée une transaction
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // 2) Non-signer tente de confirmer
        vm.expectRevert("Not a signer");
        vm.prank(nonSigner);
        wallet.confirmTransaction(txId);
    }

    function testConfirmNonExistentTxShouldRevert() public {
        // Tenter de confirmer un tx inexistant
        vm.prank(sign1);
        vm.expectRevert("Transaction does not exist");
        wallet.confirmTransaction(9999);
    }

    // --------------------------------
    // 4. Tests sur revokeConfirmation
    // --------------------------------
    function testRevokeConfirmation() public {
        // 1) sign1 crée la tx
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // 2) sign2 confirme
        vm.prank(sign2);
        wallet.confirmTransaction(txId);

        // 3) sign2 révoque
        vm.prank(sign2);
        wallet.revokeConfirmation(txId);

        // Vérifier que la confirmation est bien révoquée
        (, , , , uint numConfirmations) = wallet.transactions(txId);
        assertEq(numConfirmations, 0);
    }

    function testRevokeConfirmationNotConfirmedShouldRevert() public {
        // 1) sign1 crée la tx
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // 2) sign2 n'a pas confirmé, donc révoquer doit échouer
        vm.prank(sign2);
        vm.expectRevert("Transaction not confirmed by this signer");
        wallet.revokeConfirmation(txId);
    }

    function testRevokeConfirmationAlreadyExecutedShouldRevert() public {
        // 1) sign1 crée la tx
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // 2) sign1 et sign2 confirment
        vm.prank(sign1);
        wallet.confirmTransaction(txId);
        vm.prank(sign2);
        wallet.confirmTransaction(txId);

        // 3) On exécute
        vm.prank(sign1);
        wallet.executeTransaction(txId);

        // 4) Tenter de révoquer alors que la tx est exécutée => revert
        vm.prank(sign2);
        vm.expectRevert("Transaction already executed");
        wallet.revokeConfirmation(txId);
    }

    // --------------------------------
    // 5. Tests sur executeTransaction
    // --------------------------------
    function testExecuteTransaction() public {
        // 1) sign1 crée la tx
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(address(this), 0.1 ether, "0x");

        // 2) sign2 confirme
        vm.prank(sign2);
        wallet.confirmTransaction(txId);

        // 3) sign1 exécute (on a 2 confirmations sur 2 requises)
        vm.prank(sign1);
        wallet.executeTransaction(txId);

        // Vérifier que la tx est marquée exécutée
        (, , , bool executed, ) = wallet.transactions(txId);
        assertTrue(executed, "Transaction should be marked executed");

        // Vérifier qu'on a bien reçu 0.1 ETH sur `address(this)`
        // Au départ, on avait 0 ETH sur `address(this)` (celui du test), car on a tout envoyé au wallet
        // On récupère 0.1 ETH depuis le wallet
        assertEq(address(this).balance, 0.1 ether);
    }

    function testExecuteTransactionWithoutEnoughConfirmationsShouldRevert()
        public
    {
        // 1) sign1 crée la tx
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.1 ether,
            "0x1234"
        );

        // 2) On essaie de l'exécuter tout de suite avec 0 confirmations
        vm.prank(sign1);
        vm.expectRevert("Not enough confirmations");
        wallet.executeTransaction(txId);
    }

    function testExecuteTransactionAlreadyExecutedShouldRevert() public {
        // 1) sign1 crée la tx
        vm.prank(sign1);
        uint txId = wallet.submitTransaction(
            address(0xABC),
            0.0 ether,
            "0x1234"
        );

        // 2) sign1 et sign2 confirment
        vm.prank(sign1);
        wallet.confirmTransaction(txId);
        vm.prank(sign2);
        wallet.confirmTransaction(txId);

        // 3) On exécute une première fois
        vm.prank(sign1);
        wallet.executeTransaction(txId);

        // 4) On tente de l'exécuter à nouveau
        vm.prank(sign2);
        vm.expectRevert("Transaction already executed");
        wallet.executeTransaction(txId);
    }

    // --------------------------------
    // 6. Tests sur addSigner
    // --------------------------------
    function testAddSigner() public {
        // On se fait passer pour sign1
        vm.prank(sign1);
        wallet.addSigner(sign4);

        // Vérifier que sign4 est bien ajouté
        assertTrue(wallet.isSigner(sign4), "Sign4 should be a signer now");

        // Vérifier qu'on a bien 4 signataires
        // On teste en récupérant la longueur
        // (Il n'y a pas de fonction publique native pour la longueur, mais on peut vérifier directement :
        // soit en itérant, soit en récupérant le dernier signers(x))
        // Pour la démonstration, on va juste vérifier isSigner sur sign1, sign2, sign3, sign4
        assertTrue(wallet.isSigner(sign1));
        assertTrue(wallet.isSigner(sign2));
        assertTrue(wallet.isSigner(sign3));
        assertTrue(wallet.isSigner(sign4));
    }

    function testAddSignerAlreadySignerShouldRevert() public {
        vm.prank(sign1);
        vm.expectRevert("Address already a signer");
        wallet.addSigner(sign1);
    }

    function testAddSignerZeroAddressShouldRevert() public {
        vm.prank(sign1);
        vm.expectRevert("Invalid address");
        wallet.addSigner(address(0));
    }

    function testAddSignerByNonSignerShouldRevert() public {
        // Seule un signataire peut ajouter
        vm.prank(nonSigner);
        vm.expectRevert("Not a signer");
        wallet.addSigner(sign4);
    }

    // --------------------------------
    // 7. Tests sur removeSigner
    // --------------------------------
    function testRemoveSigner() public {
        // On a actuellement 3 signataires (sign1, sign2, sign3).
        // On en ajoute un 4ème (sign4) pour pouvoir retirer quelqu'un
        vm.prank(sign1);
        wallet.addSigner(sign4);

        // On retire sign2 par exemple
        vm.prank(sign1);
        wallet.removeSigner(sign2);

        // On s'assure que sign2 n'est plus signataire
        assertFalse(wallet.isSigner(sign2), "Sign2 should be removed");
        // On s'assure que sign4 est toujours signer
        assertTrue(wallet.isSigner(sign4));

        // Nombre de signers restants : sign1, sign3, sign4 => 3 signers
        assertTrue(wallet.isSigner(sign1));
        assertTrue(wallet.isSigner(sign3));
        assertTrue(wallet.isSigner(sign4));
    }

    function testRemoveSignerGoingBelow3ShouldRevert() public {
        // On a 3 signataires initiaux
        // Retirer l'un d'eux ferait passer à 2 => revert
        vm.prank(sign1);
        vm.expectRevert("Cannot go below 3 signers");
        wallet.removeSigner(sign2);
    }

    function testRemoveNonExistentSignerShouldRevert() public {
        // On ajoute d'abord un 4ème signataire pour qu'on puisse faire des remove
        vm.prank(sign1);
        wallet.addSigner(sign4);

        // Tenter de retirer un signataire qui n'en est pas un
        vm.prank(sign1);
        vm.expectRevert("Address not a signer");
        wallet.removeSigner(nonSigner);
    }

    function testRemoveSignerByNonSignerShouldRevert() public {
        // On ajoute un 4ème signataire d'abord
        vm.prank(sign1);
        wallet.addSigner(sign4);

        // On essaie de retirer sign2 en se faisant passer pour un non-signer
        vm.prank(nonSigner);
        vm.expectRevert("Not a signer");
        wallet.removeSigner(sign2);
    }

    // --------------------------------
    // 8. Test utilitaire : isSigner
    // --------------------------------
    function testIsSigner() public view {
        // On vérifie qu'on a 3 signers initiaux
        assertTrue(wallet.isSigner(sign1));
        assertTrue(wallet.isSigner(sign2));
        assertTrue(wallet.isSigner(sign3));
        // On vérifie qu'on n'est pas signer
        assertFalse(wallet.isSigner(nonSigner));
    }

    // --------------------------------
    // 9. Test du fallback/receive
    // --------------------------------
    function testReceiveEther() public {
        // Contrat est déjà fundé, testons un envoi supplémentaire
        uint initialBalance = address(wallet).balance;
        assertEq(initialBalance, 1 ether);

        vm.deal(address(this), 1 ether);
        (bool success, ) = address(wallet).call{value: 0.5 ether}("");
        require(success, "send extra funds failed");

        // Balance doit être 1.5 ETH maintenant
        assertEq(address(wallet).balance, 1.5 ether);
    }
}
