
## 📦 Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/0x8Bit0/ESToken_v1.git
   cd estoken_v1
   ```

2. Install contract dependencies:
   ```bash
   cd contract
   npm install
   ```

3. Install frontend dependencies:
   ```bash
   cd ../frontend
   npm install
   ```

4. Compile smart contracts:
   ```bash
   cd ../contract
   npx hardhat compile
   ```

5. Deploy contracts (ensure you have Base Sepolia network configured):
   ```bash
   npx hardhat run scripts/deploy-core.ts --network baseSepolia
   ```

## 🚀 Usage

1. Start the frontend development server:
   ```bash
   cd frontend
   npm run dev
   ```

2. Open your browser and navigate to `http://localhost:5173`

3. Connect your Base-compatible wallet (MetaMask, etc.)

4. Complete KYC verification to access all platform features

5. Start investing in tokenized real estate properties!
