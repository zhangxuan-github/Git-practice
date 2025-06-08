function [bs_position, bs_antennas, beam_width, carrier_freq, wavelength, tx_power_dBm, tx_power, ...
          beam_tracking_delay, sim_time, dt, time_steps, data_rate, comm_distance, ...
          interference_suppression, uav_nums, uav_initial_position, uav_speed, ...
          uav_flight_radius, uav_height, random_step_size, change_direction_prob, ...
          noise_floor_dBm, path_loss_exponent, shadow_fading_std ,visual_beams] = initializeSimulation()
% 初始化仿真参数和数据结构
% 输出：各种仿真参数

%% 获取用户输入参数
prompt = {'基站数目:（个）',...
    '基站天线数:（大于64）', ...
    '无人机初始飞行速度:(m/s)',...
    '无人机数目:（个）',...
    '可视化波束数量:(至少3个)',...
    '波束宽度:（°）',...
    '通信速率:（Mbps）',...
    '通信距离:（KM）',...
    '干扰抑制能力:（dB）'};
dlg_title = '外部接入信息';
dims = [1 50];   
default_vals = {'1','64', '300', '10','5', '3','10', '300', '20',};
input_vals = inputdlg(prompt, dlg_title, dims, default_vals);
% 确保波束数量至少为3个

if isempty(input_vals)
    % 用户取消了输入，返回空值
    bs_position = [];
    bs_antennas = [];    
    beam_width = [];
    carrier_freq = [];
    wavelength = [];
    tx_power_dBm = [];
    tx_power = [];
    beam_tracking_delay = [];
    sim_time = [];
    dt = [];
    time_steps = [];
    data_rate = [];
    comm_distance = [];
    interference_suppression = [];
    uav_nums = [];
    uav_initial_position = [];
    uav_speed = [];
    uav_flight_radius = [];
    uav_height = [];
    random_step_size = [];
    change_direction_prob = [];
    noise_floor_dBm = [];
    path_loss_exponent = [];
    shadow_fading_std = [];
    visual_beams = [];
    return;
end



%% 参数设置
% 基站参数
bs_position = [0, 0, 0];  % 基站位置 [x, y, z] (米)，固定在坐标原点
bs_antennas = str2double(input_vals{1}); % 基站天线数
beam_width = str2double(input_vals{5}); % 波束宽度
carrier_freq = 28e9;       % 载波频率 (28GHz)
wavelength = 3e8/carrier_freq;  % 波长
tx_power_dBm = 43;         % 发射功率 (dBm)
tx_power = 10^(tx_power_dBm/10)/1000;  % 转换为瓦特

% 波束跟踪参数
beam_tracking_delay = 5;  % 波束追踪延迟（时间步长）
visual_beams = str2double(input_vals{5});

% 仿真时间设置
sim_time = 10;    % 总仿真时间(秒)
dt = 0.1;         % 时间步长(秒)
time_steps = sim_time/dt;  % 总步数

% 通信参数设置
data_rate = str2double(input_vals{6}); % 通信速率(Mbps)
comm_distance = str2double(input_vals{7}); % 通信距离(Km)
interference_suppression = str2double(input_vals{8}); % 干扰抑制能力(dB)

% 无人机参数
uav_nums = str2double(input_vals{3});
uav_initial_position = [100, 0, 50];  % 无人机初始位置 [x, y, z] (米)
uav_speed = str2double(input_vals{2});  % 无人机速度 (米/秒)
uav_flight_radius = 200;   % 无人机飞行半径 (米)
uav_height = 50;           % 无人机高度 (米)

% 随机轨迹参数 (仅在随机轨迹模式下使用)
random_step_size = 5;      % 随机步长最大值 (米)
change_direction_prob = 0.1; % 改变方向概率

% 信道参数
noise_floor_dBm = -174 + 10*log10(100e6) + 7;  % 噪声底 (带宽100MHz, NF=7dB)
path_loss_exponent = 2.2;  % 路径损耗指数
shadow_fading_std = 4;     % 阴影衰落标准差 (dB)

end