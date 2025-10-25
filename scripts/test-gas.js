const { ethers } = require("hardhat");

async function main() {
  // Get the contract
  const contractAddress = "0xbb75A3ae597c0025a405ecAD104bB78c7C265bF0";
  const SimpleTransfer = await ethers.getContractFactory("SimpleTransfer");
  const contract = SimpleTransfer.attach(contractAddress);
  
  // Test gas estimation
  const receiver = "0x9f08eFb0767Bf180B8b8094FaaEF9DAB5a0755e1";
  const value = ethers.parseEther("0.04"); // 0.04 ETH
  const requiredOutput = ethers.parseEther("0.03"); // 0.03 ETH
  
  console.log("Estimating gas for sendETH...");
  
  try {
    const gasEstimate = await contract.sendETH.estimateGas(receiver, requiredOutput, {
      value: value
    });
    
    console.log("Gas estimate:", gasEstimate.toString());
    console.log("Gas estimate in hex:", gasEstimate.toHexString());
    
  } catch (error) {
    console.error("Gas estimation failed:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });



