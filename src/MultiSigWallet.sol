// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MultiSigWallet {
    // ---------------------------------------
    // 1. Variables d’état
    // ---------------------------------------
    address[] public signers;
    uint public requiredConfirmations;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }

    // Tableau de transactions
    Transaction[] public transactions;

    // Mapping txId => (signer => bool)
    mapping(uint => mapping(address => bool)) public confirmations;

    // ---------------------------------------
    // 2. Modifiers
    // ---------------------------------------
    modifier onlySigner() {
        require(isSigner(msg.sender), "Not a signer");
        _;
    }

    // ---------------------------------------
    // 3. Constructeur
    // ---------------------------------------
    constructor(address[] memory _initialSigners, uint _requiredConfirmations) {
        require(_initialSigners.length >= 3, "At least 3 signers required");
        require(
            _requiredConfirmations <= _initialSigners.length &&
                _requiredConfirmations > 0,
            "Invalid number of required confirmations"
        );

        for (uint i = 0; i < _initialSigners.length; i++) {
            signers.push(_initialSigners[i]);
        }
        requiredConfirmations = _requiredConfirmations;
    }

    // ---------------------------------------
    // 4. Fonctions principales
    // ---------------------------------------

    /**
     * @notice Soumet une nouvelle transaction à exécuter par le multisig.
     * @param _to L'adresse destinataire de la transaction.
     * @param _value La quantité d'ETH (en wei) à envoyer.
     * @param _data Les données à exécuter (par ex. un appel de fonction).
     * @return txId L'ID (index) de la transaction soumise.
     */
    function submitTransaction(
        address _to,
        uint _value,
        bytes calldata _data
    ) external onlySigner returns (uint txId) {
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        txId = transactions.length - 1;

        // Émettre un event (facultatif, mais recommandé)
        // emit TransactionSubmitted(txId, msg.sender, _to, _value, _data);
    }

    /**
     * @notice Permet à un signataire de confirmer une transaction donnée.
     * @param _txId L'ID de la transaction à confirmer.
     */
    function confirmTransaction(uint _txId) external onlySigner {
        require(_txId < transactions.length, "Transaction does not exist");
        require(!transactions[_txId].executed, "Transaction already executed");
        require(
            !confirmations[_txId][msg.sender],
            "Transaction already confirmed by this signer"
        );

        confirmations[_txId][msg.sender] = true;
        transactions[_txId].numConfirmations++;

        // emit TransactionConfirmed(_txId, msg.sender);
    }

    /**
     * @notice Permet à un signataire de révoquer sa confirmation.
     * @param _txId L'ID de la transaction à révoquer.
     */
    function revokeConfirmation(uint _txId) external onlySigner {
        require(_txId < transactions.length, "Transaction does not exist");
        require(!transactions[_txId].executed, "Transaction already executed");
        require(
            confirmations[_txId][msg.sender],
            "Transaction not confirmed by this signer"
        );

        confirmations[_txId][msg.sender] = false;
        transactions[_txId].numConfirmations--;

        // emit TransactionRevoked(_txId, msg.sender);
    }

    /**
     * @notice Exécute une transaction si le nombre de confirmations requis est atteint.
     * @param _txId L'ID de la transaction à exécuter.
     */
    function executeTransaction(uint _txId) external onlySigner {
        require(_txId < transactions.length, "Transaction does not exist");
        Transaction storage txn = transactions[_txId];

        require(!txn.executed, "Transaction already executed");
        require(
            txn.numConfirmations >= requiredConfirmations,
            "Not enough confirmations"
        );

        txn.executed = true;

        // Exécution de la transaction
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "Transaction failed");

        // emit TransactionExecuted(_txId, msg.sender);
    }

    /**
     * @notice Ajoute un nouveau signataire au multisig.
     * @param _newSigner L'adresse du nouveau signataire.
     */
    function addSigner(address _newSigner) external onlySigner {
        require(_newSigner != address(0), "Invalid address");
        require(!isSigner(_newSigner), "Address already a signer");

        signers.push(_newSigner);

        // Vérifier qu'on garde au moins 3 signataires
        require(signers.length >= 3, "Must have at least 3 signers");

        // emit SignerAdded(_newSigner);
    }

    /**
     * @notice Retire un signataire existant du multisig.
     * @param _signer L'adresse du signataire à retirer.
     */
    function removeSigner(address _signer) external onlySigner {
        require(isSigner(_signer), "Address not a signer");
        require(signers.length > 3, "Cannot go below 3 signers");

        // Trouver l'index du signataire et le retirer du tableau
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == _signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        require(signers.length >= 3, "Must have at least 3 signers");
        if (requiredConfirmations > signers.length) {
            requiredConfirmations = signers.length;
        }

        // emit SignerRemoved(_signer);
    }

    // ---------------------------------------
    // 5. Fonctions internes / utilitaires
    // ---------------------------------------
    /**
     * @notice Vérifie si une adresse est signataire.
     * @param _account Adresse à vérifier.
     * @return bool True si c'est un signataire, sinon False.
     */
    function isSigner(address _account) public view returns (bool) {
        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == _account) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {}
}
