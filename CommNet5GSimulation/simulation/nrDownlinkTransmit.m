function [thoughputArray, maxThroughputArray, transmitSizeArray] = nrDownlinkTransmit(gNBs, UEs, globalConfig, gNBMapping)

    [thoughputArray, maxThroughputArray, transmitSizeArray] = performParallelOperation(gNBs, UEs, globalConfig, gNBMapping);
end

function [resThoughputArray, resMaxThroughputArray, resTransmitSizeArray] = performParallelOperation(gNBs, nUEs, globalConfig, gNBMapping)
    % 预分配结果数组
    nUENum = length(nUEs);
    resThoughputArray = zeros(1, nUENum);
    resMaxThroughputArray = zeros(1, nUENum);
    resTransmitSizeArray = zeros(1, nUENum);
    
    tic_parfor = tic;
    % parfor i = 1:nUEs
    for i = 1:length(nUEs)
        if ~isnan(nUEs{i}.gnbNodeId)
            % 执行传输并获取结果
            [resThoughput, resMaxThroughput, resTransmitSize] = downlinkTransmit(gNBMapping(nUEs{i}.gnbNodeId), nUEs{i}, globalConfig);
        else
            resThoughput = 0;
            resMaxThroughput = 0;
            resTransmitSize = 0;
        end
        % 存储当前UE的结果
        resThoughputArray(i) = resThoughput;
        resMaxThroughputArray(i) = resMaxThroughput;
        resTransmitSizeArray(i) = resTransmitSize;
    end
    toc_parfor = toc(tic_parfor);
    fprintf('并行操作耗时: %.4f 秒\n', toc_parfor);
end

