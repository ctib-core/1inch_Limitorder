// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;  // updated pragma

import {OrderLib} from "@1inch/limit-order-protocol/OrderLib.sol";
import {IOrderMixin} from "@1inch/limit-order-protocol/interfaces/IOrderMixin.sol";
import {MakerTraitsLib, MakerTraits} from "@1inch/limit-order-protocol/libraries/MakerTraitsLib.sol";
import {TakerTraitsLib, TakerTraits} from "@1inch/limit-order-protocol/libraries/TakerTraitsLib.sol";

contract OrderEvents {
    // Attach library functions to struct types
    using MakerTraitsLib for MakerTraits;
    using TakerTraitsLib for TakerTraits;

    // v4 events
    event RawRemainingInvalidatorForOrder(address maker, bytes32 orderHash, uint256 remainingRaw);
    event RemainingRawForOrder(bytes32 _orderhash, uint256 remaining, address maker);
  event  OrderMixinAddressSet(address _orderMixin);


    event FillContractOrder(
        IOrderMixin.Order order,
        uint256 amount,
        TakerTraits takerTraits,
        bytes32 orderHash,
        uint256 makingAmount,
        uint256 takingAmount
    );

    event FillOrder(IOrderMixin.Order order, uint256 amount, TakerTraits takerTraits);

    event FillOrderArgs(IOrderMixin.Order order, uint256 amount, TakerTraits takerTraits, bytes args);

    event OrderCancelled(MakerTraits makerTraits, bytes32 orderHashes);



    event CrossChainFillOrder(
    bytes32 indexed orderId,
    address indexed maker,
    uint256 makingAmount,
    uint256 takingAmount
);

event CrossChainFillOrderArgs(
    bytes32 indexed orderId,
    address indexed maker,
    uint256 makingAmount,
    uint256 takingAmount
);

event CrossChainFillContractOrder(
    bytes32 indexed orderId,
    address indexed maker,
    uint256 makingAmount,
    uint256 takingAmount
);

event CrossChainCancelOrder(
    MakerTraits makerTraits,
    bytes32 indexed orderHash
);

event CrossChainStateResponseReceived(
    bytes32 indexed requestId,
    bool success,
    uint256 resultAmount,
    string errorMessage
);


}
