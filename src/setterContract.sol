// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IOrderMixin} from "@1inch/limit-order-protocol/interfaces/IOrderMixin.sol";
import {OrderEvents} from "./Events.sol";
import {OrderLib} from "@1inch/limit-order-protocol/OrderLib.sol";
import {MakerTraitsLib, MakerTraits} from "@1inch/limit-order-protocol/libraries/MakerTraitsLib.sol";
import {TakerTraitsLib, TakerTraits} from "@1inch/limit-order-protocol/libraries/TakerTraitsLib.sol";

import {IPermissionManager} from "./interface/IpermisionManager.sol";
import {PermissionModifiers} from "./permissionModifer.sol";

abstract contract SetterContract is OrderEvents {
    using PermissionModifiers for *;

    //// address ///////////
    address public ORDER_MIXIN_ADDRESS =  0x119c71D3BbAC22029622cbaEc24854d3D32D2828 ;
    address public CREATE3_DEPLOYER_ADDRESS;
    address public AMOUNT_GETTER_ADDRESS;
    address public PERMSSION_ADDRESS  =0xc9F6a492Fb1D623690Dc065BBcEd6DfB4a324A35 ;

    constructor() {}

    /**
     * @notice Fills order's quote, fully or partially (whichever is possible).
     */
    function fillOrder(
        IOrderMixin.Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits
    )
        external
        payable
        returns (uint256 makingAmount, uint256 takingAmount, bytes32 orderHash)
    {
        (makingAmount, takingAmount, orderHash) = IOrderMixin(
            ORDER_MIXIN_ADDRESS
        ).fillOrder(order, r, vs, amount, takerTraits);

        emit FillOrder(order, amount, takerTraits);
        return (makingAmount, takingAmount, orderHash);
    }

    /**
     * @notice Same as `fillOrder` but allows to specify arguments used by the taker.
     */
    function fillOrderArgs(
        IOrderMixin.Order calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    )
        external
        payable
        returns (uint256 makingAmount, uint256 takingAmount, bytes32 orderHash)
    {
        (makingAmount, takingAmount, orderHash) = IOrderMixin(
            ORDER_MIXIN_ADDRESS
        ).fillOrderArgs(order, r, vs, amount, takerTraits, args);

        emit FillOrderArgs(order, amount, takerTraits, args);
        return (makingAmount, takingAmount, orderHash);
    }

    /**
     * @notice Same as `fillOrder` but uses contract-based signatures.
     */
    function fillContractOrder(
        IOrderMixin.Order calldata order,
        bytes calldata signature,
        uint256 amount,
        TakerTraits takerTraits
    )
        external
        returns (uint256 makingAmount, uint256 takingAmount, bytes32 orderHash)
    {
        (makingAmount, takingAmount, orderHash) = IOrderMixin(
            ORDER_MIXIN_ADDRESS
        ).fillContractOrder(order, signature, amount, takerTraits);

        emit FillContractOrder(
            order,
            amount,
            takerTraits,
            orderHash,
            makingAmount,
            takingAmount
        );
        return (makingAmount, takingAmount, orderHash);
    }

    /**
     * @notice Cancels orders' quotes
     */
    function cancelOrders(
        MakerTraits[] calldata makerTraits,
        bytes32[] calldata orderHashes
    ) external {
        uint256 hashLen = orderHashes.length;
        uint256 makelen = makerTraits.length;
        require(
            makelen == hashLen,
            "SetterContract__length should be the same"
        );

        IOrderMixin(ORDER_MIXIN_ADDRESS).cancelOrders(makerTraits, orderHashes);

        // Emit event per order cancelled
        for (uint256 i = 0; i < hashLen; i++) {
            emit OrderCancelled(makerTraits[i], orderHashes[i]);
        }
    }

    /**
     * @notice Simulates if an address can transfer from
     */
    function simulate(address target, bytes calldata data) external {
        IOrderMixin(ORDER_MIXIN_ADDRESS).simulate(target, data);
    }

    /**
     * @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
     */
    function remainingInvalidatorForOrder(
        address maker,
        bytes32 orderHash
    ) external returns (uint256 remaining) {
        remaining = IOrderMixin(ORDER_MIXIN_ADDRESS)
            .remainingInvalidatorForOrder(maker, orderHash);
        emit RemainingRawForOrder(orderHash, remaining, maker);
    }

    /**
     * @notice Returns bitmask for double-spend invalidators based on lowest byte of order.info and filled quotes
     */
    function rawRemainingInvalidatorForOrder(
        address maker,
        bytes32 orderHash
    ) external returns (uint256 remainingRaw) {
        remainingRaw = IOrderMixin(ORDER_MIXIN_ADDRESS)
            .rawRemainingInvalidatorForOrder(maker, orderHash);
        emit RawRemainingInvalidatorForOrder(maker, orderHash, remainingRaw);
        return remainingRaw;
    }

    /**
     * @notice Hash order
     */
    function hashOrder(
        IOrderMixin.Order calldata order
    ) public view returns (bytes32 _orderHash) {
        _orderHash = IOrderMixin(ORDER_MIXIN_ADDRESS).hashOrder(order);
    }

    /**
     * @notice Function to set contract address
     * @notice only permission address
     */
    function setContractAddress(
        address _orderMixin,
        address _permission
    ) public {
        ORDER_MIXIN_ADDRESS = _orderMixin;
        PERMSSION_ADDRESS = _permission;
    }
    //     emit OrderMixinAddressSet(_orderMixin);
    // }
}
