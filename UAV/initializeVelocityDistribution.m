%% 速度分布选择功能
function [uav_speed, velocity_distribution_modes] = initializeVelocityDistribution(uav_nums, uav_speed)
    % 初始化速度分布模式数组
    velocity_distribution_modes = zeros(uav_nums, 1);
    
    % 给每个无人机分配初始速度（默认使用全局速度）
    uav_speeds = ones(uav_nums, 1) * uav_speed;
    
    % 添加速度分布选择对话框
    speed_choice = questdlg('为无人机选择速度分布方式?', ...
                     '速度分布', ...
                     '每架单独选择', '全局统一模式', '随机分配', '随机分配');
    
    % 速度分布模式分配逻辑分支
    switch speed_choice
        case '每架单独选择'
            % 为每个无人机实体调用单独的速度分布模式选择函数
            for i = 1:uav_nums
                [velocity_distribution_modes(i), uav_speeds(i)] = selectVelocityDistributionForUAV(i, uav_speed);
            end
            
        case '全局统一模式'
            % 调用全局速度分布模式选择器
            [global_mode, base_speed] = selectVelocityDistributionMode(uav_speed);
            velocity_distribution_modes(:) = global_mode;
            
            % 根据选择的模式初始化无人机速度
            initializeSpeedsBasedOnMode(uav_nums, global_mode, base_speed, uav_speeds);
            
        case '随机分配'
            % 以离散均匀分布从速度分布模式空间进行随机采样
            mode_count = 4;  % 速度模式空间基数 |M| = 4
            
            % 随机选择速度分布模式
            for i = 1:uav_nums
                velocity_distribution_modes(i) = randi(mode_count);
                
                % 根据每个无人机的模式分配速度
                switch velocity_distribution_modes(i)
                    case 1 % 恒定速率
                        uav_speeds(i) = uav_speed;
                    case 2 % 正态分布
                        uav_speeds(i) = uav_speed + randn * (uav_speed * 0.2);
                        uav_speeds(i) = max(uav_speeds(i), uav_speed * 0.5);
                    case 3 % 均匀分布
                        uav_speeds(i) = uav_speed * (0.5 + rand);
                    case 4 % 指数分布
                        uav_speeds(i) = exprnd(uav_speed);
                        uav_speeds(i) = max(uav_speeds(i), uav_speed * 0.3);
                end
            end
            
            % 将选定的速度分布模式输出到控制台
            speed_mode_names = {'恒定速率', '正态分布', '均匀分布', '指数分布'};
            fprintf('\n随机分配的速度分布模式:\n');
            for i = 1:uav_nums
                fprintf('无人机 %d: %s, 速度: %.2f m/s\n', i, speed_mode_names{velocity_distribution_modes(i)}, uav_speeds(i));
            end
            
        otherwise
            % 默认情况下使用原始速度参数
            uav_speeds(:) = uav_speed;
            velocity_distribution_modes(:) = 1; % 默认恒定速率
    end
end

%% 速度分布模式选择函数 - 下拉框选择
function [mode, base_speed] = selectVelocityDistributionMode(default_speed)
    % 创建速度模式选择对话框
    speed_distribution_list = {'恒定速率', '正态分布', '均匀分布', '指数分布'};
    
    [mode_idx, ok] = listdlg('ListString', speed_distribution_list, ...
                           'SelectionMode', 'single', ...
                           'Name', '速度分布模式选择', ...
                           'PromptString', '选择速度分布模式:', ...
                           'ListSize', [300, 160]);
    
    if ~ok
        % 用户取消选择，使用默认值
        mode = 1;  % 恒定速率
        base_speed = default_speed;
        return;
    end
    
    % 设置返回的模式
    mode = mode_idx;
    
    % 根据所选模式提供参数输入界面
    switch mode
        case 1 % 恒定速率
            prompt = {'输入基准速度 (m/s):'};
            dlg_title = '恒定速率参数';
            num_lines = 1;
            default_answer = {num2str(default_speed)};
            answer = inputdlg(prompt, dlg_title, num_lines, default_answer);
            
            if ~isempty(answer)
                base_speed = str2double(answer{1});
            else
                base_speed = default_speed;
            end
            
        case 2 % 正态分布
            prompt = {'均值 (m/s):', '标准差 (m/s):'};
            dlg_title = '正态分布参数';
            num_lines = 1;
            default_answer = {num2str(default_speed), num2str(default_speed * 0.2)};
            answer = inputdlg(prompt, dlg_title, num_lines, default_answer);
            
            if ~isempty(answer)
                base_speed = str2double(answer{1});
            else
                base_speed = default_speed;
            end
            
        case 3 % 均匀分布
            prompt = {'最小速度 (m/s):', '最大速度 (m/s):'};
            dlg_title = '均匀分布参数';
            num_lines = 1;
            default_answer = {num2str(default_speed * 0.5), num2str(default_speed * 1.5)};
            answer = inputdlg(prompt, dlg_title, num_lines, default_answer);
            
            if ~isempty(answer)
                min_speed = str2double(answer{1});
                max_speed = str2double(answer{2});
                base_speed = (min_speed + max_speed) / 2; % 使用平均值作为基准速度
            else
                base_speed = default_speed;
            end
            
        case 4 % 指数分布
            prompt = {'均值 (m/s):'};
            dlg_title = '指数分布参数';
            num_lines = 1;
            default_answer = {num2str(default_speed)};
            answer = inputdlg(prompt, dlg_title, num_lines, default_answer);
            
            if ~isempty(answer)
                base_speed = str2double(answer{1});
            else
                base_speed = default_speed;
            end
    end
end

