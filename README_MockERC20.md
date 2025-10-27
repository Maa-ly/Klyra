# MockERC20 Token

A simple mock ERC20 token for testing your Klyra contract.

## Features

- ✅ **Mint function** - Create tokens for testing
- ✅ **Approve function** - Standard ERC20 approval
- ✅ **Burn function** - Destroy tokens
- ✅ **Owner controls** - Only owner can mint to others
- ✅ **Public mint** - Anyone can mint to themselves

## Usage

### Deploy Token
```bash
forge script script/DeployMockERC20.s.sol --rpc-url sepolia --broadcast
```

### Test Token
```bash
forge test --match-contract MockERC20Test -vv
```

## Functions

### `mint(address to, uint256 amount)`
- **Owner only** - Mint tokens to any address
- **Usage**: `token.mint(userAddress, 1000 * 10**18)`

### `mint(uint256 amount)`
- **Public** - Mint tokens to caller
- **Usage**: `token.mint(1000 * 10**18)`

### `approve(address spender, uint256 amount)`
- **Standard ERC20** - Approve spender to spend tokens
- **Usage**: `token.approve(klyraAddress, 1000 * 10**18)`

### `burn(uint256 amount)`
- **Public** - Burn caller's tokens
- **Usage**: `token.burn(100 * 10**18)`

## Example Usage with Klyra

```javascript
// 1. Deploy mock token
const token = await MockERC20.deploy("Test Token", "TEST", 18, 0);

// 2. Mint tokens to user
await token.mint(userAddress, ethers.utils.parseEther("1000"));

// 3. User approves Klyra contract
await token.connect(user).approve(klyraAddress, ethers.utils.parseEther("100"));

// 4. User sends tokens through Klyra
await klyra.sendDirectToken(tokenAddress, receiverAddress, ethers.utils.parseEther("100"));
```

## Test Tokens

The deployment script creates 3 test tokens:
- **Mock USDC** (6 decimals) - 1M tokens
- **Mock DAI** (18 decimals) - 1M tokens  
- **Mock WETH** (18 decimals) - 1000 tokens

