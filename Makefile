-include .env

build:; forge build

deploy-sepolia:

	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --broadcast --account $(ACCOUNT_NAME) --sender $(SENDER) --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
