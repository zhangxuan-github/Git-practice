clc;
clear;
%% Config
prompt = {'用电信息采集用户节点数量:', ...
          '配电自动化用户节点数量:', ...
          '新能源调控用户节点数量:', ...
          '多模通信服务器数量:'};
dlg_title = '输入参数';
dims = [1 50];
default_vals = {'8', '7', '6', '3'};
input_vals = inputdlg(prompt, dlg_title, dims, default_vals);

if isempty(input_vals)
    disp('用户取消了输入！');
    return;
end

num_electric_nodes = str2double(input_vals{1});
num_automation_nodes = str2double(input_vals{2});
num_new_energy_nodes = str2double(input_vals{3});
num_servers = str2double(input_vals{4});

num_users_type = [num_electric_nodes, num_automation_nodes, num_new_energy_nodes];

fprintf('用电信息采集用户节点数量: %d\n', num_electric_nodes);
fprintf('配电自动化用户节点数量: %d\n', num_automation_nodes);
fprintf('新能源调控用户节点数量: %d\n', num_new_energy_nodes);
fprintf('多模通信服务器数量: %d\n', num_servers);

[dist_matrix_user, dist_matrix, user_positions, server_positions] = calculate_distances( ...
    num_electric_nodes, num_automation_nodes, num_new_energy_nodes, num_servers);

disp('距离矩阵:');
disp(dist_matrix);

% plot_network(user_positions, server_positions, num_users_type);

pairs = pair_nodes(dist_matrix);
disp('用户节点-配对服务器结果:');
disp(pairs);

% plot_pairings(user_positions, server_positions, pairs);

selected_mode = select_communication_mode();


communication_mode_config();

performance_results = simulate_performance(pairs, user_positions, server_positions, selected_mode);
disp('性能指标:');
disp(performance_results);

mode_names = {'5G', 'HPCL', 'HRF'};
communication_modes = performance_results(:,4);
% plot_pairings_with_modes(user_positions, server_positions, pairs, communication_modes, mode_names);


plot_pairings_with_user_user_links(user_positions, server_positions, pairs, communication_modes, mode_names, dist_matrix_user, num_users_type);


NumUE = num_electric_nodes+num_automation_nodes+num_new_energy_nodes;
generateAPPConfig(NumUE);
generateUEConfig('NRFDDAPPConfigFile.xlsx', 'NRFDDRLCChannelConfig.xlsx');

%% scheduling
rng('default'); % Reset the random number generator
simParameters = []; % Clear the simParameters variable
simParameters.NumFramesSim = 1; % Simulation time in terms of number of 10 ms frames-------------
simParameters.SchedulingType = 1; % Set the value to 0 (slot based scheduling) or 1 (symbol based scheduling)---------
AppConfig=readtable("NRFDDAPPConfigFile.xlsx");
save("NRFDDAppConfig.mat","AppConfig");
load('NRFDDAppConfig.mat');
numUEs = height(AppConfig);

areaSize = 500;
lambda = 0.1;  
numPoints = numUEs; 
positions = zeros(numPoints, 3);
for i = 1:numPoints
    x = poissrnd(lambda * areaSize);  
    y = poissrnd(lambda * areaSize); 
    x = min(max(x, 0), areaSize);  
    y = min(max(y, 0), areaSize);  % 限制在 [0, areaSize] 
    positions(i, :) = [x, y, 0];
end

simParameters.UEPosition = positions;
simParameters.NumUEs = numPoints;
simParameters.UESpeed = 20;% Supported speed: '5/10/15/20/25'
% Validate the UE positions
validateattributes(simParameters.UEPosition, {'numeric'}, {'nonempty', 'real', 'nrows', simParameters.NumUEs, 'ncols', 3, 'finite'}, 'simParameters.UEPosition', 'UEPosition')
simParameters.NumRBs = 66;%-------------------
simParameters.SCS = 60; % kHz-----------------------
simParameters.DLCarrierFreq = 2.635e9; % Hz
simParameters.ULCarrierFreq = 2.515e9; % Hz
% The UL and DL carriers are assumed to have symmetric channel
% bandwidth 
simParameters.DLBandwidth = 50e6; % 50 gHz --------------------
simParameters.ULBandwidth = 50e6; % Hz --------------------
simParameters.UETxPower = 23;  % Tx power for all the UEs in dBm  
simParameters.GNBTxPower = 24; % Tx power for gNB in dBm   24  --------------------------
simParameters.GNBRxGain = 6; % Receiver antenna gain at gNB   5-------------------------
simParameters.SINR90pc = [-5.46 -0.46 4.54 9.05 11.54 14.04 15.54 18.04 ...
    20.04 22.43 24.93 25.43 27.43 30.43 33.43];