function [resThoughput, resMaxThroughput, resTransmitSize] = downlinkTransmit(gNB, UE, globalConfig)
    simPara = struct();       % Clear simPara variable to contain all key simulation parameters
    simPara.NFrames = globalConfig.NFrames;      % Number of 10 ms frames
    simPara.SNRIn = UE.sinr; % SNR range (dB)


    simPara.PerfectChannelEstimator = true;
    simPara.DisplaySimulationInformation = globalConfig.DisplaySimulationInformation;
    simPara.DisplayDiagnostics = false;

    simPara.Carrier = gNB.Carrier;

    % PDSCH/DL-SCH parameters
    simPara.PDSCH = nrPDSCHConfig;      % This PDSCH definition is the basis for all PDSCH transmissions in the BLER simulation
    simPara.PDSCHExtension = struct();  % This structure is to hold additional simulation parameters for the DL-SCH and PDSCH

    % Define PDSCH time-frequency resource allocation per slot to be full grid (single full grid BWP)
    simPara.PDSCH.PRBSet = 0:simPara.Carrier.NSizeGrid-1;                 % PDSCH PRB allocation，设置资源块的索引，这个直接是0到该用户的资源块
    simPara.PDSCH.SymbolAllocation = [0,simPara.Carrier.SymbolsPerSlot];  % Starting symbol and number of symbols of each PDSCH allocation，固定不动
    simPara.PDSCH.MappingType = 'A';     % PDSCH mapping type ('A'(slot-wise),'B'(non slot-wise))，固定不动

    % Scrambling identifiers
    simPara.PDSCH.NID = simPara.Carrier.NCellID;   % 固定不动

    % Define the number of transmission layers to be used
    simPara.PDSCH.NumLayers = globalConfig.NumLayers;            % 全局配置，这个考虑是否为前端展开

    % Define codeword modulation and target coding rate
    % The number of codewords is directly dependent on the number of layers so ensure that

    % layers are set first before getting the codeword number
    % 这里可以选择用户的调制方式
    if simPara.PDSCH.NumCodewords > 1                             % Multicodeword transmission (when number of layers being > 4)
        simPara.PDSCH.Modulation = {UE.modulation, UE.modulation};             % 'QPSK', '16QAM', '64QAM', '256QAM'
        simPara.PDSCHExtension.TargetCodeRate = [UE.targetCodeRate UE.targetCodeRate];   % Code rate used to calculate transport block sizes
    else
        simPara.PDSCH.Modulation = UE.modulation;                       % 'QPSK', '16QAM', '64QAM', '256QAM'
        simPara.PDSCHExtension.TargetCodeRate = UE.targetCodeRate;         % Code rate used to calculate transport block sizes
    end

    % DM-RS and antenna port configuration (TS 38.211 Section 7.4.1.1)
    simPara.PDSCH.DMRS.DMRSPortSet = 0:simPara.PDSCH.NumLayers-1; % DM-RS ports to use for the layers
    % simPara.PDSCH.DMRS.DMRSTypeAPosition = 2;      % Mapping type A only. First DM-RS symbol position (2,3)
    % simPara.PDSCH.DMRS.DMRSLength = 1;             % Number of front-loaded DM-RS symbols (1(single symbol),2(double symbol))
    % simPara.PDSCH.DMRS.DMRSAdditionalPosition = 2; % Additional DM-RS symbol positions (max range 0...3)
    % simPara.PDSCH.DMRS.DMRSConfigurationType = 2;  % DM-RS configuration type (1,2)
    % simPara.PDSCH.DMRS.NumCDMGroupsWithoutData = 1;% Number of CDM groups without data
    % simPara.PDSCH.DMRS.NIDNSCID = 1;               % Scrambling identity (0...65535)
    % simPara.PDSCH.DMRS.NSCID = 0;                  % Scrambling initialization (0,1)

    % PT-RS configuration (TS 38.211 Section 7.4.1.2)
    % simPara.PDSCH.EnablePTRS = 0;                  % Enable or disable PT-RS (1 or 0)
    % simPara.PDSCH.PTRS.TimeDensity = 1;            % PT-RS time density (L_PT-RS) (1, 2, 4)
    % simPara.PDSCH.PTRS.FrequencyDensity = 2;       % PT-RS frequency density (K_PT-RS) (2 or 4)
    % simPara.PDSCH.PTRS.REOffset = '00';            % PT-RS resource element offset ('00', '01', '10', '11')
    % simPara.PDSCH.PTRS.PTRSPortSet = [];           % PT-RS antenna port, subset of DM-RS port set. Empty corresponds to lower DM-RS port number

    % Reserved PRB patterns, if required (for CORESETs, forward compatibility etc)
    % simPara.PDSCH.ReservedPRB{1}.SymbolSet = [];   % Reserved PDSCH symbols
    % simPara.PDSCH.ReservedPRB{1}.PRBSet = [];      % Reserved PDSCH PRBs
    % simPara.PDSCH.ReservedPRB{1}.Period = [];      % Periodicity of reserved resources

    % Additional simulation and DL-SCH related parameters
    %
    % PDSCH PRB bundling (TS 38.214 Section 5.1.2.3)
    simPara.PDSCHExtension.PRGBundleSize = [];     % 2, 4, or [] to signify "wideband"
    %
    % HARQ process and rate matching/TBS parameters
    simPara.PDSCHExtension.XOverhead = 6*simPara.PDSCH.EnablePTRS; % Set PDSCH rate matching overhead for TBS (Xoh) to 6 when PT-RS is enabled, otherwise 0
    simPara.PDSCHExtension.NHARQProcesses = globalConfig.NumHARQProcesses;    % Number of parallel      HARQ processes to use
    simPara.PDSCHExtension.EnableHARQ = globalConfig.EnableHARQ;      % Enable retransmissions for each process, using RV sequence [0,2,3,1]

    % LDPC decoder parameters
    % Available algorithms: 'Belief propagation', 'Layered belief propagation', 'Normalized min-sum', 'Offset min-sum'
    simPara.PDSCHExtension.LDPCDecodingAlgorithm = globalConfig.LDPCDecodingAlgorithm;
    simPara.PDSCHExtension.MaximumLDPCIterationCount = globalConfig.MaximumLDPCIterationCount;

    % Define the overall transmission antenna geometry at end-points
    % If using a CDL propagation channel then the integer number of antenna elements is
    % turned into an antenna panel configured when the channel model object is created
    simPara.NTxAnts = gNB.numTransmitAntennas;                        % Number of PDSCH transmission antennas (1,2,4,8,16,32,64,128,256,512,1024) >= NumLayers
    simPara.NRxAnts = UE.numTransmitAntennas;                                            % Number of PDSCH receive antennas (1,2,4,8,16,32,64,128,256,512,1024)

    % Define data type ('single' or 'double') for resource grids and waveforms
    simPara.DataType = globalConfig.DataType;

    % Define the general CDL/TDL propagation channel parameters
    simPara.DelayProfile = globalConfig.channel.DelayProfile;      % Use CDL-C model (Urban macrocell model)
    simPara.DelaySpread = globalConfig.channel.DelaySpread;
    simPara.MaximumDopplerShift = globalConfig.channel.MaximumDopplerShift;

    % Cross-check the PDSCH layering against the channel geometry
    % validateNumLayers(simPara);

    waveformInfo = nrOFDMInfo(simPara.Carrier); % Get information about the baseband waveform after OFDM modulation step

    % Constructed the CDL or TDL channel model object
    if contains(simPara.DelayProfile,'CDL','IgnoreCase',true)

        channel = nrCDLChannel; % CDL channel object

        % Turn the number of antennas into antenna panel array layouts. If
        % NTxAnts is not one of (1,2,4,8,16,32,64,128,256,512,1024), its value
        % is rounded up to the nearest value in the set. If NRxAnts is not 1 or
        % even, its value is rounded up to the nearest even number.
        channel = hArrayGeometry(channel,simPara.NTxAnts,simPara.NRxAnts);
        simPara.NTxAnts = prod(channel.TransmitAntennaArray.Size);
        simPara.NRxAnts = prod(channel.ReceiveAntennaArray.Size);
    else
        channel = nrTDLChannel; % TDL channel object

        % Configure the channel to automatically select a sample rate for
        % generating channel coefficients
        channel.PathGainSampleRate = 'auto';

        % Set the channel geometry
        channel.NumTransmitAntennas = simPara.NTxAnts;
        channel.NumReceiveAntennas = simPara.NRxAnts;
    end

    % Assign simulation channel parameters and waveform sample rate to the
    % object, and specify OFDM channel response as the channel response output
    % so that perfect channel estimation is calculated while filtering the
    % signal
    channel.DelayProfile = simPara.DelayProfile;
    channel.DelaySpread = simPara.DelaySpread;
    channel.MaximumDopplerShift = simPara.MaximumDopplerShift;
    channel.SampleRate = waveformInfo.SampleRate;
    channel.ChannelResponseOutput = globalConfig.channel.ChannelResponseOutput;

    chInfo = info(channel);
    maxChDelay = chInfo.MaximumChannelDelay;

    % Array to store the maximum throughput for all SNR points
    maxThroughput = zeros(length(simPara.SNRIn),1);
    % Array to store the simulation throughput for all SNR points
    simThroughput = zeros(length(simPara.SNRIn),1);
    % 存储传输了多少数据
    transmitSize = 0;

    % Set up redundancy version (RV) sequence for all HARQ processes
    if simPara.PDSCHExtension.EnableHARQ
        % In the final report of RAN WG1 meeting #91 (R1-1719301), it was
        % observed in R1-1717405 that if performance is the priority, [0 2 3 1]
        % should be used. If self-decodability is the priority, it should be
        % taken into account that the upper limit of the code rate at which
        % each RV is self-decodable is in the following order: 0>3>2>1
        rvSeq = [0 2 3 1];
    else
        % HARQ disabled - single transmission with RV=0, no retransmissions
        rvSeq = 0;
    end

    % Create DL-SCH encoder system object to perform transport channel encoding
    encodeDLSCH = nrDLSCH;
    encodeDLSCH.MultipleHARQProcesses = simPara.PDSCHExtension.EnableHARQ;
    encodeDLSCH.TargetCodeRate = simPara.PDSCHExtension.TargetCodeRate;

    % Create DL-SCH decoder system object to perform transport channel decoding
    % Use layered belief propagation for LDPC decoding, with half the number of
    % iterations as compared to the default for belief propagation decoding
    decodeDLSCH = nrDLSCHDecoder;
    decodeDLSCH.MultipleHARQProcesses = simPara.PDSCHExtension.EnableHARQ;
    decodeDLSCH.TargetCodeRate = simPara.PDSCHExtension.TargetCodeRate;
    decodeDLSCH.LDPCDecodingAlgorithm = simPara.PDSCHExtension.LDPCDecodingAlgorithm;
    decodeDLSCH.MaximumLDPCIterationCount = simPara.PDSCHExtension.MaximumLDPCIterationCount;

    % Reset the random number generator so that each SNR point will
    % experience the same noise realization
    rng('default');

    % Take full copies of the simulation-level parameter structures so that they are not
    % PCT broadcast variables when using parfor
    simLocal = simPara;
    waveinfoLocal = waveformInfo;

    % Take copies of channel-level parameters to simplify subsequent parameter referencing
    carrier = simLocal.Carrier;
    pdsch = simLocal.PDSCH;
    pdschextra = simLocal.PDSCHExtension;
    decodeDLSCHLocal = decodeDLSCH;  % Copy of the decoder handle to help PCT classification of variable
    decodeDLSCHLocal.reset();        % Reset decoder at the start of each SNR point
    % pathFilters = [];

    % Prepare simulation for new SNR point
    SNRdB = simLocal.SNRIn;
    fprintf('\nSimulating transmission scheme 1 (%dx%d) and SCS=%dkHz with %s channel at %gdB SNR for %d 10ms frame(s)\n', ...
            simLocal.NTxAnts,simLocal.NRxAnts,carrier.SubcarrierSpacing, ...
            simLocal.DelayProfile,SNRdB,simLocal.NFrames);

    % Specify the fixed order in which we cycle through the HARQ process IDs
    harqSequence = 0:pdschextra.NHARQProcesses-1;

    % Initialize the state of all HARQ processes
    harqEntity = HARQEntity(harqSequence,rvSeq,pdsch.NumCodewords);

    % Reset the channel so that each SNR point will experience the same
    % channel realization
    reset(channel);

    % Total number of slots in the simulation period
    NSlots = simLocal.NFrames * carrier.SlotsPerFrame;

    % Obtain a precoding matrix (wtx) to be used in the transmission of the
    % first transport block
    estChannelGridAnts = getInitialChannelEstimate(carrier,channel,simLocal.DataType,maxChDelay);
    newWtx = hSVDPrecoders(carrier,pdsch,estChannelGridAnts,pdschextra.PRGBundleSize);

    % Timing offset, updated in every slot for perfect synchronization and
    % when the correlation is strong for practical synchronization
    offset = 0;

    % Noise power, normalized by the IFFT size used in OFDM modulation, as
    % the OFDM modulator applies this normalization to the transmitted
    % waveform. Also normalize by the number of receive antennas, as the
    % channel model applies this normalization to the received waveform by
    % default. Calculate the noise power per RE to act as the noise
    % estimate if perfect channel estimation is enabled
    SNR = 10^(SNRdB/10);
    N0 = 1/sqrt(double(simLocal.NRxAnts)*double(waveinfoLocal.Nfft)*SNR);
    nPowerPerRE = N0^2*double(waveinfoLocal.Nfft);

    % Loop over the entire waveform length
    for nslot = 0:NSlots-1
        % Update the carrier slot numbers for new slot
        carrier.NSlot = nslot;

        % Calculate the transport block sizes for the transmission in the slot
        [pdschIndices,pdschIndicesInfo] = nrPDSCHIndices(carrier,pdsch);
        trBlkSizes = nrTBS(pdsch.Modulation,pdsch.NumLayers,numel(pdsch.PRBSet),pdschIndicesInfo.NREPerPRB,pdschextra.TargetCodeRate,pdschextra.XOverhead);

        % HARQ processing
        for cwIdx = 1:pdsch.NumCodewords
            % If new data for current process and codeword then create a new DL-SCH transport block
            if harqEntity.NewData(cwIdx)
                %TODO 考虑后续使用文件来代替
                trBlk = randi([0 1],trBlkSizes(cwIdx),1); 
                transmitSize = transmitSize + trBlkSizes(cwIdx);
                setTransportBlock(encodeDLSCH,trBlk,cwIdx-1,harqEntity.HARQProcessID);
                % If new data because of previous RV sequence time out then flush decoder soft buffer explicitly
                if harqEntity.SequenceTimeout(cwIdx)
                    resetSoftBuffer(decodeDLSCHLocal,cwIdx-1,harqEntity.HARQProcessID);
                end
            end
        end

        % Encode the DL-SCH transport blocks
        codedTrBlocks = encodeDLSCH(pdsch.Modulation,pdsch.NumLayers, ...
            pdschIndicesInfo.G,harqEntity.RedundancyVersion,harqEntity.HARQProcessID);

        % Get precoding matrix (wtx) calculated in previous slot
        wtx = newWtx;

        % Create resource grid for a slot
        pdschGrid = nrResourceGrid(carrier,simLocal.NTxAnts,OutputDataType=simLocal.DataType);

        % PDSCH modulation and precoding
        pdschSymbols = nrPDSCH(carrier,pdsch,codedTrBlocks);
        [pdschAntSymbols,pdschAntIndices] = nrPDSCHPrecode(carrier,pdschSymbols,pdschIndices,wtx);

        % PDSCH mapping in grid associated with PDSCH transmission period
        pdschGrid(pdschAntIndices) = pdschAntSymbols;

        % PDSCH DM-RS precoding and mapping
        dmrsSymbols = nrPDSCHDMRS(carrier,pdsch);
        dmrsIndices = nrPDSCHDMRSIndices(carrier,pdsch);
        [dmrsAntSymbols,dmrsAntIndices] = nrPDSCHPrecode(carrier,dmrsSymbols,dmrsIndices,wtx);
        pdschGrid(dmrsAntIndices) = dmrsAntSymbols;

        % PDSCH PT-RS precoding and mapping
        ptrsSymbols = nrPDSCHPTRS(carrier,pdsch);
        ptrsIndices = nrPDSCHPTRSIndices(carrier,pdsch);
        [ptrsAntSymbols,ptrsAntIndices] = nrPDSCHPrecode(carrier,ptrsSymbols,ptrsIndices,wtx);
        pdschGrid(ptrsAntIndices) = ptrsAntSymbols;

        % OFDM modulation
        txWaveform = nrOFDMModulate(carrier,pdschGrid);

        % Pass data through channel model. Append zeros at the end of the
        % transmitted waveform to flush channel content. These zeros take
        % into account any delay introduced in the channel. This is a mix
        % of multipath delay and implementation delay. This value may
        % change depending on the sampling rate, delay profile, and delay
        % spread. The channel model also returns the OFDM channel response
        % and timing offset for the specified carrier
        txWaveform = [txWaveform; zeros(maxChDelay,size(txWaveform,2))]; %#ok<AGROW>
        [rxWaveform,ofdmResponse,timingOffset] = channel(txWaveform,carrier);

        % Add AWGN to the received time domain waveform
        noise = N0*randn(size(rxWaveform),"like",rxWaveform);
        rxWaveform = rxWaveform + noise;

        if (simLocal.PerfectChannelEstimator)
            % For perfect synchronization, use the timing offset obtained
            % from the channel
            offset = timingOffset;
        else
            % Practical synchronization. Correlate the received waveform
            % with the PDSCH DM-RS to give timing offset estimate 't' and
            % correlation magnitude 'mag'. The function
            % hSkipWeakTimingOffset is used to update the receiver timing
            % offset. If the correlation peak in 'mag' is weak, the current
            % timing estimate 't' is ignored and the previous estimate
            % 'offset' is used
            [t,mag] = nrTimingEstimate(carrier,rxWaveform,dmrsIndices,dmrsSymbols);
            offset = hSkipWeakTimingOffset(offset,t,mag);
            % Display a warning if the estimated timing offset exceeds the
            % maximum channel delay
            if offset > maxChDelay
                warning(['Estimated timing offset (%d) is greater than the maximum channel delay (%d).' ...
                    ' This will result in a decoding failure. This may be caused by low SNR,' ...
                    ' or not enough DM-RS symbols to synchronize successfully.'],offset,maxChDelay);
            end
        end
        rxWaveform = rxWaveform(1+offset:end,:);

        % Perform OFDM demodulation on the received data to recreate the
        % resource grid, including padding in the event that practical
        % synchronization results in an incomplete slot being demodulated
        rxGrid = nrOFDMDemodulate(carrier,rxWaveform);
        [K,L,R] = size(rxGrid);
        if (L < carrier.SymbolsPerSlot)
            rxGrid = cat(2,rxGrid,zeros(K,carrier.SymbolsPerSlot-L,R));
        end

        if (simLocal.PerfectChannelEstimator)
            % For perfect channel estimate, use the OFDM channel response
            % obtained from the channel
            estChannelGridAnts = ofdmResponse;

            % For perfect noise estimate, use the noise power per RE
            noiseEst = nPowerPerRE;

            % Get PDSCH resource elements from the received grid and
            % channel estimate
            [pdschRx,pdschHest,~,pdschHestIndices] = nrExtractResources(pdschIndices,rxGrid,estChannelGridAnts);

            % Apply precoding to channel estimate
            pdschHest = nrPDSCHPrecode(carrier,pdschHest,pdschHestIndices,permute(wtx,[2 1 3]));
        else
            % Practical channel estimation between the received grid and
            % each transmission layer, using the PDSCH DM-RS for each
            % layer. This channel estimate includes the effect of
            % transmitter precoding
            [estChannelGridPorts,noiseEst] = hSubbandChannelEstimate(carrier,rxGrid,dmrsIndices,dmrsSymbols,pdschextra.PRGBundleSize,'CDMLengths',pdsch.DMRS.CDMLengths);

            % Average noise estimate across PRGs and layers
            noiseEst = mean(noiseEst,'all');

            % Get PDSCH resource elements from the received grid and
            % channel estimate
            [pdschRx,pdschHest] = nrExtractResources(pdschIndices,rxGrid,estChannelGridPorts);

            % Remove precoding from estChannelGridPorts to get channel
            % estimate w.r.t. antennas
            estChannelGridAnts = precodeChannelEstimate(carrier,estChannelGridPorts,conj(wtx));
        end

        % Equalization
        [pdschEq,csi] = nrEqualizeMMSE(pdschRx,pdschHest,noiseEst);

        % Common phase error (CPE) compensation
        if ~isempty(ptrsIndices)
            % Initialize temporary grid to store equalized symbols
            tempGrid = nrResourceGrid(carrier,pdsch.NumLayers);

            % Extract PT-RS symbols from received grid and estimated
            % channel grid
            [ptrsRx,ptrsHest,~,~,ptrsHestIndices,ptrsLayerIndices] = nrExtractResources(ptrsIndices,rxGrid,estChannelGridAnts,tempGrid);
            ptrsHest = nrPDSCHPrecode(carrier,ptrsHest,ptrsHestIndices,permute(wtx,[2 1 3]));

            % Equalize PT-RS symbols and map them to tempGrid
            ptrsEq = nrEqualizeMMSE(ptrsRx,ptrsHest,noiseEst);
            tempGrid(ptrsLayerIndices) = ptrsEq;

            % Estimate the residual channel at the PT-RS locations in
            % tempGrid
            cpe = nrChannelEstimate(tempGrid,ptrsIndices,ptrsSymbols);

            % Sum estimates across subcarriers, receive antennas, and
            % layers. Then, get the CPE by taking the angle of the
            % resultant sum
            cpe = angle(sum(cpe,[1 3 4]));

            % Map the equalized PDSCH symbols to tempGrid
            tempGrid(pdschIndices) = pdschEq;

            % Correct CPE in each OFDM symbol within the range of reference
            % PT-RS OFDM symbols
            symLoc = pdschIndicesInfo.PTRSSymbolSet(1)+1:pdschIndicesInfo.PTRSSymbolSet(end)+1;
            tempGrid(:,symLoc,:) = tempGrid(:,symLoc,:).*exp(-1i*cpe(symLoc));

            % Extract PDSCH symbols
            pdschEq = tempGrid(pdschIndices);
        end

        % Decode PDSCH physical channel
        [dlschLLRs,rxSymbols] = nrPDSCHDecode(carrier,pdsch,pdschEq,noiseEst);

        % Display EVM per layer, per slot and per RB
        if (simLocal.DisplayDiagnostics)
            plotLayerEVM(NSlots,nslot,pdsch,size(pdschGrid),pdschIndices,pdschSymbols,pdschEq);
        end

        % Scale LLRs by CSI
        csi = nrLayerDemap(csi); % CSI layer demapping
        for cwIdx = 1:pdsch.NumCodewords
            Qm = length(dlschLLRs{cwIdx})/length(rxSymbols{cwIdx}); % bits per symbol
            csi{cwIdx} = repmat(csi{cwIdx}.',Qm,1);                 % expand by each bit per symbol
            dlschLLRs{cwIdx} = dlschLLRs{cwIdx} .* csi{cwIdx}(:);   % scale by CSI
        end

        % Decode the DL-SCH transport channel
        decodeDLSCHLocal.TransportBlockLength = trBlkSizes;
        [decbits,blkerr] = decodeDLSCHLocal(dlschLLRs,pdsch.Modulation,pdsch.NumLayers,harqEntity.RedundancyVersion,harqEntity.HARQProcessID);
        % TODO: decbits为传输得到的结果，后续可能需要进行文件重组


        % Store values to calculate throughput
        simThroughput = simThroughput + sum(~blkerr .* trBlkSizes);
        maxThroughput = maxThroughput + sum(trBlkSizes);

        % Update current process with CRC error and advance to next process
        procstatus = updateAndAdvance(harqEntity,blkerr,trBlkSizes,pdschIndicesInfo.G);
        if (simLocal.DisplaySimulationInformation)
            fprintf('\n(%3.2f%%) NSlot=%d, %s',100*(nslot+1)/NSlots,nslot,procstatus);
        end

        % Get precoding matrix for next slot
        newWtx = hSVDPrecoders(carrier,pdsch,estChannelGridAnts,pdschextra.PRGBundleSize);

    end

    % Display the results dynamically in the command window
    if (simLocal.DisplaySimulationInformation)
        fprintf('\n');
    end
    fprintf('\nThroughput(Mbps) for %d frame(s) = %.4f\n',simLocal.NFrames,1e-6*simThroughput/(simLocal.NFrames*10e-3));
    fprintf('Throughput(%%) for %d frame(s) = %.4f\n',simLocal.NFrames,simThroughput*100/maxThroughput);

    resThoughput = 1e-6*simThroughput/(simLocal.NFrames*10e-3);
    resMaxThroughput = simThroughput*100/maxThroughput;
    resTransmitSize = transmitSize;

end

function estChannelGrid = getInitialChannelEstimate(carrier,propchannel,dataType,maxChDelay)
% Obtain channel estimate before first transmission. This can be used to
% obtain a precoding matrix for the first slot.

    ofdmInfo = nrOFDMInfo(carrier);

    % Clone of the channel
    chClone = propchannel.clone();
    chClone.release();

    % No filtering needed to get perfect channel estimate
    chClone.ChannelFiltering = false;
    chClone.OutputDataType = dataType;
    chClone.NumTimeSamples = (ofdmInfo.SampleRate/1000/carrier.SlotsPerSubframe)+maxChDelay;

    % Get the perfect channel estimate
    estChannelGrid = chClone(carrier);

end

function estChannelGrid = precodeChannelEstimate(carrier,estChannelGrid,W)
% Apply precoding matrix W to the last dimension of the channel estimate

    [K,L,R,P] = size(estChannelGrid);
    estChannelGrid = reshape(estChannelGrid,[K*L R P]);
    estChannelGrid = nrPDSCHPrecode(carrier,estChannelGrid,reshape(1:numel(estChannelGrid),[K*L R P]),W);
    estChannelGrid = reshape(estChannelGrid,K,L,R,[]);

end

