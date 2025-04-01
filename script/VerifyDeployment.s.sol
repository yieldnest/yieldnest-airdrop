// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Airdrop, IAirdrop, UserAmount } from "../src/Airdrop.sol";

import { BaseScript } from "./BaseScript.s.sol";

import { ProxyAdmin } from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from
    "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Address } from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

import { ProxyUtils } from "./ProxyUtils.sol";

// source .env && forge script script/VerifyDeployment.s.sol:VerifyAirdrop -s "run(string)" script/inputs/season-one-eigen-holesky.json --rpc-url $HOLESKY_RPC_URL --sender $DEPLOYER_ADDRESS --account $DEPLOYER_ACCOUNT_NAME
contract VerifyAirdrop is BaseScript {
    Airdrop public airdrop;
    Airdrop public airdropImpl;
    ProxyAdmin public proxyAdmin;
    Deployment public deployment;

    struct Deployment {
        address airdropProxy;
        address airdropImplementation;
        address proxyAdmin;
        address owner;
        address proxyAdminOwner;
        address rewardsSafe;
        address token;
        uint256 totalAmount;
        uint256 initialSafeBalance;
    }

    error InvalidDeployment();

    function run(string memory _path) public {
        _loadInput(_path);
        deployment = _loadDeployment();

        _verify();
    }

    function _verify() internal {
        console.log("Airdrop Proxy:", deployment.airdropProxy);
        console.log("Airdrop Implementation:", deployment.airdropImplementation);
        console.log("Proxy Admin:", deployment.proxyAdmin);
        console.log("Owner:", deployment.owner);
        console.log("Proxy Admin Owner:", deployment.proxyAdminOwner);
        console.log("Rewards Safe:", deployment.rewardsSafe);
        console.log(" Token:", deployment.token);
        console.log("Total Amount:", deployment.totalAmount);
        console.log("Initial Safe Balance:", deployment.initialSafeBalance);

        // Initialize Airdrop instance
        airdrop = Airdrop(deployment.airdropProxy);
        if (airdrop.paused()) {
            revert("Airdrop is paused when it should not be");
        }
        console.log("\u2705 Airdrop is not paused");

        _verifyViewFunctions();

        _verifyProxyAdmin();

        _verifyTotalAmount();

        console.log("Deployment verified successfully");
    }

    function _verifyProxyAdmin() internal {
        // Verify ProxyAdmin owner
        address proxyAdminAddress = ProxyUtils.getProxyAdmin(deployment.airdropProxy);
        proxyAdmin = ProxyAdmin(proxyAdminAddress);

        if (proxyAdmin.owner() != deployment.proxyAdminOwner) {
            console.log("Expected ProxyAdmin owner:", deployment.proxyAdminOwner);
            console.log("Actual ProxyAdmin owner:", proxyAdmin.owner());
            revert InvalidDeployment();
        }

        console.log("\u2705 ProxyAdmin owner verified successfully: ", proxyAdmin.owner());
    }

    function _verifyViewFunctions() internal view {
        // Verify view functions
        if (airdrop.owner() != data.airdropOwner) {
            revert("Airdrop owner verification failed");
        }
        console.log("\u2705 Airdrop owner verified successfully: ", airdrop.owner());

        if (airdrop.safe() != rewardsSafe) {
            revert("Airdrop safe address verification failed");
        }
        console.log("\u2705 Airdrop safe address verified successfully: ", airdrop.safe());

        if (address(airdrop.token()) != token) {
            revert("Airdrop token address verification failed");
        }
        console.log("\u2705 Airdrop token address verified successfully: ", address(airdrop.token()));
    }

    function _verifyTotalAmount() internal view {
        // Verify user amounts
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < userAmounts.length; i++) {
            UserAmount memory userAmount = userAmounts[i];
            uint256 onChainAmount = airdrop.amounts(userAmount.user);
            if (onChainAmount != userAmount.amount) {
                console.log("Mismatch for user: ", userAmount.user);
                console.log("Expected amount: ", userAmount.amount);
                console.log("On-chain amount: ", onChainAmount);
                revert InvalidDeployment();
            }
            totalTokens += onChainAmount;
        }

        if (totalTokens != deployment.totalAmount) {
            console.log("Total tokens mismatch");
            console.log("Expected total tokens: ", deployment.totalAmount);
            console.log("Actual total tokens: ", totalTokens);
            revert InvalidDeployment();
        }
        console.log("\u2705 Total tokens verified successfully");
        console.log("Total tokens: ", totalTokens);
    }

    function _loadDeployment() internal view returns (Deployment memory) {
        string memory json = vm.readFile(_getDeploymentFile());

        address airdropProxy = abi.decode(vm.parseJson(json, ".airdropProxy"), (address));

        address airdropImplementation = abi.decode(vm.parseJson(json, ".airdropImplementation"), (address));
        address proxyAdminAddress = abi.decode(vm.parseJson(json, ".proxyAdmin"), (address));
        address owner = abi.decode(vm.parseJson(json, ".owner"), (address));
        address proxyAdminOwner = abi.decode(vm.parseJson(json, ".proxyAdmin"), (address));
        address rewardsSafe = abi.decode(vm.parseJson(json, ".rewardsSafe"), (address));
        address tokenAddress = abi.decode(vm.parseJson(json, ".token"), (address));
        uint256 totalAmount = abi.decode(vm.parseJson(json, ".totalAmount"), (uint256));
        uint256 initialSafeBalance = abi.decode(vm.parseJson(json, ".initialSafeBalance"), (uint256));

        console.log("Loaded deployment from:", _getDeploymentFile());

        return Deployment({
            airdropProxy: airdropProxy,
            airdropImplementation: airdropImplementation,
            proxyAdmin: proxyAdminAddress,
            owner: owner,
            proxyAdminOwner: proxyAdminOwner,
            rewardsSafe: rewardsSafe,
            token: tokenAddress,
            totalAmount: totalAmount,
            initialSafeBalance: initialSafeBalance
        });
    }
}