simParameters.SchedulerStrategy = 'a-PF'; % Supported scheduling strategies: 'a-PF','PF', 'RR', and 'BestCQI'
simParameters.RBAllocationLimitUL = 66; % For PUSCH -----------------------
simParameters.RBAllocationLimitDL = 66; % For PDSCH -----------------------
% cyl add
RLCChannelConfig=readtable("NRFDDRLCChannelConfig.xlsx");
save("NRFDDRLCChannelConfig.mat","RLCChannelConfig");

load('NRFDDRLCChannelConfig.mat')
simParameters.RLCChannelConfig = RLCChannelConfig;
simParameters.CQIVisualization = 1; % Supported scheduling strategies: 'a-PF','PF', 'RR', and 'BestCQI'
simParameters.RBVisualization =1;
simParameters.TimeVisualization = false;
enableTraces = 0;
simParameters.NumMetricsSteps =10;
parametersLogFile = 'simParameters'; % For logging the simulation parameters
simulationLogFile = 'simulationLogs'; % For logging the simulation traces
simulationMetricsFile = 'simulationMetrics'; % For logging the simulation metrics

% Enable packet capture (PCAP)
simParameters.PCAPLogging =0;
simParameters.UEofInterest =1; % Log the packets of UE with this RNTI
% dlAppDataRate = 16e4*ones(simParameters.NumUEs,1); % DL application data rate in kilo bits per second (kbps)
% ulAppDataRate = 16e4*ones(simParameters.NumUEs,1); % UL application data rate in kbps
% % Validate the DL application data rate
% validateattributes(dlAppDataRate, {'numeric'}, {'nonempty', 'vector', 'numel', simParameters.NumUEs, 'finite', '>', 0}, 'dlAppDataRate', 'dlAppDataRate')
% % Validate the UL application data rate
% validateattributes(ulAppDataRate, {'numeric'}, {'nonempty', 'vector', 'numel', simParameters.NumUEs, 'finite', '>', 0}, 'ulAppDataRate', 'ulAppDataRate')



% Validate the host device type for the applications configured
validateattributes(AppConfig.HostDevice, {'numeric'}, {'nonempty', 'integer', '>=', 0, '<=', 1}, 'AppConfig.HostDevice', 'HostDevice');
simParameters.DuplexMode = 0; %% FDD
simParameters.NCellID = 1; % Physical cell ID
simParameters.Position = [0 0 0];% Position of gNB in (x,y,z) coordinates
csirsConfig = nrCSIRSConfig('NID', simParameters.NCellID, 'NumRB', simParameters.NumRBs, 'RowNumber', 2, 'SubcarrierLocations', 1, 'SymbolLocations', 0);
simParameters.CSIRSConfig = {csirsConfig};
csiReportConfig = struct('SubbandSize', 8, 'CQIMode', 'Subband');
simParameters.CSIReportConfig = {csiReportConfig};
channelModelUL = cell(1, simParameters.NumUEs);
channelModelDL = cell(1, simParameters.NumUEs);
waveformInfo = nrOFDMInfo(simParameters.NumRBs, simParameters.SCS);
for ueIdx = 1:simParameters.NumUEs
    % Configure the uplink channel model
    channel = nrCDLChannel;
    channel.DelayProfile = 'CDL-C';
    channel.DelaySpread = 3e-08;
    channel.Seed = 73 + (ueIdx - 1);
    channel.CarrierFrequency = simParameters.ULCarrierFreq;
    channel.MaximumDopplerShift = 175.66666666666666;
    channel.TransmitAntennaArray.Size = [1, 1, 1, 1, 1];
    channel.ReceiveAntennaArray.Size = [1, 1, 1, 1, 1];
    channel.SampleRate = waveformInfo.SampleRate;
    channelModelUL{ueIdx} = channel;

    % Configure the downlink channel model
    channel = nrCDLChannel;
    channel.DelayProfile = 'CDL-C';
    channel.DelaySpread = 3e-08;
    channel.Seed = 73 + (ueIdx - 1);
    channel.CarrierFrequency = simParameters.DLCarrierFreq;
    channel.MaximumDopplerShift = 175.66666666666666;
    channel.TransmitAntennaArray.Size = [1, 1, 1, 1, 1];
    channel.ReceiveAntennaArray.Size = [1, 1, 1, 1, 1];
    channel.SampleRate = waveformInfo.SampleRate;
    channelModelDL{ueIdx} = channel;

