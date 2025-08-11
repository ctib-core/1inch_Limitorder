// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OApp, Origin, MessagingFee } from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import { OAppOptionsType3 } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {SetterContract} from "./setterContract.sol";


import {IOrderMixin} from "@1inch/limit-order-protocol/interfaces/IOrderMixin.sol";
import {OrderEvents} from "./Events.sol";
import {OrderLib} from "@1inch/limit-order-protocol/OrderLib.sol";
import {MakerTraitsLib, MakerTraits} from "@1inch/limit-order-protocol/libraries/MakerTraitsLib.sol";
import {TakerTraitsLib, TakerTraits} from "@1inch/limit-order-protocol/libraries/TakerTraitsLib.sol";
contract Cross_Chain_Interaction is SetterContract, OApp, OAppOptionsType3 {
    /// @notice Last string received from any remote chain
    string public lastMessage;

    /// @notice Msg type for sending a string, for use in OAppOptionsType3 as an enforced option
    uint16 public constant SEND = 1;
    uint16 public constant FILL_ORDER = 5;
    uint16 public constant FILL_ORDER_ARGS = 6;
    uint16 public constant FILL_CONTRACT_ORDER = 7;
    uint16 public constant CANCEL_ORDERS = 8;


/// @notice Struct for state response messages
 struct StateResponse {
    bytes32 requestId;
    bool success;
    uint256 resultAmount;
    string errorMessage;
    uint32 dstEid;
    uint256 timestamp;
}



    //////eerrros

   error  Strategy__RequestAlreadyProcessed(bytes32 _requestId);
   

   
    /// @notice Mapping to track processed requests to prevent replay attacks
    mapping(bytes32 => bool) public processedRequests;

    /// @notice Initialize with Endpoint V2 and owner address
    /// @param _endpoint The local chain's LayerZero Endpoint V2 address
    /// @param _owner    The address permitted to configure this OApp
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}



function _lzReceive(
    Origin calldata _origin,
    bytes32 _guid,
    bytes calldata _message,
    address /*_executor*/,
    bytes calldata /*_extraData*/
) internal override {
    (uint16 msgType, bytes memory data) = abi.decode(_message, (uint16, bytes));

    StateResponse memory response;

    if (msgType == SEND) {
        string memory _string = abi.decode(data, (string));
        lastMessage = _string;
        return;
    } else if (msgType == FILL_ORDER) {
        response = _handlerFillOrderRequest(_origin, data);
    } else if (msgType == FILL_ORDER_ARGS) {
        response = _handlerFillOrderArgsRequest(_origin, data);
    } else if (msgType == FILL_CONTRACT_ORDER) {
        response = _handlerFillContractOrderRequest(_origin, data);
    } else if (msgType == CANCEL_ORDERS) {
        response = _handlerCancelOrdersRequest(_origin, data);
    } else {
        revert Strategy__UnknownMessageType(msgType);
    }

    // after handler executed, send state response (encoded)
    _handleStateResponse(abi.encode(response));
}




    /////////////handlers//////////////////////////////////////
    //////////////////////////////////////////////////////////


     function _handleStateResponse(bytes memory _data) internal {
    StateResponse memory response = abi.decode(_data, (StateResponse));
    bytes memory message = abi.encode(response);
    _internalSendStateResponse(response.dstEid, message, "", 50000);
    emit StateResponseReceived(
        response.requestId,
        response.success,
        response.resultAmount,
        response.errorMessage
    );
}


function _handlerFillOrderRequest(Origin calldata _origin, bytes memory _data) internal {
    (
        IOrderMixin.Order memory order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits memory takerTraits
    ) = abi.decode(_data, (IOrderMixin.Order, bytes32, bytes32, uint256, TakerTraits));

    if (processedRequests[order.info]) {
        revert Strategy__RequestAlreadyProcessed(order.info);
    }
    processedRequests[order.info] = true;

    (
        bool success,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 actualAmountIn,
        string memory errorMessage
    ) = _executeFillOrder(order, r, vs, amount, takerTraits);

    emit CrossChainFillOrder(order.info, order.maker, makingAmount, takingAmount);

    bytes memory message = abi.encode(success, makingAmount, takingAmount, actualAmountIn, errorMessage);
    _internalSendStateResponse(_origin.srcEid, message, "", 500000);
}

