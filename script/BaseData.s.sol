// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity >=0.8.25 <0.9.0;

import { Script } from "forge-std/Script.sol";

contract BaseData is Script {
    struct Data {
        address airdropOwner;
        address proxyAdminOwner;
    }

    struct ChainIds {
        uint256 mainnet;
        uint256 holesky;
        uint256 anvil;
    }

    mapping(uint256 chainId => Data data) private __data;

    ChainIds public chainIds = ChainIds({ mainnet: 1, holesky: 17_000, anvil: 31_337 });

    address private TEMP_AIRDROP_OWNER;
    address private TEMP_PROXY_CONTROLLER;

    function setUp() public virtual {
        TEMP_AIRDROP_OWNER = makeAddr("airdrop-owner");
        TEMP_PROXY_CONTROLLER = makeAddr("proxy-controller");

        address YN_DEV_MAINNET = 0xa08F39d30dc865CC11a49b6e5cBd27630D6141C3;

        __data[chainIds.mainnet] = Data({ airdropOwner: YN_DEV_MAINNET, proxyAdminOwner: YN_DEV_MAINNET });

        address YN_DEV_HOLESKY = 0x72fdBD51085bDa5eEEd3b55D1a46E2e92f0837a5;

        __data[chainIds.holesky] = Data({ airdropOwner: YN_DEV_HOLESKY, proxyAdminOwner: YN_DEV_HOLESKY });
    }

    function getData(uint256 chainId) internal view returns (Data memory) {
        return __data[chainId];
    }

    function isSupportedChainId(uint256 chainId) internal view returns (bool) {
        return chainId == chainIds.mainnet || chainId == chainIds.holesky;
    }
}
