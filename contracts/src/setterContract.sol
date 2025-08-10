//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import{IAmountGetter } from "@limit-order-protocol/contracts/interfaces/IAmountGetter.sol";
import{ICreate3Deployer} from "./interface/ICreate3Deployer.sol";
import{IOrderMixin} from "./interface/IOrderMixin.sol";
import{IOrderRegistrator} from "./interface/IorderRegistrator.sol";
import{IPermissionManager} from "./interface/IpermisionManager.sol";
import{PermissionModifiers} from "./permissionModifer.sol";


abstract contract SetterContract {

 using PermissionModifiers for *;


//// address ///////////
address public ORDER_MIXIN_ADDRESS;
address public CREATE3_DEPLOYER_ADDRESS;
address public AMOUNT_GETTER_ADDRESS;
address public ORDER_REGISTRATOR_ADDRESS;


    constructor(){

    }









    /**@notice function to set contract addresss
      *@notice only permision address 
     */

     function setContractAddress(address _orderMixin, address create3deployer,address _amountgetter, address _orderRegistrator) public {
        ORDER_MIXIN_ADDRESS = _orderMixin;
        CREATE3_DEPLOYER_ADDRESS = create3deployer;
        AMOUNT_GETTER_ADDRESS = _amountgetter;
        ORDER_REGISTRATOR_ADDRESS = _orderRegistrator;

     }
    

}