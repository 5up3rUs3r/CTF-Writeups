# Smart Bid (400 pts - WEB3)

## Challenge Description
> What is blockchain, but have you ever interfaced with it? Now's your lucky day to get a crash course! I have provided a blockchain/web3 contract written in Solidity.

**URL:** `http://challenge.perfectroot.wiki:7337`

## TL;DR
Simple Solidity challenge requiring calling a contract function with the correct string argument to set a boolean flag.

## Initial Analysis
Received `Blockchain101.sol`:
```solidity
contract Blockchain101 {
    bool private chall_solved;

    function solveChall(string memory argument) public {
        if (keccak256(abi.encodePacked(argument)) == 
            keccak256(abi.encodePacked("hackerschallenge"))) {
            chall_solved = true;
        }
    }

    function isSolved() external view returns (bool) {
        return chall_solved;
    }
}
```

**Solution:** Call `solveChall("hackerschallenge")` to set `chall_solved = true`

## Solution

### Step 1: Solve Proof of Work
Used the web interface to solve PoW challenge (or clicked "Solve in Browser")

### Step 2: Launch Instance
Received credentials:
- RPC URL
- Contract Address  
- Private Key

### Step 3: Write Exploit Script
```python
from web3 import Web3
import json

RPC_URL = "http://challenge.perfectroot.wiki:7337/[instance-id]"
CONTRACT_ADDRESS = "0x..."
PRIVATE_KEY = "..."

w3 = Web3(Web3.HTTPProvider(RPC_URL))
account = w3.eth.account.from_key(PRIVATE_KEY)

CONTRACT_ABI = json.loads('[{"inputs":[{"internalType":"string","name":"argument","type":"string"}],"name":"solveChall","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"isSolved","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}]')

contract = w3.eth.contract(address=CONTRACT_ADDRESS, abi=CONTRACT_ABI)

# Build, sign, and send transaction
tx = contract.functions.solveChall("hackerschallenge").build_transaction({
    'from': account.address,
    'nonce': w3.eth.get_transaction_count(account.address),
    'gas': 200000,
    'gasPrice': w3.eth.gas_price
})

signed_tx = w3.eth.account.sign_transaction(tx, PRIVATE_KEY)
tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
```

### Step 4: Get Flag
Clicked "Flag" button on the website after `isSolved()` returned `true`

## Flag
```
r00t{is_Sm4rtc0ntr4ct5_h4ck1ng_really_f0r_n00bs??}
```

## Key Takeaways
- **Web3 basics** - Interacting with Ethereum smart contracts via RPC
- **Transaction signing** - How to sign transactions with private keys
- **Contract ABIs** - Understanding function signatures and types
- **Solidity fundamentals** - String comparison using keccak256 hashing

## Tools Used
- Python `web3.py` library
- Web browser for PoW and instance management
- Solidity for contract analysis
