function res = main()
    clc; close all;
    %% 导入tools
    current_dir = fileparts(mfilename('fullpath'));
    disp(current_dir)

    % 添加工具包所在的目录
    addpath(current_dir);
    % 读取MAT文件
    data = load('5g_nr_simulation_data.mat');
    disp(data)

    envConfig = struct();
    % 创建地图区域
    area = struct();
    area.latitudeTopLeft = data.area.latitudeTopLeft;
    area.longitudeTopLeft = data.area.longitudeTopLeft;
    area.latitudeBottomRight = data.area.latitudeBottomRight;
    area.longitudeBottomRight = data.area.longitudeBottomRight;
    envConfig.area = area;

    % % 创建基站和切片对象
    [gNBs, gNBsMapping] = tools.createNRGNB(data.gNBs);
    [UEs, UEsMapping] = tools.createNRUE(data.UEs);
    envConfig.gNBs = gNBs;
    envConfig.UEs = tools.sortUeByPriority(UEs);
    envConfig.gNBsMapping = gNBsMapping;
    envConfig.UEsMapping = UEsMapping;
    for i = 1:length(gNBs)
        fprintf('gNB %d: %s\n', i, gNBs{i}.toString());
    end
    for i = 1:length(UEs)
        fprintf('UE %d: %s\n', i, envConfig.UEs{i}.toString());
    end

    envConfig.distanceMapping = tools.createUeGnbDistanceMap(UEs, gNBs);
    envConfig.simulationTime = 1;
    envConfig.simulationStep = 1;
    envConfig.allocationStrategy = 'RR';

    % 路径损失
    envConfig.pathLossModel = '5G-NR';   % 5G-NR or fspl
    envConfig.pathLoss = nrPathLossConfig;
    envConfig.pathLoss.Scenario = 'UMa'; % 路径损失方案
    envConfig.pathLoss.EnvironmentHeight = 1;

    envConfig.DelayProfile = 'TDL-A'; %

    % 路径模式
    % 获取信道的kFactor，用来计算SNR
    if contains(envConfig.DelayProfile,'CDL','IgnoreCase',true)   % CDL
        channel = nrCDLChannel;
        channel.DelayProfile = envConfig.DelayProfile;
        chInfo = info(channel);
        kFactor = chInfo.KFactorFirstCluster; % dB
    else % TDL
        channel = nrTDLChannel;
        channel.DelayProfile = envConfig.DelayProfile;
        chInfo = info(channel);
        kFactor = chInfo.KFactorFirstTap; % dB
    end
    envConfig.channel = channel;
    envConfig.LOS = kFactor>-Inf;             % 无线信道是否有LOS
    envConfig.channel.DelaySpread = 3e-8;
    envConfig.channel.MaximumDopplerShift = 5;
    envConfig.channel.ChannelResponseOutput = 'ofdm-response';   % 这个在matlab写死

    % 传输的全局配置，这些最后要使用data.xxx来获取
    envConfig.NFrames = 1; 
    envConfig.DisplaySimulationInformation = true;
    envConfig.NumLayers = 1;
    envConfig.NumHARQProcesses = 16;
    envConfig.EnableHARQ = true;
    envConfig.LDPCDecodingAlgorithm = 'Normalized min-sum';
    envConfig.MaximumLDPCIterationCount = 6;
    envConfig.DataType = 'single';
    envConfig.channelExtension.DelayProfile = envConfig.channel.DelayProfile;
    envConfig.channelExtension.DelaySpread = envConfig.channel.DelaySpread;
    envConfig.channelExtension.MaximumDopplerShift = envConfig.channel.MaximumDopplerShift;
    envConfig.channelExtension.ChannelResponseOutput = envConfig.channel.ChannelResponseOutput;


    env = NetSimuEnv(envConfig);
    env.run();


    res = 'Hello World!';
end