%the orignal version     channel = nrTDLChannel;
%     channel.Seed = 73 + (ueIdx - 1);
%     channel.DelayProfile = 'TDL-C';
%     channel.DelaySpread = 30e-9;
%     channel.MaximumDopplerShift = 50;
%     channel.NumTransmitAntennas = 1;
%     channel.NumReceiveAntennas = 1;
%     channel.SampleRate = waveformInfo.SampleRate;
%     channelModelUL{ueIdx} = channel;
% 
%     channel = nrTDLChannel;
%     channel.Seed = 73 + (ueIdx - 1);
%     channel.DelayProfile = 'TDL-C';
%     channel.DelaySpread = 30e-9;
%     channel.MaximumDopplerShift = 50;
%     channel.NumTransmitAntennas = 1;
%     channel.NumReceiveAntennas = 1;
%     channel.SampleRate = waveformInfo.SampleRate;
%     channelModelDL{ueIdx} = channel;

end
simParameters.PUSCHPrepTime = 200; % In microseconds
slotDuration = 1/(simParameters.SCS/15); % In ms 一个slot多少毫秒 0.5ms-30khz
numSlotsFrame = 10/slotDuration; % Number of slots in a 10 ms frame
numSlotsSim = simParameters.NumFramesSim * numSlotsFrame; % Number of slots in the simulation
simParameters.MetricsStepSize = ceil(numSlotsSim / simParameters.NumMetricsSteps);
if mod(numSlotsSim, simParameters.NumMetricsSteps) ~= 0
    % Update the NumMetricsSteps parameter if numSlotsSim is not
    % completely divisible by it
    simParameters.NumMetricsSteps = floor(numSlotsSim / simParameters.MetricsStepSize);
end
%numLogicalChannels = 1; % Only 1 logical channel is assumed in each UE in this example
% Logical channel id (logical channel ID of data radio bearers starts from 4) 
%simParameters.LCHConfig.LCID = 4;
lchInfo = repmat(struct('RNTI', [], 'LCID', [], 'EntityDir', []), [simParameters.NumUEs 1]);
for ueIdx = 1:simParameters.NumUEs
    lchInfo(ueIdx).RNTI = ueIdx;
    lchInfo(ueIdx).LCID = simParameters.RLCChannelConfig.LogicalChannelID(simParameters.RLCChannelConfig.RNTI == ueIdx);
    lchInfo(ueIdx).EntityDir = simParameters.RLCChannelConfig.EntityType(simParameters.RLCChannelConfig.RNTI == ueIdx);
end
% simParameters.RLCConfig.EntityType = 2;%RLC UM 双向实体RLC不做重传ARQ处理。
% rlcChannelConfigStruct.LCGID = 1; % Mapping between logical channel and logical channel group ID
% rlcChannelConfigStruct.Priority = 1; % Priority of each logical channel
% rlcChannelConfigStruct.PBR = 8; % Prioritized bitrate (PBR), in kilobytes per second, of each logical channel
% rlcChannelConfigStruct.BSD = 10; % Bucket size duration (BSD), in ms, of each logical channel
% rlcChannelConfigStruct.EntityType = simParameters.RLCConfig.EntityType;
% rlcChannelConfigStruct.LogicalChannelID = simParameters.LCHConfig.LCID;
if ~isfield(simParameters, 'SchedulingType') || simParameters.SchedulingType == 0 % If no scheduling type is specified or slot based scheduling is specified
    tickGranularity = 14;
    simParameters.PUSCHMappingType = 'A';
    simParameters.PDSCHMappingType = 'A';
