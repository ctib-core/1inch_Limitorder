//SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IOrderMixin} from "@1inch/limit-order-protocol/interfaces/IOrderMixin.sol";
import {OrderEvents} from "./Events.sol";
import {OrderLib} from "@1inch/limit-order-protocol/OrderLib.sol";
import {IPermissionManager} from "./interface/IpermisionManager.sol";
import {PermissionModifiers} from "./permissionModifer.sol";

abstract contract SetterContract is OrderEvents {
    using PermissionModifiers for *;

    //// address ///////////
    address public ORDER_MIXIN_ADDRESS;
    address public CREATE3_DEPLOYER_ADDRESS;
    address public AMOUNT_GETTER_ADDRESS;
    address public ORDER_REGISTRATOR_ADDRESS;

    constructor() {}

      function fillOrderToWithPermit(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target,
        bytes calldata permit
    ) external returns(uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash){
      IOrderMixin(ORDER_MIXIN_ADDRESS).fillOrderToWithPermit(order, signature, interaction, makingAmount, takingAmount, skipPermitAndThresholdAmount, target, permit);
      emit FillOderToWithPermit(order, orderHash, actualMakingAmount, actualTakingAmount);

      return (actualMakingAmount, actualTakingAmount , orderHash);
      
    }



/**@notice stimulates if an address ca transfer from
 */
    function simulate(address target, bytes calldata data) external {
      IOrderMixin(ORDER_MIXIN_ADDRESS).simulate(target, data);
    }

/**@notice Checks order predicate
 *@return results Predicate evaluation result. True if predicate allows to fill the order, false otherwise
 */
function checkPredicate(OrderLib.Order calldata order) public returns(bool results){
  results  =  IOrderMixin(ORDER_MIXIN_ADDRESS).checkPredicate(order);
  emit OrderPredicateCheck(order, results);
  return results;
}
 
/**@notice returns unfilled amount for order
 */
    function remainingRaw(bytes32 orderHash) public returns (uint256 _amountraw) {
        _amountraw = IOrderMixin(ORDER_MIXIN_ADDRESS).remainingRaw(orderHash);
        emit RemainingRawForOrder(orderHash, _amountraw);
        return _amountraw;
    }

    /**
     * @notice hash order
     */
    function hashOrder(OrderLib.Order calldata order) public view {
        // hashes an order
        IOrderMixin(ORDER_MIXIN_ADDRESS).hashOrder(order);
    }

    /**
     * @notice function to set contract addresss
     * @notice only permision address
     */
    function setContractAddress(address _orderMixin) public {
        ORDER_MIXIN_ADDRESS = _orderMixin;

        emit OrderMixinAddressSet(_orderMixin);
    }
}
