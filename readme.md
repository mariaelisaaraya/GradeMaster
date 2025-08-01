# 🛠️ GradeMaster_v3 Challenge Solution (Reentrancy Attack)

## 📝 Challenge Description  
The **Grader5** contract on Sepolia network contains a vulnerability that allows reentrancy attacks. The contract requires a counter to be greater than 1 before accepting grade submissions via the `gradeMe()` function.

### Key Components:
- Target Contract: [`0x5733...e16`](https://sepolia.etherscan.io/address/0x5733eE985e22eFF46F595376d79e31413b1A1e16)
- Vulnerability: Unsafe external call in `retrieve()` function
- Objective: Manipulate the counter to submit a grade

## 🚀 Attack Strategy
### Reentrancy Exploit Flow:
1. **Initial Deposit**  
   Send ETH to trigger the vulnerable `retrieve()` function

2. **Callback Execution**  
   The contract's refund activates our attacker's `receive()` function

3. **Nested Attack**  
   Re-enter `retrieve()` before initial call completes

4. **Counter Manipulation**  
   Successive calls increment counter from 0 → 2 in one transaction

5. **Final Submission**  
   Call `gradeMe()` with your name ("Elisa Araya")

## 🧰 Step-by-Step Solution
### Requirements:
- Remix IDE
- MetaMask (Sepolia Testnet)
- Sepolia ETH (faucet funds)

### Execution Steps:
1. **Contract Deployment**
   - Deploy attacker contract targeting Grader5 address
   - Set initial ETH value (10 Wei recommended)

2. **Attack Trigger**
   - Call `solveChallenge()` with your name parameter
   - Confirm transaction in MetaMask

3. **Verification**
   - Wait for transaction confirmation
   - Check contract state changes

## ✅ Post-Attack Verification
1. **Etherscan Check**  
   Verify your transaction on:  
   [Grader5 Contract](https://sepolia.etherscan.io/address/0x5733eE985e22eFF46F595376d79e31413b1A1e16)

2. **Counter Validation**  
   - Navigate to "Read Contract" section  
   - Query your attacker address in the counter mapping  
   - Should return value ≥ 2

3. **Grade Confirmation**  
   Check contract events for successful grade submission

## ⚠️ Important Notes
- Works only on Sepolia testnet
- Requires precise timing of reentrancy calls
- Test with small ETH amounts first
- Educational purposes only

---

🎉 **Success Criteria:**  
Your name should appear in the contract's grade registry with counter = 2