else % Symbol based scheduling
    tickGranularity = 1;
    simParameters.PUSCHMappingType = 'B';
    simParameters.PDSCHMappingType = 'B';
end
simParams = rmfield(simParameters); % 移除Mobility字段
% Create scheduler
switch(simParameters.SchedulerStrategy)
    case 'RR' % Round-robin scheduler
        scheduler = hNRSchedulerRoundRobin(simParameters);
    case 'PF' % Proportional fair scheduler
        scheduler = hNRSchedulerProportionalFair(simParameters);
    case 'a-PF' % alpha-Proportional fair scheduler
        scheduler = hNRScheduleralphaProportionalFair(simParameters);
    case 'BestCQI' % Best CQI scheduler
        scheduler = hNRSchedulerBestCQI(simParameters);
end
addScheduler(gNB, scheduler); % Add scheduler to gNB；gnb中的function
simParameters.ChannelModel = channelModelUL;                       
gNB.PhyEntity = hNRGNBPhy(simParameters); % Create the PHY layer instance
configurePhy(gNB, simParameters); % Configure the PHY layer
setPhyInterface(gNB); % Set the interface to PHY layer

% Create the set of UE nodes
UEs = cell(simParameters.NumUEs, 1);
fprintf('Create UE PHY layer\n'); 
for ueIdx=1:simParameters.NumUEs
    ueParam = simParameters;
    ueParam.Position = simParameters.UEPosition(ueIdx, :); % Position of the UE----------------
    ueParam.ChannelModel = channelModelDL{ueIdx};
    ueParam.CSIReportConfig = csiReportConfig;
    UEs{ueIdx} = hNRUE(ueParam, ueIdx);
    UEs{ueIdx}.PhyEntity = hNRUEPhy(ueParam, ueIdx); % Create the PHY layer instance
    configurePhy(UEs{ueIdx}, ueParam); % Configure the PHY layer
    setPhyInterface(UEs{ueIdx}); % Set up the interface to PHY layer

    % Setup logical channel at gNB for the UE   在 gNB 为 UE 建立逻辑信道----------
    %configureLogicalChannel(gNB, ueIdx, rlcChannelConfigStruct);
    % Setup logical channel at UE  % 在 UE 建立逻辑信道---------
    %configureLogicalChannel(UEs{ueIdx}, ueIdx, rlcChannelConfigStruct);
    %------------------------
end


% Setup logical channels
fprintf('Create UE logical channel\n'); 
for lchInfoIdx = 1:size(simParameters.RLCChannelConfig, 1)
    rlcChannelConfigStruct = table2struct(simParameters.RLCChannelConfig(lchInfoIdx, :));
    ueIdx_logicalchannnel = simParameters.RLCChannelConfig.RNTI(lchInfoIdx);
    % Setup the logical channel at gNB and UE%在gNB和UE设置逻辑通道
    gNB.configureLogicalChannel(ueIdx_logicalchannnel, rlcChannelConfigStruct);
    %configureLogicalChannel(gNB, ueIdx_logicalchannnel, rlcChannelConfigStruct);
    UEs{ueIdx_logicalchannnel}.configureLogicalChannel(ueIdx_logicalchannnel, rlcChannelConfigStruct);
    %configureLogicalChannel(UEs{ueIdx_logicalchannnel}, ueIdx_logicalchannnel, rlcChannelConfigStruct);
end