function _handlerFillOrderArgsRequest(Origin calldata _origin, bytes memory _data) internal {
    (
        IOrderMixin.Order memory order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits memory takerTraits,
        bytes memory args
    ) = abi.decode(_data, (IOrderMixin.Order, bytes32, bytes32, uint256, TakerTraits, bytes));

    if (processedRequests[order.info]) {
        revert Strategy__RequestAlreadyProcessed(order.info);
    }
    processedRequests[order.info] = true;

    (
        bool success,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 actualAmountIn,
        string memory errorMessage
    ) = _executeFillOrderArgs(order, r, vs, amount, takerTraits, args);

    emit CrossChainFillOrderArgs(order.info, order.maker, makingAmount, takingAmount);

    bytes memory message = abi.encode(success, makingAmount, takingAmount, actualAmountIn, errorMessage);
    _internalSendStateResponse(_origin.srcEid, message, "", 500000);
}

function _handlerFillContractOrderRequest(Origin calldata _origin, bytes memory _data) internal {
    (
        IOrderMixin.Order memory order,
        bytes memory signature,
        uint256 amount,
        TakerTraits memory takerTraits
    ) = abi.decode(_data, (IOrderMixin.Order, bytes, uint256, TakerTraits));

    if (processedRequests[order.info]) {
        revert Strategy__RequestAlreadyProcessed(order.info);
    }
    processedRequests[order.info] = true;

    (
        bool success,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 actualAmountIn,
        string memory errorMessage
    ) = _executeFillContractOrder(order, signature, amount, takerTraits);

    emit CrossChainFillContractOrder(order.info, order.maker, makingAmount, takingAmount);

    bytes memory message = abi.encode(success, makingAmount, takingAmount, actualAmountIn, errorMessage);
    _internalSendStateResponse(_origin.srcEid, message, "", 500000);
}

function _handlerCancelOrdersRequest(Origin calldata _origin, bytes memory _data) internal {
    (
        MakerTraits[] memory makerTraits,
        bytes32[] memory orderHashes
    ) = abi.decode(_data, (MakerTraits[], bytes32[]));

    bytes32 requestId = keccak256(abi.encode(makerTraits, orderHashes));
    if (processedRequests[requestId]) {
        revert Strategy__RequestAlreadyProcessed(requestId);
    }
    processedRequests[requestId] = true;

    (bool success, string memory errorMessage) = _executeCancelOrders(makerTraits, orderHashes);

    for (uint i = 0; i < orderHashes.length; i++) {
        emit CrossChainCancelOrder(makerTraits[i], orderHashes[i]);
    }

    bytes memory message = abi.encode(success, errorMessage);
    _internalSendStateResponse(_origin.srcEid, message, "", 500000);
}

    


