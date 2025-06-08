%% 5G网络系统级仿真 - 基站、小区、用户与网络切片 (增强时延计算)
% 该代码模拟了5G网络环境下基站、小区、用户与网络切片的交互
% 增加了详细的时延分析，包括传播时延、处理时延、队列时延等

clear all;
close all;
clc;

%% 仿真参数设置
simTime = 1000;           % 仿真总时长(ms)
timeStep = 1;             % 时间步长(ms)

%% 创建基站
numBS = 3;                % 基站数量
BS = struct('ID', {}, 'Position', {}, 'Frequency', {}, 'Bandwidth', {}, ...
            'TxPower', {}, 'AntennaArray', {}, 'Cells', {}, 'SliceList', {}, ...
            'ProcessingDelay', {});

% 基站参数配置
for i = 1:numBS
    BS(i).ID = i;
    
    % 基站位置 [x, y, z] (米)
    BS(i).Position = [500*(i-1), 500*(mod(i-1,2)), 30];
    
    % 频谱范围 (MHz)
    BS(i).Frequency = 3500 + 100*(i-1);  % 3.5GHz开始
    
    % 带宽 (MHz)
    BS(i).Bandwidth = 100;
    
    % 发射功率 (dBm)
    BS(i).TxPower = 46;
    
    % 天线阵列配置 [水平天线数, 垂直天线数]
    BS(i).AntennaArray = [8, 8];
    
    % 基站处理时延 (ms)
    BS(i).ProcessingDelay = 0.5 + 0.2*rand();  % 0.5-0.7ms
    
    % 初始化小区列表
    BS(i).Cells = [];
    
    % 支持的网络切片列表
    BS(i).SliceList = {'eMBB', 'URLLC', 'mMTC'};
    
    % 为每个基站添加小区
    numCellsPerBS = randi([1, 3]); % 每个基站随机1-3个小区
    
    for j = 1:numCellsPerBS
        % 创建小区
        cell = struct();
        cell.ID = (i-1)*3 + j;    % 小区ID
        cell.SectorAngle = (j-1)*120; % 扇区角度 (120度/扇区)
        cell.SectorRange = 120;   % 扇区范围 (度)
        cell.TiltAngle = 10;      % 下倾角 (度)
        cell.MaxUsers = 100;      % 最大用户数
        cell.ActiveUsers = [];    % 当前活跃用户列表
        cell.PRBCount = 275;      % 物理资源块数量 (100MHz带宽对应275个PRB)
        cell.AllocatedPRBs = 0;   % 已分配的PRB数量
        cell.UplinkQueue = [];    % 上行队列
        cell.DownlinkQueue = [];  % 下行队列
        cell.QueueDelay = 0;      % 队列平均时延
        
        % 添加到基站的小区列表
        BS(i).Cells = [BS(i).Cells, cell];
    end
end

%% 创建用户
numUsers = 50;            % 用户数量
Users = struct('ID', {}, 'Position', {}, 'Velocity', {}, 'SliceType', {}, ...
               'TrafficModel', {}, 'ConnectedCellID', {}, 'DataRate', {}, ...
               'Latency', {}, 'QoSRequirement', {}, 'BufferStatus', {}, ...
               'UEProcessingDelay', {}, 'UplinkData', {}, 'DownlinkData', {}, ...
               'LastTransmissionTime', {}, 'RetransmissionCount', {}, ...
               'DetailedLatency', {});

% 用户类型分布 (eMBB, URLLC, mMTC)
userTypeDist = [0.6, 0.3, 0.1]; % 60% eMBB, 30% URLLC, 10% mMTC
sliceTypes = {'eMBB', 'URLLC', 'mMTC'};

