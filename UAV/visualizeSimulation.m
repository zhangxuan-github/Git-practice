function visualizeSimulation(t, bs_position, uav_trajectories, colors, multi_beam_directions, ...
distances, mode_names, uav_trajectory_modes, uav_nums, visual_beams,beam_width,bs_antennas)
% 可视化仿真
% 绘制基站、无人机、波束等

% 获取当前图形窗口，如果没有则创建
if isempty(findall(0, 'Type', 'figure'))
    figure;
end

% 只在第一次调用时设置窗口最大化和渲染器
persistent figure_initialized;
if isempty(figure_initialized) || ~isvalid(gcf)
    set(gcf, 'WindowState', 'maximized');
    % 设置渲染器以减少闪烁
    set(gcf, 'Renderer', 'opengl');
    % 启用双缓冲
    set(gcf, 'DoubleBuffer', 'on');
    figure_initialized = true;
end

% 只清除坐标轴内容，不清除图形窗口设置
cla;
hold on;

% 在每次更新时强制固定坐标轴
set(gca, 'XLim', [-200, 200]);
set(gca, 'YLim', [-200, 200]);
set(gca, 'ZLim', [-50, 100]);
set(gca, 'XLimMode', 'manual');
set(gca, 'YLimMode', 'manual');
set(gca, 'ZLimMode', 'manual');

% 储存图例句柄和标签（用于只显示实际绘制的元素）
legend_handles = [];
legend_labels = {};

% % 绘制基站位置
% bs_handle = plot3(bs_position(1), bs_position(2), bs_position(3), 'ks', ...
%     'MarkerSize', 15, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
% 绘制基站位置 - 使用图形图标而不是简单的标记
drawBaseStation(bs_position,12,bs_antennas); % 使用自定义函数绘制基站
% legend_handles(end+1) = bs_handle;
% legend_labels{end+1} = '基站';

% 计算实际要显示的无人机数量
actual_visual_beams = min(visual_beams, uav_nums);

% 绘制所有无人机
for uav_idx = 1:uav_nums
    % 获取无人机当前位置
    uav_pos = squeeze(uav_trajectories(t, uav_idx, :))';
    
    % 绘制无人机当前位置和编号标签
    uav_handle = plot3(uav_pos(1), uav_pos(2), uav_pos(3), 'o', 'Color', colors(uav_idx,:), ...
        'MarkerSize', 12, 'MarkerFaceColor', colors(uav_idx,:), 'MarkerEdgeColor', colors(uav_idx,:));
    legend_handles(end+1) = uav_handle;
    legend_labels{end+1} = sprintf('UAV-%d [%s]', uav_idx, mode_names{uav_trajectory_modes(uav_idx)});
    
    % 创建包含轨迹模式的标签文本
    label_text = sprintf(' UAV-%d [%s]', uav_idx, mode_names{uav_trajectory_modes(uav_idx)});
    % 添加增强标签
    text(uav_pos(1), uav_pos(2), uav_pos(3) + 5, label_text, ...
        'Color', colors(uav_idx,:), 'FontWeight', 'bold', 'FontSize', 10);
    
    % 只为前visual_beams个无人机绘制波束
    if uav_idx <= actual_visual_beams
        % 计算基站到无人机的方向和距离
        beam_vec = uav_pos - bs_position;
        beam_length = norm(beam_vec);
        beam_dir = beam_vec / beam_length;
        
        % 创建线性波束效果（类似于图片中所示）
        createLinearBeam(bs_position, uav_pos, colors(uav_idx,:), uav_idx,beam_width);
        
        % 在波束中间添加波束编号标签
        mid_point = (bs_position + uav_pos) / 2;
        text(mid_point(1), mid_point(2), mid_point(3), [' 波束-', num2str(uav_idx)], ...
            'Color', colors(uav_idx,:), 'FontWeight', 'bold', 'FontSize', 9);
    end
end

% 添加标签和图例
xlabel('X (m)', 'FontSize', 14);
ylabel('Y (m)', 'FontSize', 14);
zlabel('Z (m)', 'FontSize', 14);
title(['多无人机波束跟踪 (', num2str(uav_nums), '架无人机, 显示前', num2str(actual_visual_beams), '个波束) - 时刻 t=', num2str(t)], 'FontSize', 16);

% 显示图例
legend(legend_handles, legend_labels, 'Location', 'northeast', 'FontSize', 12);
grid on;

% 设置视角和坐标轴范围
view(45, 30);

% 自动调整坐标轴范围以包含所有无人机
all_points = reshape(uav_trajectories(1:t,:,:), [], 3);
all_points = [all_points; bs_position];
xlim([min(all_points(:,1))-20, max(all_points(:,1))+20]);
ylim([min(all_points(:,2))-20, max(all_points(:,2))+20]);
zlim([min(all_points(:,3))-20, max(all_points(:,3))+20]);

% 设置坐标轴比例为相等，确保3D图形不失真
axis equal;

% 使用flush和限制更新频率来减少闪烁
% 更新图形
drawnow;
% 减少暂停时间以提高流畅度
pause(0.05);

end