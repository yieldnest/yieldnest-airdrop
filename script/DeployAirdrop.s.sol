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

import { ProxyUtils } from "script/ProxyUtils.sol";

contract DeployAirdrop is BaseScript {
    Airdrop public airdrop;
    Airdrop public airdropImpl;
    ProxyAdmin public proxyAdmin;

    error InvalidDeployment();

    function run(string memory _path) public {
        _loadInput(_path);

        _deploy();
        _verify();
        _save();
    }

    function _deploy() internal {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deployer address: ", deployer);

        airdropImpl = new Airdrop();

        console.log("Deployed Airdrop implementation at address: ", address(airdropImpl));

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(airdropImpl), data.proxyAdminOwner, "");

        console.log("Deployed Airdrop proxy at address: ", address(proxy));

        airdrop = Airdrop(address(proxy));

        airdrop.initialize(data.airdropOwner, rewardsSafe, token, userAmounts);

        console.log("Initialized Airdrop with owner: ", data.airdropOwner);

        vm.stopBroadcast();

        proxyAdmin = ProxyAdmin(ProxyUtils.getProxyAdmin(address(proxy)));
    }

    function _verify() internal view {
        if (proxyAdmin.owner() != data.proxyAdminOwner) {
            revert InvalidDeployment();
        }
        if (airdrop.owner() != data.airdropOwner) {
            revert InvalidDeployment();
        }
        if (airdrop.safe() != rewardsSafe) {
            revert InvalidDeployment();
        }
        if (address(airdrop.token()) != token) {
            revert InvalidDeployment();
        }
        if (airdrop.paused()) {
            revert InvalidDeployment();
        }
    }

    function _save() internal {
        string memory json;
        vm.serializeAddress(json, "airdropProxy", address(airdrop));
        vm.serializeAddress(json, "airdropImplementation", address(airdropImpl));
        vm.serializeAddress(json, "owner", data.airdropOwner);
        vm.serializeAddress(json, "proxyAdmin", address(proxyAdmin));
        vm.serializeAddress(json, "rewardsSafe", rewardsSafe);
        vm.serializeAddress(json, "token", token);
        vm.serializeUint(json, "totalAmount", totalAmount);
        vm.serializeUint(json, "initialSafeBalance", initialSafeBalance);
        string memory finalJson = vm.serializeAddress(json, "deployer", msg.sender);
        vm.writeJson(finalJson, _getDeploymentFile());
    }
}
