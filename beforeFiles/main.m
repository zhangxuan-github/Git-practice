% 主文件：main.m
clc;
clear;

% Step 1: 获取用户输入
prompt = {'用电信息采集用户节点数量:', ...
          '配电自动化用户节点数量:', ...
          '新能源调控用户节点数量:', ...
          '多模通信服务器数量:'};
dlg_title = '输入参数';
dims = [1 50];
default_vals = {'80', '70', '60', '5'};
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

% Step 2: 计算距离矩阵
[dist_matrix_user, dist_matrix, user_positions, server_positions] = calculate_distances( ...
    num_electric_nodes, num_automation_nodes, num_new_energy_nodes, num_servers);

disp('距离矩阵:');
disp(dist_matrix);

% Step 3: 绘制网络拓扑
% plot_network(user_positions, server_positions, num_users_type);

% Step 4: 用户与服务器配对
pairs = pair_nodes(dist_matrix);
disp('用户节点-配对服务器结果:');
disp(pairs);

% 新增功能：绘制用户与服务器的配对连线图
% plot_pairings(user_positions, server_positions, pairs);

% Step 5: 弹出通信模式选择菜单
selected_mode = select_communication_mode();

% 弹出信道配置
communication_mode_config();

% Step 6: 模拟性能
performance_results = simulate_performance(pairs, user_positions, server_positions, selected_mode);
disp('性能指标:');
disp(performance_results);

% 定义通信模式名称
mode_names = {'5G', 'HPCL', 'HRF'};
communication_modes = performance_results(:,4);
% plot_pairings_with_modes(user_positions, server_positions, pairs, communication_modes, mode_names);


% 绘制用户与服务器的配对图（用户间连接）
plot_pairings_with_user_user_links(user_positions, server_positions, pairs, communication_modes, mode_names, dist_matrix_user, num_users_type);

% 生成多用户多业务调度配置文件
NumUE = num_electric_nodes+num_automation_nodes+num_new_energy_nodes;
generateAPPConfig(NumUE);
generateUEConfig('NRFDDAPPConfigFile.xlsx', 'NRFDDRLCChannelConfig.xlsx');

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
    fprintf('用户设备配置文件已生成并保存为 %s\n', outputFilePath);
end

