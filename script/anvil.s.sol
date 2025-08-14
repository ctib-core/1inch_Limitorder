//SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import{ Cross_Chain_Interaction} from "../src/cross-chain_interaction.sol";


import "forge-std/Script.sol";

contract DeployContract is Script {
Cross_Chain_Interaction public cross;
address public _endpoint;
address public deployer;
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        deployer = vm.addr(deployerPrivateKey);

        vm.createSelectFork(vm.rpcUrl("anvillocal"));
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying contracts to ETH network...");
        console.log("Deployer address:", deployer);

       deploy(deployer);
       logAddress();

        vm.stopBroadcast();
    }

    function deploy(address _deployer) internal {
  cross = new Cross_Chain_Interaction(_endpoint, _deployer);
    }


    function logAddress() internal {
      console.log("CROSS CHAIN ADDRESS WAS DEPLOYED AT",  address(cross));
    }

}