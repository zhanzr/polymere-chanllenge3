//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";

contract Answer is UniversalChanIbcApp {
    // application specific state
    uint64 public counter;
    address constant public TEST_DEST = 0x528f7971cE3FF4198c3e6314AA223C83C7755bf7;

    event LogAcknowledgement(
        string message
    );

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

    // application specific logic

    // IBC logic

    /**
     * @dev Sends a packet with the caller's address over the universal channel.
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */
    function sendUniversalPacket(address destPortAddr, bytes32 channelId, uint64 timeoutSeconds) external {
        string memory queryStr = "crossChainQuery";
        bytes memory payload = abi.encode(msg.sender, queryStr);

        uint64 timeoutTimestamp = uint64((block.timestamp + timeoutSeconds) * 1000000000);

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket)
    {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address payload, uint64 c) = abi.decode(packet.appData, (address, uint64));

        return AckPacket(true, abi.encode(counter));
    }
   
    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     * 
     * Is this function named ' onAcknowledgementUniversalPacket '?
     */
    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
        {
            ackPackets.push(UcAckWithChannel(channelId, packet, ack));

            // decode the counter from the ack packet
            (string memory ackString) = abi.decode(ack.data, (string)); 

            emit LogAcknowledgement(ackString);
        }

    /*
    function onAcknowledgementUniversalPacket(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
        {
            ackPackets.push(UcAckWithChannel(channelId, packet, ack));

            // decode the counter from the ack packet
            (address _caller, string memory ackString) = abi.decode(ack.data, (address, string)); 

            emit LogAcknowledgement(ackString);
        }
    */

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