///////////////////////////////////////////////////////////////////////
///////internallll execute functions///////////////////////////////////
//////////////////////////////////////////////////////////////////////
    function _executeFillOrder(
        IOrderMixin.Order memory order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits

    ) internal returns (
        bool success,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 actualAmountIn,
        string memory errorMessage
    ) {
        try this.fillOrder(order, r, vs, amount, takerTraits ) {
            success = true;
            makingAmount = order.makingAmount;
            takingAmount = order.takingAmount;
            actualAmountIn = amount;
            errorMessage = "";
        } catch Error(string memory reason) {
            success = false;
            makingAmount = 0;
            takingAmount = 0;
            actualAmountIn = amount;
            errorMessage = reason;
        } catch {
            success = false;
            makingAmount = 0;
            takingAmount = 0;
            actualAmountIn = amount;
            errorMessage = "Low-level call failed";
        }
    }

    function _executeFillOrderArgs(
        IOrderMixin.Order memory order,
        bytes32 r,
        bytes32 vs,
        uint256 amount,
        TakerTraits takerTraits,
        bytes calldata args
    ) internal returns (
        bool success,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 actualAmountIn,
        string memory errorMessage
    ) {
        try this.fillOrderArgs(order, r, vs, amount, takerTraits, args) returns (uint256 _makingAmount, uint256 _takingAmount, bytes32) {
            success = true;
            makingAmount = _makingAmount;
            takingAmount = _takingAmount;
            actualAmountIn = amount;
            errorMessage = "";
        } catch Error(string memory reason) {
            success = false;
            makingAmount = 0;
            takingAmount = 0;
            actualAmountIn = amount;
            errorMessage = reason;
        } catch {
            success = false;
            makingAmount = 0;
            takingAmount = 0;
            actualAmountIn = amount;
            errorMessage = "Low-level call failed";
        }
    }

    function _executeFillContractOrder(
        IOrderMixin.Order memory order,
        bytes calldata signature,
        uint256 amount,
        TakerTraits takerTraits

    ) internal returns (
        bool success,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 actualAmountIn,
        string memory errorMessage
    ) {
        try this.fillContractOrder(order, signature, amount, takerTraits) returns (uint256 _makingAmount, uint256 _takingAmount, bytes32) {
            success = true;
            makingAmount = _makingAmount;
            takingAmount = _takingAmount;
            actualAmountIn = amount;
            errorMessage = "";
        } catch Error(string memory reason) {
            success = false;
            makingAmount = 0;
            takingAmount = 0;
            actualAmountIn = amount;
            errorMessage = reason;
        } catch {
            success = false;
            makingAmount = 0;
            takingAmount = 0;
            actualAmountIn = amount;
            errorMessage = "Low-level call failed";
        }
    }

    function _executeCancelOrders(
        MakerTraits[] calldata makerTraits,
        bytes32[] calldata orderHashes
    ) internal returns (bool success, string memory errorMessage) {
        try this.cancelOrders(makerTraits, orderHashes) {
            success = true;
            errorMessage = "";
        } catch Error(string memory reason) {
            success = false;
            errorMessage = reason;
        } catch {
            success = false;
            errorMessage = "Low-level call failed";
        }
    }

    /////////////////////////////////////////////////
    //////////internal response//////////////////////
    ////////////////////////////////////////////////

        function _internalSendStateResponse(
        uint32 dstEid,
        bytes memory message,
        bytes memory options,
        uint256 gasAmount
    ) external payable {
        // Only allow self-calls for security
        if (msg.sender != address(this)) revert Strategy__OnlyOwner();
        
        // Limit gas usage to prevent draining contract balance
        uint256 maxGasForResponse = gasAmount / 2; // Use at most half of available balance
        
        _lzSend(
            dstEid,
            message,
            options,
            MessagingFee(maxGasForResponse, 0), // Use limited amount for gas
            payable(address(this)) // Refund excess to contract
        );
    }

    
    /// @notice Withdraw native tokens from contract (admin only)
    /// @param to Recipient address
    /// @param amount Amount to withdraw
    function withdrawNative(address payable to, uint256 amount) external onlyOwnerWithPermission(bytes4(keccak256("withdrawNative(address,uint256)"))) {
        if (to == address(0)) revert Strategy__InvalidRecipient();
        if (amount > address(this).balance) revert Strategy__InsufficientBalance();
        to.transfer(amount);
    }



    /// @notice Storage for minimum gas balance requirement
    uint256 public minimumGasBalance = 0.01 ether; // Default minimum balance


    
    /// @notice Allow contract to receive native tokens for gas fees
    receive() external payable {}

}
