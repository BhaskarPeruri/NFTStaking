.PHONY: install
install :; forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit && forge install OpenZeppelin/openzeppelin-foundry-upgrades --no-commit  &&  forge install foundry-rs/forge-std --no-commit