%     % Create an object for On-Off network traffic pattern and add it to the
%     % specified UE. This object generates the uplink data traffic on the UE
%         % 为 On-Off 网络流量模式创建一个对象，并将其添加到指定的 UE。该对象在 UE 上生成上行数据流量
%     ulApp = networkTrafficOnOff('GeneratePacket', true, ...
%         'OnTime', simParameters.NumFramesSim*10e-3, 'OffTime', 0, 'DataRate', ulAppDataRate(ueIdx));
%     UEs{ueIdx}.addApplication(ueIdx, simParameters.LCHConfig.LCID, ulApp);
% 
%     % Create an object for On-Off network traffic pattern for the specified
%     % UE and add it to the gNB. This object generates the downlink data
%     % traffic on the gNB for the UE
%     dlApp = networkTrafficOnOff('GeneratePacket', true, ...
%         'OnTime', simParameters.NumFramesSim*10e-3, 'OffTime', 0, 'DataRate', dlAppDataRate(ueIdx));
%     gNB.addApplication(ueIdx, simParameters.LCHConfig.LCID, dlApp);
% simParameters.MaxReceivers = simParameters.NumUEs + 1; % Number of nodes
% % Create packet distribution object
% packetDistributionObj = hNRPacketDistribution(simParameters);
% hNRSetUpPacketDistribution(simParameters, gNB, UEs, packetDistributionObj);
% Add data traffic pattern generators to gNB and UE nodes
for appIdx = 1:size(AppConfig, 1)
    
    % Create an object for On-Off network traffic pattern
    app = networkTrafficOnOff('PacketSize', AppConfig.PacketSize(appIdx), 'GeneratePacket', true, ...
            'OnTime', simParameters.NumFramesSim/100, 'OffTime', 0, 'DataRate', AppConfig.DataRate(appIdx));

    if AppConfig.HostDevice(appIdx) == 0
        % Add traffic pattern that generates traffic on downlink
        addApplication(gNB, AppConfig.RNTI(appIdx), AppConfig.LCID(appIdx), app);
    else
        % Add traffic pattern that generates traffic on uplink
        addApplication(UEs{AppConfig.RNTI(appIdx)}, AppConfig.RNTI(appIdx), AppConfig.LCID(appIdx), app);
    end
end

% Setup the UL and DL packet distribution mechanism
simParameters.MaxReceivers = simParameters.NumUEs + 1; % Number of nodes
% Create packet distribution object创建包分发对象
packetDistributionObj = hNRPacketDistribution(simParameters);
hNRSetUpPacketDistribution(simParameters, gNB, UEs, packetDistributionObj);
% Enable PCAP logging
if simParameters.PCAPLogging
    % To generate unique file name for every simulation run为每次模拟运行生成唯一的文件名
    ueCapturefileName = strcat('CellID-', num2str(simParameters.NCellID), '_ue-',num2str(simParameters.UEofInterest), '_', num2str(now));
    enablePacketLogging(UEs{simParameters.UEofInterest}.PhyEntity, ueCapturefileName);
end
if enableTraces
    % Create an object for RLC traces logging
    simRLCLogger = hNRRLCLogger(simParameters, lchInfo);
    % Create an object for MAC traces logging
    simSchedulingLogger = hNRSchedulingLogger(simParameters);
    % Create an object for PHY traces logging
    simPhyLogger = hNRPhyLogger(simParameters);
    % Create an object for CQI and RB grid visualization
    if simParameters.TimeVisualization
%         TimeVisualizer = hNRTimeVisualizer(simParameters, 'TimeLogger', simTimeLogger);
        TimeVisualizer = hNRTimeVisualizer(simParameters, 'PHYLogger', simPhyLogger);
    end
    if simParameters.CQIVisualization || simParameters.RBVisualization
        gridVisualizer = hNRGridVisualizer(simParameters, 'MACLogger', simSchedulingLogger);
    end
end
nodes = struct('UEs', {UEs}, 'GNB', gNB);
% metricsVisualizer = hNRMetricsVisualizer(simParameters, 'Nodes', nodes, 'EnableSchedulerMetricsPlots', true, 'EnablePhyMetricsPlots', true);

