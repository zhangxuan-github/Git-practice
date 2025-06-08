

% 主脚本：main.m
clc; clear; close all;

% 1. 初始化网络
[numNodes, nodePositions, distanceMatrix] = initialize_network(2000);

% 2. 定义通信模式
% 高速电力线载波通信 HPLC（High-speed Power Line Communications）
% 高速无线通信技术 HRF（High-speed Radio Frequency）
modes = struct(...
    'Mode_5G', struct('Bandwidth', 100e6, 'Latency', 1e-3, 'Range', 1000), ...
    'Mode_HPLC', struct('Bandwidth', 10e3, 'Latency', 10e-3, 'Range', 500), ...
    'Mode_HRF', struct('Bandwidth', 1e6, 'Latency', 5e-3, 'Range', 300));

% 3. 定义业务类型
businessTypes = {'PowerDataCollection', 'DistributionAutomation', 'RenewableControl'};
businessDescriptions = {'用电信息采集', '配电自动化', '新能源调控'}; % 中文描述仅用于输出显示

% 4. 业务场景仿真
results = struct();
for i = 1:length(businessTypes)
    fprintf('正在模拟业务: %s\n', businessDescriptions{i});
    results.(businessTypes{i}) = simulate_communication(...
        numNodes, nodePositions, distanceMatrix, modes, businessTypes{i});
end

% 5. 绘制仿真结果
plot_results(results);