% 用户参数配置
for i = 1:numUsers
    Users(i).ID = i;
    
    % 用户位置 [x, y, z] (米) - 随机分布在1500m x 1500m区域内
    Users(i).Position = [rand()*1500, rand()*1500, 1.5];
    
    % 用户移动速度 [vx, vy, vz] (米/秒)
    speed = rand() * 10;  % 0-10 m/s (0-36 km/h)
    direction = rand() * 2 * pi;  % 随机方向 (0-2π)
    Users(i).Velocity = [speed*cos(direction), speed*sin(direction), 0];
    
    % 分配用户切片类型 (基于分布)
    r = rand();
    cumProb = 0;
    for j = 1:length(userTypeDist)
        cumProb = cumProb + userTypeDist(j);
        if r <= cumProb
            Users(i).SliceType = sliceTypes{j};
            break;
        end
    end
    
    % 根据切片类型设置流量模型和QoS要求
    switch Users(i).SliceType
        case 'eMBB'
            Users(i).TrafficModel = 'FullBuffer';  % 总是有数据传输
            Users(i).QoSRequirement.MinDataRate = 50;  % 最小50Mbps
            Users(i).QoSRequirement.MaxLatency = 100;  % 最大100ms延迟
            Users(i).UEProcessingDelay = 2 + rand();   % 2-3ms
            
        case 'URLLC'
            Users(i).TrafficModel = 'SporadicBurst';  % 突发性流量
            Users(i).QoSRequirement.MinDataRate = 10;  % 最小10Mbps
            Users(i).QoSRequirement.MaxLatency = 1;    % 最大1ms延迟
            Users(i).UEProcessingDelay = 0.1 + 0.1*rand();  % 0.1-0.2ms
            
        case 'mMTC'
            Users(i).TrafficModel = 'Periodic';  % 周期性流量
            Users(i).QoSRequirement.MinDataRate = 0.1;  % 最小0.1Mbps
            Users(i).QoSRequirement.MaxLatency = 1000;  % 最大1000ms延迟
            Users(i).UEProcessingDelay = 1 + rand();    % 1-2ms
    end
    
    % 初始化连接和性能指标
    Users(i).ConnectedCellID = -1;  % 未连接状态
    Users(i).DataRate = 0;
    Users(i).Latency = Inf;
    Users(i).BufferStatus = 0;  % 初始缓冲区为空
    Users(i).UplinkData = 0;    % 上行数据
    Users(i).DownlinkData = 0;  % 下行数据
    Users(i).LastTransmissionTime = 0;
    Users(i).RetransmissionCount = 0;
    
    % 详细时延分析结构
    Users(i).DetailedLatency = struct();
    Users(i).DetailedLatency.PropagationDelay = 0;  % 传播时延
    Users(i).DetailedLatency.ProcessingDelay = 0;   % 处理时延
    Users(i).DetailedLatency.QueueingDelay = 0;     % 队列时延
    Users(i).DetailedLatency.AccessDelay = 0;       % 接入时延
    Users(i).DetailedLatency.ProtocolDelay = 0;     % 协议时延
    Users(i).DetailedLatency.RetransmissionDelay = 0; % 重传时延
    Users(i).DetailedLatency.TotalDelay = 0;        % 总时延
end

%% 初始化性能统计变量
% 按切片类型统计
sliceStats = struct();
for i = 1:length(sliceTypes)
    sliceType = sliceTypes{i};
    sliceStats.(sliceType).AvgDataRate = 0;
    sliceStats.(sliceType).AvgLatency = 0;
    sliceStats.(sliceType).NumUsers = 0;
    sliceStats.(sliceType).SatisfiedUsers = 0;  % QoS满足的用户数
    
    % 详细时延统计
    sliceStats.(sliceType).DetailedLatency = struct();
    sliceStats.(sliceType).DetailedLatency.PropagationDelay = 0;
    sliceStats.(sliceType).DetailedLatency.ProcessingDelay = 0;
    sliceStats.(sliceType).DetailedLatency.QueueingDelay = 0;
    sliceStats.(sliceType).DetailedLatency.AccessDelay = 0;
    sliceStats.(sliceType).DetailedLatency.ProtocolDelay = 0;
    sliceStats.(sliceType).DetailedLatency.RetransmissionDelay = 0;
end

