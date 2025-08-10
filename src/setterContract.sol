//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IOrderMixin } from "@1inch/limit-order-protocol/interfaces/IOrderMixin.sol";
import{OrderEvents} from "./Events.sol";
import{IPermissionManager} from "./interface/IpermisionManager.sol";
import{PermissionModifiers} from "./permissionModifer.sol";


abstract contract SetterContract is  OrderEvents {

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

     function setContractAddress(address _orderMixin) public {
        ORDER_MIXIN_ADDRESS = _orderMixin;
       
        
        emit OrderMixinAddressSet(_orderMixin);

     }
    

}