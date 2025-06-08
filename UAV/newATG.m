function newATG(varargin)
close all;
clc;

% 初始化仿真参数和数据结构
[bs_position, bs_antennas, beam_width, carrier_freq, wavelength, tx_power_dBm, tx_power, ...
 beam_tracking_delay, sim_time, dt, time_steps, data_rate, comm_distance, ...
 interference_suppression, uav_nums, uav_initial_position, uav_speed, ...
 uav_flight_radius, uav_height, random_step_size, change_direction_prob, ...
 noise_floor_dBm, path_loss_exponent, shadow_fading_std,visual_beams] = initializeSimulation();

if isempty(bs_position)
    disp('用户取消了输入！');
    return;
end   

%% 速度分布选择模块 - 先执行速度模式选择
% 调用速度分布初始化函数
[uav_speed, velocity_distribution_modes] = initializeVelocityDistribution(uav_nums, uav_speed);

%% 轨迹模式选择模块
% 初始化无人机特定轨迹模式数组
uav_trajectory_modes = zeros(uav_nums, 1);

% 添加随机轨迹分配选项到对话框
choice = questdlg('为无人机选择轨迹分配方法?', ...
                 '轨迹分配', ...
                 '每架单独选择', '全局统一模式', '随机分配', '随机分配');

% 轨迹模式分配逻辑分支
switch choice
    case '每架单独选择'
        % 为每个无人机实体调用单独的模式选择函数
        for i = 1:uav_nums
            uav_trajectory_modes(i) = selectTrajectoryForUAV(i);
        end
        
    case '全局统一模式'
        % 调用全局模式选择器并进行广播赋值
        global_mode = selectTrajectoryForUAV(-1);
        uav_trajectory_modes(:) = global_mode;
        
    case '随机分配'
        % 以离散均匀分布从模式空间进行随机采样
        mode_count = 4;  % 模式空间基数 |M| = 4
        % 实现随机分配的全随机策略
        for i = 1:uav_nums
            % 从离散均匀分布 U(1,mode_count) 中采样
            uav_trajectory_modes(i) = randi(mode_count);
        end
        
        % 将选定的模式输出到控制台以便调试
        mode_names = {'圆周运动', '直线运动', '8字形轨迹', '随机轨迹'};
        fprintf('\n随机分配的轨迹模式:\n');
        for i = 1:uav_nums
            fprintf('无人机 %d: %s\n', i, mode_names{uav_trajectory_modes(i)});
        end
    otherwise
        % 默认情况下实现随机分配
        for i = 1:uav_nums
            uav_trajectory_modes(i) = randi(4);  % 默认随机采样
        end
end

%% 初始化无人机位置
% 初始化多个无人机的位置数组 - 使用随机位置
uav_positions = zeros(uav_nums, 3);
for i = 1:uav_nums
    % 随机生成初始位置 (x, y 平面内随机，z轴固定高度)
    uav_positions(i,:) = [
        rand(1) * 200 - 100,  % x: -100 到 100 范围内随机
        rand(1) * 200 - 100,  % y: -100 到 100 范围内随机
        uav_height + rand(1) * 20  % z: 在基本高度上增加一些随机变化
    ];
end

%% 初始化数据存储结构
% 为每个无人机创建单独的轨迹和性能指标数组
uav_trajectories = zeros(time_steps, uav_nums, 3);  % [时间步, 无人机编号, xyz坐标]
distances = zeros(time_steps, uav_nums);            % [时间步, 无人机编号]
beam_directions = zeros(time_steps, uav_nums, 2);   % [时间步, 无人机编号, 方位角/仰角]
received_powers = zeros(time_steps, uav_nums);      % [时间步, 无人机编号]
snrs = zeros(time_steps, uav_nums);                 % [时间步, 无人机编号]
beam_misalignments = zeros(time_steps, uav_nums);   % [时间步, 无人机编号]

% 初始化多无人机的波束跟踪缓冲区
tracking_buffers = zeros(beam_tracking_delay, uav_nums, 2);  % [延迟步数, 无人机编号, 方位/仰角]
for i = 1:uav_nums
    [init_az, init_el] = calculateBeamDirection(bs_position, uav_positions(i,:));
    tracking_buffers(:, i, :) = repmat([init_az, init_el], beam_tracking_delay, 1);
end

% 初始化波束方向数组（每个波束对应一个无人机）
multi_beam_directions = zeros(time_steps, uav_nums, 2);  % [时间步, 无人机编号/波束编号, 方位/仰角]
multi_beam_gains = zeros(time_steps, uav_nums);          % [时间步, 无人机编号/波束编号]

% 初始化随机轨迹的方向向量
current_directions = zeros(uav_nums, 3);
for i = 1:uav_nums
    current_directions(i,:) = [rand(1)-0.5, rand(1)-0.5, (rand(1)-0.5)*0.2];
    current_directions(i,:) = current_directions(i,:) / norm(current_directions(i,:));
end

%% 时间参数系统初始化
time_vector = (0:time_steps-1) * dt;  % 时间向量，从0开始，每步增加dt

%% 存储第一帧的初始位置
for uav_idx = 1:uav_nums
    uav_trajectories(1, uav_idx, :) = uav_positions(uav_idx,:);
end

%% 主仿真循环
mode_names = {'圆周运动', '直线运动', '8字形轨迹', '随机轨迹'};
colors = hsv(uav_nums); % 定义颜色映射，使每个无人机有独特的颜色

for t = 2:time_steps  % 从第2帧开始，第1帧已初始化
    % 更新无人机位置
    [uav_trajectories, uav_positions, current_directions] = updateUAVPosition(t, uav_trajectories, uav_positions, ...
        uav_trajectory_modes, time_vector, bs_position, uav_speed, uav_flight_radius, uav_height, ...
        current_directions, change_direction_prob, dt, uav_nums);
    
    % 计算通信参数
    [distances, beam_directions, received_powers, snrs, beam_misalignments, ...
        multi_beam_directions, multi_beam_gains, tracking_buffers] = ...
        calculateCommunicationParams(t, uav_trajectories, bs_position, tracking_buffers, ...
        wavelength, path_loss_exponent, shadow_fading_std, bs_antennas, beam_width, ...
        tx_power_dBm, noise_floor_dBm, distances, beam_directions, received_powers, ...
        snrs, beam_misalignments, multi_beam_directions, multi_beam_gains, uav_nums);
    
    % 可视化 - 每10步更新一次图像
    if mod(t, 10) == 0 || t == time_steps
        visualizeSimulation(t, bs_position, uav_trajectories, colors, multi_beam_directions, ...
            distances, mode_names, uav_trajectory_modes, uav_nums,visual_beams,beam_width,bs_antennas);
    end
end

%% 分析和输出性能指标
analyzePerformance(received_powers, snrs, beam_misalignments, beam_width, ...
    mode_names, uav_trajectory_modes, uav_nums);

end