% 整体网络统计
cellCount = sum(arrayfun(@(x) length(x.Cells), BS));
networkStats = struct('AvgDataRate', 0, 'AvgLatency', 0, 'ConnectedUsers', 0, ...
                      'SatisfiedUsers', 0, 'CellLoad', zeros(1, cellCount));

%% 绘制初始网络拓扑
figure('Name', '5G网络拓扑');
hold on;
grid on;
title('5G网络拓扑 - 基站、小区和用户分布');
xlabel('X (米)');
ylabel('Y (米)');

% 绘制基站和小区
for i = 1:numBS
    % 绘制基站
    plot3(BS(i).Position(1), BS(i).Position(2), BS(i).Position(3), 'rs', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    text(BS(i).Position(1), BS(i).Position(2), BS(i).Position(3)+10, ['BS-', num2str(i)]);
    
    % 绘制小区覆盖范围
    for j = 1:length(BS(i).Cells)
        cell = BS(i).Cells(j);
        
        % 计算扇区边界
        startAngle = cell.SectorAngle - cell.SectorRange/2;
        endAngle = cell.SectorAngle + cell.SectorRange/2;
        angles = linspace(startAngle, endAngle, 50) * pi/180;
        
        % 扇区覆盖范围
        coverage = 500;  % 500米覆盖半径
        
        % 绘制扇区
        x = BS(i).Position(1) + coverage * cos(angles);
        y = BS(i).Position(2) + coverage * sin(angles);
        fill([BS(i).Position(1), x], [BS(i).Position(2), y], 'c', 'FaceAlpha', 0.2);
    end
end

% 绘制用户
userColors = containers.Map(sliceTypes, {'b', 'g', 'm'});
for i = 1:numUsers
    color = userColors(Users(i).SliceType);
    plot(Users(i).Position(1), Users(i).Position(2), '.', 'Color', color, 'MarkerSize', 10);
end

% 添加图例
legend('基站', 'eMBB用户', 'URLLC用户', 'mMTC用户', 'Location', 'Best');

%% 仿真主循环
figure('Name', '实时性能指标', 'Position', [100, 100, 1200, 800]);
dataRateHistory = zeros(length(sliceTypes), round(simTime/timeStep));
latencyHistory = zeros(length(sliceTypes), round(simTime/timeStep));
detailedLatencyHistory = zeros(length(sliceTypes), 6, round(simTime/timeStep)); % 6个时延组件
satisfactionHistory = zeros(length(sliceTypes), round(simTime/timeStep));

for t = 1:timeStep:simTime
    fprintf('仿真时间: %d ms (%.1f%%完成)\n', t, 100*t/simTime);
    
    % 更新用户位置
    for i = 1:numUsers
        % 更新位置
        Users(i).Position = Users(i).Position + Users(i).Velocity * (timeStep/1000);
        
        % 保持在仿真区域内
        Users(i).Position(1) = mod(Users(i).Position(1), 1500);
        Users(i).Position(2) = mod(Users(i).Position(2), 1500);
    end
    
    % 用户小区选择与连接
    for i = 1:numUsers
        % 如果用户未连接或需要重新选择小区
        if Users(i).ConnectedCellID == -1 || mod(t, 100) == 0
            bestRSRP = -Inf;
            bestCellID = -1;
            
            % 遍历所有基站和小区
            for b = 1:numBS
                % 检查基站是否支持用户请求的切片
                if ~ismember(Users(i).SliceType, BS(b).SliceList)
                    continue;
                end
                
                for c = 1:length(BS(b).Cells)
                    cell = BS(b).Cells(c);
                    
                    % 计算用户到基站的距离
                    distance = norm(Users(i).Position - BS(b).Position);
                    
                    % 检查用户是否在小区扇区覆盖范围内
                    userAngle = atan2(Users(i).Position(2) - BS(b).Position(2), ...
                                      Users(i).Position(1) - BS(b).Position(1)) * 180/pi;
                    if userAngle < 0
                        userAngle = userAngle + 360;
                    end
                    
                    angleDiff = abs(mod(userAngle - cell.SectorAngle + 180, 360) - 180);
                    
                    if angleDiff <= cell.SectorRange/2
                        % 计算接收信号强度
                        pathLoss = 128.1 + 37.6 * log10(max(distance, 10)/1000);
                        antennaGain = 14;
                        angleLoss = 12 * (angleDiff / (cell.SectorRange/2))^2;
                        rsrp = BS(b).TxPower + antennaGain - pathLoss - angleLoss;
                        
                        if rsrp > bestRSRP
                            bestRSRP = rsrp;
                            bestCellID = cell.ID;
                        end
                    end
                end
            end
            
            % 更新用户连接
            if bestCellID ~= -1
                % 处理切换
                if Users(i).ConnectedCellID ~= -1
                    [oldBS, oldCellIdx] = findCell(BS, Users(i).ConnectedCellID);
                    if ~isempty(oldBS)
                        oldBS.Cells(oldCellIdx).ActiveUsers = ...
                            oldBS.Cells(oldCellIdx).ActiveUsers(oldBS.Cells(oldCellIdx).ActiveUsers ~= i);
                    end
                end
                
                Users(i).ConnectedCellID = bestCellID;
                [newBS, newCellIdx] = findCell(BS, bestCellID);
                if ~isempty(newBS)
                    newBS.Cells(newCellIdx).ActiveUsers = ...
                        [newBS.Cells(newCellIdx).ActiveUsers, i];
                end
            end
        end
    end
    
    % 生成用户业务和计算详细时延
    for i = 1:numUsers
        if Users(i).ConnectedCellID ~= -1
            [connectedBS, cellIdx] = findCell(BS, Users(i).ConnectedCellID);
            
            % 计算传播时延
            distance = norm(Users(i).Position - connectedBS.Position);
            propagationDelay = distance / (3e8) * 1000;  % 光速传播时延 (ms)
            Users(i).DetailedLatency.PropagationDelay = propagationDelay;
            
            % 计算处理时延
            processingDelay = connectedBS.ProcessingDelay + Users(i).UEProcessingDelay;
            Users(i).DetailedLatency.ProcessingDelay = processingDelay;
            
            % 计算接入时延 (随机接入和调度等待)
            switch Users(i).SliceType
                case 'URLLC'
                    accessDelay = 0.2 + 0.1*rand();  % 0.2-0.3ms
                case 'eMBB'
                    accessDelay = 1 + 2*rand();      % 1-3ms
                case 'mMTC'
                    accessDelay = 5 + 5*rand();      % 5-10ms
            end
            Users(i).DetailedLatency.AccessDelay = accessDelay;
            
            % 计算协议时延 (L1/L2/L3处理)
            switch Users(i).SliceType
                case 'URLLC'
                    protocolDelay = 0.1 + 0.1*rand();  % 0.1-0.2ms
                case 'eMBB'
                    protocolDelay = 0.5 + 0.5*rand();  % 0.5-1ms
                case 'mMTC'
                    protocolDelay = 1 + 1*rand();      % 1-2ms
            end
            Users(i).DetailedLatency.ProtocolDelay = protocolDelay;
            
            % 生成数据
            switch Users(i).TrafficModel
                case 'FullBuffer'
                    Users(i).UplinkData = Users(i).UplinkData + 2;
                    Users(i).DownlinkData = Users(i).DownlinkData + 2;
                    
                case 'SporadicBurst'
                    if rand() < 0.05
                        Users(i).UplinkData = Users(i).UplinkData + 0.5;
                        Users(i).DownlinkData = Users(i).DownlinkData + 0.5;
                    end
                    
                case 'Periodic'
                    if mod(t, 100) == 0
                        Users(i).UplinkData = Users(i).UplinkData + 0.01;
                        Users(i).DownlinkData = Users(i).DownlinkData + 0.01;
                    end
            end
        end
    end
    
    % 处理队列和数据传输
    for b = 1:numBS
        for c = 1:length(BS(b).Cells)
            cell = BS(b).Cells(c);
            activeUsers = cell.ActiveUsers;
            
            if ~isempty(activeUsers)
                % 更新队列时延
                queueSize = length(cell.UplinkQueue) + length(cell.DownlinkQueue);
                queueDelay = queueSize * 0.5;  % 简化模型：每个队列项0.5ms延迟
                
                for u = 1:length(activeUsers)
                    userID = activeUsers(u);
                    Users(userID).DetailedLatency.QueueingDelay = queueDelay;
                    
                    % 计算SINR和数据率
                    distance = norm(Users(userID).Position - BS(b).Position);
                    pathLoss = 128.1 + 37.6 * log10(max(distance, 10)/1000);
                    
                    % 考虑干扰
                    interference = 0;
                    for other_b = 1:numBS
                        if other_b ~= b
                            other_distance = norm(Users(userID).Position - BS(other_b).Position);
                            other_pathLoss = 128.1 + 37.6 * log10(max(other_distance, 10)/1000);
                            interference = interference + 10^((BS(other_b).TxPower - other_pathLoss)/10);
                        end
                    end
                    
                    noise_power = 10^((-174 + 10*log10(BS(b).Bandwidth * 1e6))/10);
                    signal_power = 10^((BS(b).TxPower - pathLoss)/10);
                    sinr_linear = signal_power / (noise_power + interference);
                    sinr_dB = 10*log10(sinr_linear);
                    
                    % 计算误码率
                    switch Users(userID).SliceType
                        case 'URLLC'
                            bler = 0.00001;  % 极低误码率
                        case 'eMBB'
                            bler = 0.001;    % 一般误码率
                        case 'mMTC'
                            bler = 0.01;     % 较高误码率可接受
                    end
                    
                    % 计算重传时延
                    if rand() < bler && t - Users(userID).LastTransmissionTime > 10
                        Users(userID).RetransmissionCount = Users(userID).RetransmissionCount + 1;
                        Users(userID).LastTransmissionTime = t;
                        
                        % 重传时延 (HARQ)
                        switch Users(userID).SliceType
                            case 'URLLC'
                                retransDelay = 1;  % 1ms
                            case 'eMBB'
                                retransDelay = 8;  % 8ms
                            case 'mMTC'
                                retransDelay = 16; % 16ms
                        end
                        Users(userID).DetailedLatency.RetransmissionDelay = retransDelay;
                    else
                        Users(userID).DetailedLatency.RetransmissionDelay = 0;
                    end
                    
                    % 计算谱效率和数据率
                    spectralEfficiency = min(7, log2(1 + sinr_linear));
                    
                    % 分配PRB
                    sliceUsers = activeUsers(strcmp({Users(activeUsers).SliceType}, Users(userID).SliceType));
                    
                    switch Users(userID).SliceType
                        case 'URLLC'
                            prbPerUser = min(20, cell.PRBCount / length(sliceUsers));
                        case 'eMBB'
                            prbPerUser = min(50, cell.PRBCount / length(sliceUsers));
                        case 'mMTC'
                            prbPerUser = min(5, cell.PRBCount / length(sliceUsers));
                    end
                    
                    allocatedBandwidth = prbPerUser * 12 * 15 * 1e3;
                    dataRate = spectralEfficiency * allocatedBandwidth / 1e6;
                    Users(userID).DataRate = dataRate;
                    
                    % 处理数据传输
                    totalData = Users(userID).UplinkData + Users(userID).DownlinkData;
                    transferredData = min(totalData, dataRate * timeStep / 1000);
                    
                    % 分配给上行和下行
                    uplinkTransfer = min(Users(userID).UplinkData, transferredData/2);
                    downlinkTransfer = min(Users(userID).DownlinkData, transferredData - uplinkTransfer);
                    
                    Users(userID).UplinkData = Users(userID).UplinkData - uplinkTransfer;
                    Users(userID).DownlinkData = Users(userID).DownlinkData - downlinkTransfer;
                    
                    % 计算总时延
                    totalLatency = Users(userID).DetailedLatency.PropagationDelay + ...
                                   Users(userID).DetailedLatency.ProcessingDelay + ...
                                   Users(userID).DetailedLatency.QueueingDelay + ...
                                   Users(userID).DetailedLatency.AccessDelay + ...
                                   Users(userID).DetailedLatency.ProtocolDelay + ...
                                   Users(userID).DetailedLatency.RetransmissionDelay;
                    
                    Users(userID).DetailedLatency.TotalDelay = totalLatency;
                    Users(userID).Latency = totalLatency;
                end
            end
        end
    end
    
    % 更新统计
    for s = 1:length(sliceTypes)
        sliceType = sliceTypes{s};
        sliceStats.(sliceType).AvgDataRate = 0;
        sliceStats.(sliceType).AvgLatency = 0;
        sliceStats.(sliceType).NumUsers = 0;
        sliceStats.(sliceType).SatisfiedUsers = 0;
        
        % 重置详细时延统计
        fields = fieldnames(sliceStats.(sliceType).DetailedLatency);
        for f = 1:length(fields)
            sliceStats.(sliceType).DetailedLatency.(fields{f}) = 0;
        end
    end
    
    % 计算统计
    for i = 1:numUsers
        sliceType = Users(i).SliceType;
        
        if Users(i).ConnectedCellID ~= -1
            sliceStats.(sliceType).AvgDataRate = sliceStats.(sliceType).AvgDataRate + Users(i).DataRate;
            sliceStats.(sliceType).AvgLatency = sliceStats.(sliceType).AvgLatency + Users(i).Latency;
            sliceStats.(sliceType).NumUsers = sliceStats.(sliceType).NumUsers + 1;
            
            % 详细时延统计
            sliceStats.(sliceType).DetailedLatency.PropagationDelay = ...
                sliceStats.(sliceType).DetailedLatency.PropagationDelay + Users(i).DetailedLatency.PropagationDelay;
            sliceStats.(sliceType).DetailedLatency.ProcessingDelay = ...
                sliceStats.(sliceType).DetailedLatency.ProcessingDelay + Users(i).DetailedLatency.ProcessingDelay;
            sliceStats.(sliceType).DetailedLatency.QueueingDelay = ...
                sliceStats.(sliceType).DetailedLatency.QueueingDelay + Users(i).DetailedLatency.QueueingDelay;
            sliceStats.(sliceType).DetailedLatency.AccessDelay = ...
                sliceStats.(sliceType).DetailedLatency.AccessDelay + Users(i).DetailedLatency.AccessDelay;
            sliceStats.(sliceType).DetailedLatency.ProtocolDelay = ...
                sliceStats.(sliceType).DetailedLatency.ProtocolDelay + Users(i).DetailedLatency.ProtocolDelay;
            sliceStats.(sliceType).DetailedLatency.RetransmissionDelay = ...
                sliceStats.(sliceType).DetailedLatency.RetransmissionDelay + Users(i).DetailedLatency.RetransmissionDelay;
            
            % 检查QoS满足情况
            if Users(i).DataRate >= Users(i).QoSRequirement.MinDataRate && ...
               Users(i).Latency <= Users(i).QoSRequirement.MaxLatency
                sliceStats.(sliceType).SatisfiedUsers = sliceStats.(sliceType).SatisfiedUsers + 1;
            end
        end
    end
    
    % 计算平均值
    for s = 1:length(sliceTypes)
        sliceType = sliceTypes{s};
        if sliceStats.(sliceType).NumUsers > 0
            sliceStats.(sliceType).AvgDataRate = sliceStats.(sliceType).AvgDataRate / sliceStats.(sliceType).NumUsers;
            sliceStats.(sliceType).AvgLatency = sliceStats.(sliceType).AvgLatency / sliceStats.(sliceType).NumUsers;
            
            % 平均化详细时延
            fields = fieldnames(sliceStats.(sliceType).DetailedLatency);
            for f = 1:length(fields)
                sliceStats.(sliceType).DetailedLatency.(fields{f}) = ...
                    sliceStats.(sliceType).DetailedLatency.(fields{f}) / sliceStats.(sliceType).NumUsers;
            end
        end
        
        % 记录历史数据
        tIdx = round(t/timeStep);
        dataRateHistory(s, tIdx) = sliceStats.(sliceType).AvgDataRate;
        latencyHistory(s, tIdx) = sliceStats.(sliceType).AvgLatency;
        
        % 记录详细时延历史
        detailedLatencyHistory(s, 1, tIdx) = sliceStats.(sliceType).DetailedLatency.PropagationDelay;
        detailedLatencyHistory(s, 2, tIdx) = sliceStats.(sliceType).DetailedLatency.ProcessingDelay;
        detailedLatencyHistory(s, 3, tIdx) = sliceStats.(sliceType).DetailedLatency.QueueingDelay;
        detailedLatencyHistory(s, 4, tIdx) = sliceStats.(sliceType).DetailedLatency.AccessDelay;
        detailedLatencyHistory(s, 5, tIdx) = sliceStats.(sliceType).DetailedLatency.ProtocolDelay;
        detailedLatencyHistory(s, 6, tIdx) = sliceStats.(sliceType).DetailedLatency.RetransmissionDelay;
        
        if sliceStats.(sliceType).NumUsers > 0
            satisfactionHistory(s, tIdx) = sliceStats.(sliceType).SatisfiedUsers / sliceStats.(sliceType).NumUsers * 100;
        else
            satisfactionHistory(s, tIdx) = 0;
        end
    end
    
    % 动态绘制性能指标
    if mod(t, 100) == 0
        clf;
        
        % 绘制时延分解
        subplot(2, 2, 1);
        timeAxis = 1:timeStep:t;
        hold on;
        for s = 1:length(sliceTypes)
            plot(timeAxis, latencyHistory(s, 1:length(timeAxis)), 'LineWidth', 2);
        end
        grid on;
        xlabel('仿真时间 (ms)');
        ylabel('总时延 (ms)');
        title('不同切片的总时延');
        legend(sliceTypes, 'Location', 'Best');
        
        % 绘制时延分解柱状图 (当前时刻)
        subplot(2, 2, 2);
        if sliceStats.(sliceTypes{1}).NumUsers > 0
            delayComponents = {'传播时延', '处理时延', '队列时延', '接入时延', '协议时延', '重传时延'};
            delayMatrix = zeros(length(sliceTypes), 6);
            
            for s = 1:length(sliceTypes)
                sliceType = sliceTypes{s};
                if sliceStats.(sliceType).NumUsers > 0
                    delayMatrix(s, :) = [
                        sliceStats.(sliceType).DetailedLatency.PropagationDelay, ...
                        sliceStats.(sliceType).DetailedLatency.ProcessingDelay, ...
                        sliceStats.(sliceType).DetailedLatency.QueueingDelay, ...
                        sliceStats.(sliceType).DetailedLatency.AccessDelay, ...
                        sliceStats.(sliceType).DetailedLatency.ProtocolDelay, ...
                        sliceStats.(sliceType).DetailedLatency.RetransmissionDelay
                    ];
                end
            end
            
            bar(delayMatrix, 'stacked');
            set(gca, 'XTickLabel', sliceTypes);
            xlabel('切片类型');
            ylabel('时延 (ms)');
            title('时延组成分解');
            legend(delayComponents, 'Location', 'Best', 'FontSize', 8);
        end
        
        % 绘制数据率
        subplot(2, 2, 3);
        hold on;
        for s = 1:length(sliceTypes)
            plot(timeAxis, dataRateHistory(s, 1:length(timeAxis)), 'LineWidth', 2);
        end
        grid on;
        xlabel('仿真时间 (ms)');
        ylabel('平均数据率 (Mbps)');
        title('不同切片的平均数据率');
        legend(sliceTypes, 'Location', 'Best');
        
        % 绘制QoS满足率
        subplot(2, 2, 4);
        hold on;
        for s = 1:length(sliceTypes)
            plot(timeAxis, satisfactionHistory(s, 1:length(timeAxis)), 'LineWidth', 2);
        end
        grid on;
        xlabel('仿真时间 (ms)');
        ylabel('QoS满足率 (%)');
        title('不同切片的QoS满足率');
        legend(sliceTypes, 'Location', 'Best');
        ylim([0, 100]);
        
        drawnow;
    end
end

%% 最终性能分析
fprintf('\n==== 仿真结果总结 ====\n');
fprintf('切片类型\t平均数据率(Mbps)\t平均总时延(ms)\t用户数\tQoS满足率(%%)\n');
for s = 1:length(sliceTypes)
    sliceType = sliceTypes{s};
    fprintf('%s\t\t%.2f\t\t\t%.2f\t\t%d\t%.2f\n', sliceType, ...
            sliceStats.(sliceType).AvgDataRate, sliceStats.(sliceType).AvgLatency, ...
            sliceStats.(sliceType).NumUsers, ...
            100 * sliceStats.(sliceType).SatisfiedUsers / max(1, sliceStats.(sliceType).NumUsers));
end

fprintf('\n==== 详细时延分析 ====\n');
fprintf('切片类型\t传播(ms)\t处理(ms)\t队列(ms)\t接入(ms)\t协议(ms)\t重传(ms)\t总计(ms)\n');
for s = 1:length(sliceTypes)
    sliceType = sliceTypes{s};
    if sliceStats.(sliceType).NumUsers > 0
        fprintf('%s\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\t\t%.3f\n', ...
                sliceType, ...
                sliceStats.(sliceType).DetailedLatency.PropagationDelay, ...
                sliceStats.(sliceType).DetailedLatency.ProcessingDelay, ...
                sliceStats.(sliceType).DetailedLatency.QueueingDelay, ...
                sliceStats.(sliceType).DetailedLatency.AccessDelay, ...
                sliceStats.(sliceType).DetailedLatency.ProtocolDelay, ...
                sliceStats.(sliceType).DetailedLatency.RetransmissionDelay, ...
                sliceStats.(sliceType).AvgLatency);
    end
end

% 计算整体网络统计
connectedUsers = sum([sliceStats.(sliceTypes{1}).NumUsers, sliceStats.(sliceTypes{2}).NumUsers, sliceStats.(sliceTypes{3}).NumUsers]);
satisfiedUsers = sum([sliceStats.(sliceTypes{1}).SatisfiedUsers, sliceStats.(sliceTypes{2}).SatisfiedUsers, sliceStats.(sliceTypes{3}).SatisfiedUsers]);

fprintf('\n网络整体性能:\n');
fprintf('连接用户数: %d/%d\n', connectedUsers, numUsers);
fprintf('QoS满足率: %.2f%%\n', 100 * satisfiedUsers / max(1, connectedUsers));

%% 绘制时延分解饼图
figure('Name', '时延组成分析');
for s = 1:length(sliceTypes)
    subplot(1, 3, s);
    sliceType = sliceTypes{s};
    
    if sliceStats.(sliceType).NumUsers > 0
        delays = [
            sliceStats.(sliceType).DetailedLatency.PropagationDelay, ...
            sliceStats.(sliceType).DetailedLatency.ProcessingDelay, ...
            sliceStats.(sliceType).DetailedLatency.QueueingDelay, ...
            sliceStats.(sliceType).DetailedLatency.AccessDelay, ...
            sliceStats.(sliceType).DetailedLatency.ProtocolDelay, ...
            sliceStats.(sliceType).DetailedLatency.RetransmissionDelay
        ];
        labels = {'传播时延', '处理时延', '队列时延', '接入时延', '协议时延', '重传时延'};
        
        pie(delays, labels);
        title([sliceType, ' 切片时延组成']);
    end
end

%% 辅助函数 - 查找指定ID的小区
function [bs, cellIdx] = findCell(BSList, cellID)
    bs = [];
    cellIdx = [];
    
    for b = 1:length(BSList)
        for c = 1:length(BSList(b).Cells)
            if BSList(b).Cells(c).ID == cellID
                bs = BSList(b);
                cellIdx = c;
                return;
            end
        end
    end
end