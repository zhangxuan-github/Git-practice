classdef  hNRPacketDistribution < handle
    %hNRPacketDistribution Distributes the packets among the nodes
    % This class implements the functionality to distribute the packets
    % among the nodes. It mimics the distributed nature of channel for
    % packet receptions. It also provides out-of-band packet exchange
    % between MAC layer of sender and receiver.
    % 这个类实现了在节点之间分发数据包的功能。它模拟了用于包接收的通道的分布式特性。它还提供了发送端和接收端MAC层之间的带外包交换。

    %   Copyright 2020-2021 The MathWorks, Inc.

    properties
        %ReceiverInfo Information about the receivers
        % It is a vector of length 'N', where 'N' is the number of
        % receivers registered. Each element is a structure with three fields
        %   CarrierFreq    - Carrier frequency of the receiver
        %   NCellID        - Cell identifier
        %   RNTI           - Radio network temporary identifier
        %接收机信息（ReceiverInfo） 关于接收机的信息它是一个长度为'N'的向量，其中'N'是注册的
        %注册的接收者。每个元素是一个结构，有三个字
        % CarrierFreq - 接收器的载波频率
        % NCellID - 小区标识符
        % RNTI - 无线电网络临时标识符
        ReceiverInfo

        %ReceiverPhyFcn Phy reception function handles of the receivers
        % It is a vector of length 'N', where 'N' is the number of
        % receivers registered. For each receiver, it holds the Phy
        % reception function handle for exchange of in-band information
        % exchange
        ReceiverPhyFcn

        %ReceiverMACFcn MAC reception function handles of the receivers 
        % It is a vector of length 'N', where 'N' is the number of
        % receivers registered. For each receiver, it holds the MAC
        % reception function handle for out-of-band information exchange
        ReceiverMACFcn
    end

    methods(Access = public)
        function obj = hNRPacketDistribution(simParam)
            %hNRPacketDistribution Construct an instance of this class
            %
            % SIMPARAM is a structure with following fields
            %    MaxReceivers - Maximum number of nodes that can be 
            %                   registered for reception
            
            obj.ReceiverPhyFcn = cell(simParam.MaxReceivers, 1);
            obj.ReceiverMACFcn = cell(simParam.MaxReceivers, 1);
            obj.ReceiverInfo = cell(simParam.MaxReceivers, 1);
        end

        function sendInBandPackets(obj, packetInfo)
            %sendWaveform Transmits the packet to all the receivers operating on
            % the same frequency band as transmitter
            %将信息包发送给所有在与发射机相同频段工作的接收器
            % PACKETINFO is the information about the transmitted packet.
            % Based on Phy type packetInfo has two formats.
            %
            % Format - 1 (waveform IQ samples): It is a structure with
            % following fields
            % 
            %     Waveform    - IQ samples of the waveform
            %     SampleRate  - Sample rate of the waveform
            %     CarrierFreq - Carrier frequency (in Hz)
            %     TxPower     - Tx power (in dBm)
            %     Position    - Position of the transmitting node
            %
            % Format - 2 (Unencoded packet): It is a structure with
            % following fields
            %
            %     Packet        - Column vector of octets in decimal format十进制格式的八进制列向量
            %     CarrierFreq   - Carrier frequency (in Hz)
            %     TxPower       - Tx power (in dBm)
            %     Position      - Position of the transmitting node
            %     NCellID       - Cell identifier
            %     RNTI          - Radio network temporary identifier
            
            % Send the waveform to all the receivers operating on same
            % frequency, based on carrier frequency of each receiver
            for idx = 1:length(obj.ReceiverPhyFcn)
                if ~isempty(obj.ReceiverInfo{idx})
                    if obj.ReceiverInfo{idx}.CarrierFreq == packetInfo.CarrierFreq
                        obj.ReceiverPhyFcn{idx}(packetInfo);
                    end
                end
            end
        end

        function sendOutofBandPackets(obj, packetInfo)
            %sendOutofBandPackets Transmits the packet to the
            %receiver传输包给接收机
            %
            % PACKETINFO is the information about transmitted packet.
            % It is a structure with following fields
            %   Packet        - Column vector of octets in decimal format
            %   PacketType    - Packet type
            %   NCellID       - Cell identifier
            %   RNTI          - Radio network temporary identifier

            % Send the packet to the receiver based on information in packetInfo
            for idx = 1:length(obj.ReceiverMACFcn)
                if ~isempty(obj.ReceiverInfo{idx})
                    if obj.ReceiverInfo{idx}.NCellID == packetInfo.NCellID
                        obj.ReceiverMACFcn{idx}(packetInfo);
                    end
                end
            end
        end

        function registerRxFcn(obj, receiverInfo, phyReceiverFcn, macReceiverFcn)
            %registerRxFcn Add the given function handle to the
            %list of receivers function handles list将给定的函数句柄添加到接收者函数句柄列表中
            %
            % RECEIVERINFO is the information about receiver. It is a structure
            % with following fields
            %  CarrierFreq     - Represents carrier frequency of the
            %                    receiver
            %  NCellID         - Cell identifier
            %  RNTI            - Radio network temporary identifier
            %
            % PHYRECEIVERFCN   - Function handle provided by receiver to write
            %                    packets into its Phy reception buffer
            %
            % MACRECEIVERFCN   - Function handle provided by receiver to write
            %                    packets into its MAC reception buffer

            idx = find(cellfun(@isempty, obj.ReceiverInfo), 1);
            obj.ReceiverInfo{idx} = receiverInfo;
            obj.ReceiverPhyFcn{idx} = phyReceiverFcn;
            obj.ReceiverMACFcn{idx} = macReceiverFcn;
        end
    end
end