appdelayVisualizer = hNRAppDelayVisualizer(simParameters,'Nodes', nodes,'EnableSchedulerMetricsPlots', true, 'EnablePhyMetricsPlots', true);
slotNum = 0;
numSymbolsSim = numSlotsSim * 14; % Simulation time in units of symbol duration (assuming normal cyclic prefix)
numSymbolsSim
% Execute all the symbols in the simulation
for symbolNum = 1 : tickGranularity : numSymbolsSim
    if mod(symbolNum - 1, 14) == 0
        slotNum = slotNum + 1;
    end
    
    % Run MAC and PHY of gNB
    run(gNB);
    
    % Run MAC and PHY of UEs
    for ueIdx = 1:simParameters.NumUEs
        run(UEs{ueIdx});
    end
    
    symbolNum

    if enableTraces
        % RLC logging (only at slot boundary)
        if (simParameters.SchedulingType == 1 && mod(symbolNum, 14) == 0) || (simParameters.SchedulingType == 0 && mod(symbolNum-1, 14) == 0)
            logCellRLCStats(simRLCLogger, gNB, UEs);
        end

        % MAC logging
        logCellSchedulingStats(simSchedulingLogger, symbolNum, gNB, UEs);

        % PHY logging
        logCellPhyStats(simPhyLogger, symbolNum, gNB, UEs);

    end
    
    % Visualization    
    % Check slot boundary
    if symbolNum > 1 && ((simParameters.SchedulingType == 1 && mod(symbolNum, 14) == 0) || (simParameters.SchedulingType == 0 && mod(symbolNum-1, 14) == 0))
        % If the update periodicity is reached, plot scheduler metrics and PHY metrics at slot boundary
        if mod(slotNum, simParameters.MetricsStepSize) == 0
%             plotLiveMetrics(metricsVisualizer);
            plotLiveMetrics(appdelayVisualizer);
        end
    end
    
    % Advance timer ticks for gNB and UEs by 14 symbols
    advanceTimer(gNB, tickGranularity);
    for ueIdx = 1:simParameters.NumUEs
        advanceTimer(UEs{ueIdx}, tickGranularity);
    end
end
% metrics = getMetrics(metricsVisualizer);
metrics = getMetrics(appdelayVisualizer);
save(simulationMetricsFile, 'metrics');
displayPerformanceIndicators(appdelayVisualizer)
% if enableTraces
%     % Read the logs and save them in MAT-files
%     simulationLogs = cell(1, 1);
%     simulationLogs{1} = struct('ULTimeStepLogs',[], 'SchedulingAssignmentLogs',[] ,'RLCLogs',[]);
%     [~, simulationLogs{1}.ULTimeStepLogs] = getSchedulingLogs(simSchedulingLogger); % UL time step scheduling logs
%     simulationLogs{1}.SchedulingAssignmentLogs = getGrantLogs(simSchedulingLogger); % Scheduling assignments log
%     simulationLogs{1}.RLCLogs = getRLCLogs(simRLCLogger); % RLC statistics logs
%     save(simulationLogFile, 'simulationLogs'); % Save simulation logs in a MAT-file
%     save(parametersLogFile, 'simParameters'); % Save simulation parameters in a MAT-file
% end
if enableTraces
    simulationLogs = cell(1,1);
    % Read the logs and save them in MAT-files
    if simParameters.DuplexMode == 0 % FDD
        logInfo = struct('DLTimeStepLogs', [], 'ULTimeStepLogs', [], 'SchedulingAssignmentLogs', [], 'BLERLogs', [], 'AvgBLERLogs', []);
        [logInfo.DLTimeStepLogs, logInfo.ULTimeStepLogs] = getSchedulingLogs(simSchedulingLogger);
    else % TDD
        logInfo = struct('TimeStepLogs', [], 'SchedulingAssignmentLogs', [], 'BLERLogs', [], 'AvgBLERLogs', []);
        logInfo.TimeStepLogs = getSchedulingLogs(simSchedulingLogger);
    end
    [logInfo.BLERLogs, logInfo.AvgBLERLogs] = getBLERLogs(simPhyLogger); % BLER logs
    logInfo.SchedulingAssignmentLogs = getGrantLogs(simSchedulingLogger); % Scheduling assignments log
    simulationLogs{1} = logInfo;
    save(parametersLogFile, 'simParameters'); % Save simulation parameters in a MAT-file
    save(simulationLogFile, 'simulationLogs'); % Save simulation logs in a MAT-file
end

