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

    /**
     * @notice Cancels order.
     * @dev Order is cancelled by setting remaining amount to _ORDER_FILLED value
     * @param order Order quote to cancel
     * @return orderRemaining Unfilled amount of order before cancellation
     * @return orderHash Hash of the filled order
     */
    function cancelOrder(OrderLib.Order calldata order) external returns (uint256 orderRemaining, bytes32 orderHash) {
        IOrderMixin(ORDER_MIXIN_ADDRESS).cancelOrder(order);
        emit OrderCanceled(order, orderRemaining, orderHash);
        return (orderRemaining, orderHash);
    }

    /**
     * @notice Fills an order. If one doesn't exist (first fill) it will be created using order.makerAssetData
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param interaction A call data for InteractiveNotificationReceiver. Taker may execute interaction after getting maker assets and before sending taker assets.
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param skipPermitAndThresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount. Top-most bit specifies whether taker wants to skip maker's permit.
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrder(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount
    ) external payable returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash) {
        IOrderMixin(ORDER_MIXIN_ADDRESS).fillOrder(
            order, signature, interaction, makingAmount, takingAmount, skipPermitAndThresholdAmount
        );
        emit FillOder(order, orderHash, actualMakingAmount, actualTakingAmount);
        return (actualMakingAmount, actualTakingAmount, orderHash);
    }

    /**
     * @notice Same as `fillOrderTo` but calls permit first,
     * allowing to approve token spending and make a swap in one transaction.
     * Also allows to specify funds destination instead of `msg.sender`
     * @dev See tests for examples
     * @param order Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param interaction A call data for InteractiveNotificationReceiver. Taker may execute interaction after getting maker assets and before sending taker assets.
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param skipPermitAndThresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount. Top-most bit specifies whether taker wants to skip maker's permit.
     * @param target Address that will receive swap funds
     * @param permit Should consist of abiencoded token address and encoded `IERC20Permit.permit` call.
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderToWithPermit(
        OrderLib.Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target,
        bytes calldata permit
    ) external returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash) {
        IOrderMixin(ORDER_MIXIN_ADDRESS).fillOrderToWithPermit(
            order, signature, interaction, makingAmount, takingAmount, skipPermitAndThresholdAmount, target, permit
        );
        emit FillOderToWithPermit(order, orderHash, actualMakingAmount, actualTakingAmount);

        return (actualMakingAmount, actualTakingAmount, orderHash);
    }

    /**
     * @notice Same as `fillOrder` but allows to specify funds destination instead of `msg.sender`
     * @param order_ Order quote to fill
     * @param signature Signature to confirm quote ownership
     * @param interaction A call data for InteractiveNotificationReceiver. Taker may execute interaction after getting maker assets and before sending taker assets.
     * @param makingAmount Making amount
     * @param takingAmount Taking amount
     * @param skipPermitAndThresholdAmount Specifies maximum allowed takingAmount when takingAmount is zero, otherwise specifies minimum allowed makingAmount. Top-most bit specifies whether taker wants to skip maker's permit.
     * @param target Address that will receive swap funds
     * @return actualMakingAmount Actual amount transferred from maker to taker
     * @return actualTakingAmount Actual amount transferred from taker to maker
     * @return orderHash Hash of the filled order
     */
    function fillOrderTo(
        OrderLib.Order calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target
    ) external payable returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash) {
        IOrderMixin(ORDER_MIXIN_ADDRESS).fillOrderTo(
            order_, signature, interaction, makingAmount, takingAmount, skipPermitAndThresholdAmount, target
        );
        emit FillOderTo(order_, orderHash, actualMakingAmount, actualTakingAmount);

        return (actualMakingAmount, actualTakingAmount, orderHash);
    }

    /**
     * @notice stimulates if an address ca transfer from
     */
    function simulate(address target, bytes calldata data) external {
        IOrderMixin(ORDER_MIXIN_ADDRESS).simulate(target, data);
    }

    /**
     * @notice Checks order predicate
     * @return results Predicate evaluation result. True if predicate allows to fill the order, false otherwise
     */
    function checkPredicate(OrderLib.Order calldata order) public returns (bool results) {
        results = IOrderMixin(ORDER_MIXIN_ADDRESS).checkPredicate(order);
        emit OrderPredicateCheck(order, results);
        return results;
    }

    /**
     * @notice returns unfilled amount for order
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
