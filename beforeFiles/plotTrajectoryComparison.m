function plotTrajectoryComparison(results)
% PLOTTRAJECTORYCOMPARISON 绘制不同轨迹模式的性能对比图
% 输入参数:
%   results - 包含各轨迹模式性能指标的结构体数组
%
% 示例结构:
% results(i).mode_name = '圆周运动';  % 轨迹模式名称
% results(i).avg_rx_power = -70;      % 平均接收功率 (dBm)
% results(i).min_rx_power = -80;      % 最小接收功率 (dBm)
% results(i).avg_snr = 25;            % 平均信噪比 (dB)
% results(i).min_snr = 15;            % 最小信噪比 (dB)
% results(i).avg_misalignment = 2;    % 平均波束对准误差 (度)
% results(i).max_misalignment = 5;    % 最大波束对准误差 (度)

% 检查输入参数
if isempty(results)
    error('输入结果结构体不能为空');
end

% 提取数据
n_modes = length(results);
mode_names = cell(1, n_modes);
avg_rx_power = zeros(1, n_modes);
min_rx_power = zeros(1, n_modes);
avg_snr = zeros(1, n_modes);
min_snr = zeros(1, n_modes);
avg_misalignment = zeros(1, n_modes);
max_misalignment = zeros(1, n_modes);

for i = 1:n_modes
    mode_names{i} = results(i).mode_name;
    avg_rx_power(i) = results(i).avg_rx_power;
    min_rx_power(i) = results(i).min_rx_power;
    avg_snr(i) = results(i).avg_snr;
    min_snr(i) = results(i).min_snr;
    avg_misalignment(i) = results(i).avg_misalignment;
    max_misalignment(i) = results(i).max_misalignment;
end

% 创建图形
figure('Position', [100, 100, 1200, 800], 'Name', '轨迹模式性能对比');

% 1. 接收功率对比
subplot(2, 3, 1);
bar_data = [avg_rx_power; min_rx_power]';
bar(bar_data);
set(gca, 'XTickLabel', mode_names);
legend('平均接收功率', '最小接收功率');
ylabel('接收功率 (dBm)');
title('接收功率对比');
grid on;

% 2. SNR对比
subplot(2, 3, 2);
bar_data = [avg_snr; min_snr]';
bar(bar_data);
set(gca, 'XTickLabel', mode_names);
legend('平均SNR', '最小SNR');
ylabel('SNR (dB)');
title('信噪比对比');
grid on;

% 3. 波束对准误差对比
subplot(2, 3, 3);
bar_data = [avg_misalignment; max_misalignment]';
bar(bar_data);
set(gca, 'XTickLabel', mode_names);
legend('平均误差', '最大误差');
ylabel('波束对准误差 (度)');
title('波束对准误差对比');
grid on;

% 4. 综合性能雷达图
subplot(2, 3, [4, 5, 6]);
% 标准化数据以便于雷达图显示
% 接收功率 - 越高越好，取负值后越低越好
norm_avg_power = normalize_inverse(avg_rx_power);
% SNR - 越高越好
norm_avg_snr = normalize_direct(avg_snr);
% 误差 - 越低越好，取负值后越高越好
norm_avg_error = normalize_inverse(avg_misalignment);

% 准备雷达图数据
radar_data = [norm_avg_power; norm_avg_snr; norm_avg_error]';
categories = {'接收功率', 'SNR', '波束对准精度'};

% 绘制雷达图
radarplot(radar_data, categories, mode_names);
title('各轨迹模式综合性能对比');

% 添加总体标题
sgtitle('不同轨迹模式性能对比分析');

% 添加图表说明
annotation('textbox', [0.1, 0.01, 0.8, 0.04], ...
    'String', {'说明: 雷达图中心为低性能区域，外围为高性能区域。各指标已标准化处理。'}, ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'center');

end

% 辅助函数：绘制雷达图
function radarplot(data, categories, legendLabels)
% 获取数据维度
[num_samples, num_categories] = size(data);

% 计算角度
theta = linspace(0, 2*pi, num_categories+1);
theta = theta(1:end-1);

% 重复最后一个点以闭合多边形
data_plot = [data, data(:,1)];
theta_plot = [theta, theta(1)];

% 设置图形属性
colors = lines(num_samples);
markers = {'o', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};

% 创建雷达图
polarplot(repmat(theta_plot, num_samples, 1)', [data_plot, data_plot(:,1)]', 'LineWidth', 2);
hold on;

% 添加点标记
for i = 1:num_samples
    for j = 1:num_categories
        polarplot(theta(j), data(i,j), markers{mod(i-1, length(markers))+1}, ...
            'MarkerSize', 8, 'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', colors(i,:));
    end
end

% 设置极坐标网格和标签
rlim([0 1]);
thetaticks(theta * 180/pi);
thetaticklabels(categories);
rticks(0:0.2:1);
rticklabels({});
legend(legendLabels, 'Location', 'southoutside', 'Orientation', 'horizontal');
grid on;

end

% 辅助函数：标准化 - 高值更好
function normalized = normalize_direct(values)
min_val = min(values);
max_val = max(values);
if max_val == min_val
    normalized = ones(size(values));
else
    normalized = (values - min_val) / (max_val - min_val);
end
end

% 辅助函数：标准化 - 低值更好
function normalized = normalize_inverse(values)
min_val = min(values);
max_val = max(values);
if max_val == min_val
    normalized = ones(size(values));
else
    normalized = 1 - (values - min_val) / (max_val - min_val);
end
end