% 主脚本：main.m
clc; clear; close all;

% 1. 初始化网络（包括用户节点和服务器节点）
[numNodes, numServers, nodePositions, serverPositions, distanceMatrix] = initialize_network_with_servers(2000);

% 2. 定义通信模式
modes = struct(...
    'Mode_5G', struct('Bandwidth', 100e6, 'Latency', 1e-3, 'Range', 1000), ...
    'Mode_HPLC', struct('Bandwidth', 10e3, 'Latency', 10e-3, 'Range', 500), ...
    'Mode_HRF', struct('Bandwidth', 1e6, 'Latency', 5e-3, 'Range', 300));

% 3. 定义业务类型
businessTypes = {'PowerDataCollection', 'DistributionAutomation', 'RenewableControl'};
businessDescriptions = {'用电信息采集', '配电自动化', '新能源调控'}; % 中文描述仅用于输出显示

% 4. 用户需求定义（速率需求、时延需求）
userRequirements = struct();
for i = 1:numNodes
    % 给每种业务定义不同的需求
    userRequirements(i).businessType = businessTypes{mod(i, 3) + 1}; % 随机分配业务类型
    if strcmp(userRequirements(i).businessType, 'PowerDataCollection')
        % 用电信息采集：较低的速率需求和较低的时延需求
        userRequirements(i).rateDemand = randi([1, 10]) * 1e6;  % 1Mbps - 10Mbps
        userRequirements(i).latencyDemand = rand() * 10e-3 + 1e-3;  % 1ms - 10ms
    elseif strcmp(userRequirements(i).businessType, 'DistributionAutomation')
        % 配电自动化：较高的速率需求和中等的时延需求
        userRequirements(i).rateDemand = randi([10, 50]) * 1e6;  % 10Mbps - 50Mbps
        userRequirements(i).latencyDemand = rand() * 20e-3 + 5e-3;  % 5ms - 25ms
    elseif strcmp(userRequirements(i).businessType, 'RenewableControl')
        % 新能源调控：非常高的速率需求和较低的时延需求
        userRequirements(i).rateDemand = randi([50, 100]) * 1e6;  % 50Mbps - 100Mbps
        userRequirements(i).latencyDemand = rand() * 5e-3 + 1e-3;  % 1ms - 5ms
    end
    userRequirements(i).distanceToServer = distanceMatrix(i, numNodes + 1);  % 到服务器的距离
end

% 5. 业务场景仿真
results = struct();
for i = 1:length(businessTypes)
    fprintf('正在模拟业务: %s\n', businessDescriptions{i});
    results.(businessTypes{i}) = simulate_communication_with_server_selection(...
        numNodes, numServers, nodePositions, serverPositions, distanceMatrix, modes, userRequirements, businessTypes{i});
end

% 6. 绘制仿真结果
plot_results(results);
