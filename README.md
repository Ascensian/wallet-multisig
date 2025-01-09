# MultiSigWallet Project

**MultiSigWallet** est un contrat Ethereum permettant à plusieurs signataires de valider et d’exécuter des transactions. Il impose un nombre minimum de confirmations avant de pouvoir exécuter des transferts d’ETH ou des appels de fonction externes.

---

## Fonctionnalités principales

1. **Soumission de transactions**  
   - Un signataire peut soumettre une transaction comprenant :
     - L’adresse destinataire (`to`)  
     - Le montant en ETH à transférer (`value`)  
     - Les données d’appel (`data`)  

2. **Confirmation de transactions**  
   - Chaque signataire peut confirmer ou révoquer sa confirmation pour chaque transaction.

3. **Exécution de transactions**  
   - Une transaction est exécutable lorsqu’elle atteint le nombre minimal de confirmations requis (défini à 2 par défaut).

4. **Gestion des signataires**  
   - Ajout/suppression de signataires tout en maintenant toujours au moins 3 signataires et 2 confirmations requises.

5. **Utilisation de Foundry**  
   - Tests unitaires et script de déploiement écrits en Foundry (`forge`, `cast`).

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Coverage

```shell
$ forge coverage
```

### Script de déploiement

```shell
$ forge script script/MultiSigWallet.s.sol:MultiSigWalletDeploy --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```