%% 单个无人机速度分布选择函数
function [mode, speed] = selectVelocityDistributionForUAV(uav_idx, default_speed)
    % 设置标题文本
    if uav_idx > 0
        title_text = sprintf('为无人机 %d 选择速度分布', uav_idx);
    else
        title_text = '为所有无人机选择速度分布';
    end
    
    % 调用通用速度分布模式选择函数
    [mode, base_speed] = selectVelocityDistributionMode(default_speed);
    
    % 根据所选模式生成初始速度
    switch mode
        case 1 % 恒定速率
            speed = base_speed;
            
        case 2 % 正态分布
            speed = base_speed + randn * (base_speed * 0.2);
            speed = max(speed, base_speed * 0.5); % 确保最小速度
            
        case 3 % 均匀分布
            % 假设base_speed是区间的中点
            min_speed = base_speed * 0.5;
            max_speed = base_speed * 1.5;
            speed = min_speed + rand * (max_speed - min_speed);
            
        case 4 % 指数分布
            speed = exprnd(base_speed);
            speed = max(speed, base_speed * 0.3); % 确保最小速度
    end
end

%% 初始化基于模式的速度函数
function initializeSpeedsBasedOnMode(uav_nums, mode, base_speed, uav_speeds)
    % 根据所选速度分布模式初始化所有无人机的速度
    switch mode
        case 1 % 恒定速率
            uav_speeds(:) = base_speed;
            
        case 2 % 正态分布
            % 以base_speed为均值，标准差为均值的20%生成速度
            for i = 1:uav_nums
                uav_speeds(i) = base_speed + randn * (base_speed * 0.2);
                uav_speeds(i) = max(uav_speeds(i), base_speed * 0.5); % 确保最小速度
            end
            
        case 3 % 均匀分布
            % 在base_speed的50%到150%范围内均匀分布
            min_speed = base_speed * 0.5;
            max_speed = base_speed * 1.5;
            for i = 1:uav_nums
                uav_speeds(i) = min_speed + rand * (max_speed - min_speed);
            end
            
        case 4 % 指数分布
            % 使用指数分布，均值为base_speed
            for i = 1:uav_nums
                uav_speeds(i) = exprnd(base_speed);
                uav_speeds(i) = max(uav_speeds(i), base_speed * 0.3); % 确保最小速度
            end
    end
end

%% 更新无人机速度函数
function uav_speeds = updateUAVSpeeds(uav_speeds, velocity_distribution_modes, t, time_steps, default_speed)
    % 基于各无人机的速度分布模式动态更新速度
    for i = 1:length(uav_speeds)
        switch velocity_distribution_modes(i)
            case 1 % 恒定速率
                % 不做任何改变
                
            case 2 % 正态分布
                % 每10步更新一次速度
                if mod(t, 10) == 0
                    mean_speed = default_speed;
                    std_dev = mean_speed * 0.2;
                    uav_speeds(i) = mean_speed + randn * std_dev;
                    uav_speeds(i) = max(uav_speeds(i), mean_speed * 0.5);
                end
                
            case 3 % 均匀分布
                % 每20步更新一次速度
                if mod(t, 20) == 0
                    min_speed = default_speed * 0.5;
                    max_speed = default_speed * 1.5;
                    uav_speeds(i) = min_speed + rand * (max_speed - min_speed);
                end
                
            case 4 % 指数分布
                % 每15步更新一次速度
                if mod(t, 15) == 0
                    mean_speed = default_speed;
                    uav_speeds(i) = exprnd(mean_speed);
                    uav_speeds(i) = max(uav_speeds(i), mean_speed * 0.3);
                end
        end
    end
end

%% 速度分布可视化函数
function visualizeVelocityDistribution(time_vector, uav_speeds_history, velocity_distribution_modes, uav_nums)
    % 创建图形窗口
    figure('Name', '无人机速度分布', 'NumberTitle', 'off', 'Position', [100, 100, 900, 600]);
    
    % 颜色映射
    colors = hsv(uav_nums);
    
    % 速度分布模式名称
    speed_mode_names = {'恒定速率', '正态分布', '均匀分布', '指数分布'};
    
    % 绘制每个无人机的速度随时间变化
    subplot(2, 1, 1);
    hold on;
    for i = 1:uav_nums
        plot(time_vector, uav_speeds_history(:, i), 'Color', colors(i, :), 'LineWidth', 1.5);
    end
    hold off;
    
    title('无人机速度随时间变化');
    xlabel('时间 (秒)');
    ylabel('速度 (m/s)');
    grid on;
    
    % 创建图例
    legend_entries = cell(uav_nums, 1);
    for i = 1:uav_nums
        legend_entries{i} = sprintf('无人机 %d (%s)', i, speed_mode_names{velocity_distribution_modes(i)});
    end
    legend(legend_entries, 'Location', 'eastoutside');
    
    % 绘制速度分布直方图
    subplot(2, 1, 2);
    
    % 计算所有速度值
    all_speeds = uav_speeds_history(:);
    
    % 创建直方图
    histogram(all_speeds, 30);
    title('无人机速度分布直方图');
    xlabel('速度 (m/s)');
    ylabel('频率');
    grid on;
    
    % 计算并显示统计数据
    mean_speed = mean(all_speeds);
    std_speed = std(all_speeds);
    min_speed = min(all_speeds);
    max_speed = max(all_speeds);
    
    stats_text = sprintf('平均速度: %.2f m/s\n标准差: %.2f m/s\n最小速度: %.2f m/s\n最大速度: %.2f m/s', ...
                       mean_speed, std_speed, min_speed, max_speed);
    
    annotation('textbox', [0.7, 0.3, 0.2, 0.1], 'String', stats_text, ...
               'EdgeColor', 'none', 'BackgroundColor', [0.9, 0.9, 0.9]);
end