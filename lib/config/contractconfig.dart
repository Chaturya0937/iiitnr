// lib/config/ContractConfig.dart
// NOTE: Replace these placeholder values with your actual deployment details

// 1. Your Contract Address
const String contractAddress = "0xYourDeployedContractAddressGoesHere";

// 2. Your RPC URL (e.g., from Infura or Alchemy for your network)
const String rpcUrl = "https://your-network.rpc.url";

// 3. Your Contract ABI (as a string)
const String abiString = '''
[
  // Paste the relevant parts of your ABI JSON here.
  // For logCheckout:
  {
    "inputs": [
      { "internalType": "bytes32", "name": "_equipmentId", "type": "bytes32" },
      { "internalType": "string", "name": "_studentId", "type": "string" }
    ],
    "name": "logCheckout",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  // ... other functions
]
''';