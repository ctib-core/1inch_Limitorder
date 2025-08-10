//SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {OrderLib} from "@1inch/limit-order-protocol/OrderLib.sol";

contract OrderEvents {
    event OrderMixinAddressSet(address mixinAddress);
    event RemainingRawForOrder(bytes32 _orderhash, uint256 _amountraw);
    event OrderPredicateCheck(OrderLib.Order order, bool _result);
    event FillOderToWithPermit(
        OrderLib.Order order, bytes32 orderHash, uint256 actualMakingAmountm, uint256 actualTakingAmount
    );
    event FillOderTo(OrderLib.Order order, bytes32 orderHash, uint256 actualMakingAmountm, uint256 actualTakingAmount);
    event FillOder(OrderLib.Order order, bytes32 orderHash, uint256 actualMakingAmountm, uint256 actualTakingAmount);
    event OrderCanceled(OrderLib.Order, uint256 orderRemaining, bytes32 orderHash);
}