function generateAPPConfig(NumUE)
    % 参数定义
    DataRates = [250, 200, 100]; % 业务到达率
    PacketSize = 8; % 固定的包大小
    LCIDRange = [5, 10]; % LCID 范围
    HostDeviceRange = [0, 1]; % HostDevice 可能值

    % 初始化空表格
    ConfigData = table([], [], [], [], [], ...
        'VariableNames', {'DataRate', 'PacketSize', 'HostDevice', 'RNTI', 'LCID'});

    % 按行生成数据
    for i = 1:NumUE
        % 随机选择业务到达率
        dataRate = DataRates(randi(length(DataRates)));
        % 随机生成其他列数据
        packetSize = PacketSize;
        hostDevice = randi(HostDeviceRange);
        rnti = i; % RNTI 为当前行号
        lcid = randi(LCIDRange(2) - LCIDRange(1) + 1) - 1; % LCID 范围 0 到 20
        if lcid<1
            lcid=1;
        end

        % 添加到表格
        newRow = table(dataRate, packetSize, hostDevice, rnti, lcid, ...
            'VariableNames', {'DataRate', 'PacketSize', 'HostDevice', 'RNTI', 'LCID'});
        ConfigData = [ConfigData; newRow]; %#ok<AGROW> 
    end
     % 清空文件内容
    filename = 'NRFDDAPPConfigFile.xlsx';
    if exist(filename, 'file')
        delete(filename); % 删除现有文件
    end

    % 保存为 xlsx 文件
    writetable(ConfigData, filename);
    fprintf('配置文件已生成并保存为 %s\n', filename);
%     fprintf('配置文件已生成\n');
end

function generateUEConfig(configFilePath, outputFilePath)
    % 读取已有的配置文件
    ConfigData = readtable(configFilePath);

    % 参数定义
    LCGIDOptions = [1, 3, 5];
    SeqNumFieldLengthOptions = [6, 12];
    MaxTxBufferSDUsOptions = [2, 3, 5, 7];
    ReassemblyTimerOptions = [5, 10, 15];
    EntityTypeOptions = [0, 1, 2];
    PriorityMap = [3, 2, 1]; % 对应 DataRates [8000, 3000, 1500]
    PBROptions = [8, 16];
    BSDOptions = [5, 10];

    % 初始化输出表格
    NumUE = height(ConfigData); % 从 ConfigFile 中获取行数
    UEConfigData = table([], [], [], [], [], [], [], [], [], [], ...
        'VariableNames', {'RNTI', 'LogicalChannelID', 'LCGID', 'SeqNumFieldLength', ...
                          'MaxTxBufferSDUs', 'ReassemblyTimer', 'EntityType', ...
                          'Priority', 'PBR', 'BSD'});

    for i = 1:NumUE
        % 提取 RNTI 和 LogicalChannelID
        RNTI = ConfigData.RNTI(i);
        LogicalChannelID = ConfigData.LCID(i);

        % 生成其他列数据
        LCGID = LCGIDOptions(randi(length(LCGIDOptions)));
        SeqNumFieldLength = SeqNumFieldLengthOptions(randi(length(SeqNumFieldLengthOptions)));
        MaxTxBufferSDUs = MaxTxBufferSDUsOptions(randi(length(MaxTxBufferSDUsOptions)));
        ReassemblyTimer = ReassemblyTimerOptions(randi(length(ReassemblyTimerOptions)));
        EntityType = EntityTypeOptions(randi(length(EntityTypeOptions)));

        % Priority 根据 DataRate 映射
        DataRate = ConfigData.DataRate(i);
        if DataRate == 8000
            Priority = PriorityMap(1);
        elseif DataRate == 3000
            Priority = PriorityMap(2);
        else
            Priority = PriorityMap(3);
        end

        % 随机生成 PBR 和 BSD
        PBR = PBROptions(randi(length(PBROptions)));
        BSD = BSDOptions(randi(length(BSDOptions)));

        % 添加到表格
        newRow = table(RNTI, LogicalChannelID, LCGID, SeqNumFieldLength, ...
                       MaxTxBufferSDUs, ReassemblyTimer, EntityType, ...
                       Priority, PBR, BSD);
        UEConfigData = [UEConfigData; newRow]; %#ok<AGROW>
    end

    % 清空文件内容
    if exist(outputFilePath, 'file')
        delete(outputFilePath); % 删除现有文件
    end

    % 保存生成的配置表为文件
    writetable(UEConfigData, outputFilePath);
    % 保存生成的配置表为文件
    writetable(UEConfigData, outputFilePath);
%     fprintf('用户设备配置文件已生成并保存为 %s\n', outputFilePath);
    fprintf('用户设备配置文件已生成\n');
end

