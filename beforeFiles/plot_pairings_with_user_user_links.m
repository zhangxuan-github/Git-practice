function plot_pairings_with_user_user_links(user_positions, server_positions, pairs, communication_modes, mode_names, user_distance_matrix, num_users_type)
% 绘制用户与服务器的配对图，第二种和第三种模式的用户连接最近用户

figure;
hold on;

set(gca, 'FontSize', 18);  % 设置坐标轴字体大小
legend('FontSize', 18);  % 设置图例字体大小
% set(gcf, 'Position', [1, 1, 1000, 1000]);
% 获取屏幕大小
screenSize = get(0, 'ScreenSize');

% 设置图形窗口大小为 800x600，并居中
width = 1200;
height = 600;
x = (screenSize(3) - width) / 2;
y = (screenSize(4) - height) / 2;

set(gcf, 'Position', [x, y, width, height]);


% 定义颜色映射（根据模式数量）
colors = lines(length(mode_names)); % 自动生成不同颜色

% 绘制用户节点和服务器节点
scatter(server_positions(:,1), server_positions(:,2), 500, 'k', 'Marker', '^', 'MarkerFaceColor', 'none', 'LineWidth', 2 , 'DisplayName', '服务器节点'); % 固定黑色表示服务器
% 绘制用户节点-按照用户类型
user_pos = user_positions;
list1 = 1:num_users_type(1);
list2 = num_users_type(1)+1:num_users_type(1)+num_users_type(2);
list3 = num_users_type(1)+num_users_type(2)+1:num_users_type(1)+num_users_type(2)+num_users_type(3);
scatter(user_pos(list1,1), user_pos(list1,2), 100, 'k', 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 1.5 , 'DisplayName', '用电信息采集用户');
scatter(user_pos(list2,1), user_pos(list2,2), 100, 'k', 'Marker', 'square', 'MarkerFaceColor', 'none', 'LineWidth', 1.5, 'DisplayName', '配电自动化用户');
scatter(user_pos(list3,1), user_pos(list3,2), 100, 'k', 'Marker', 'hexagram', 'MarkerFaceColor', 'none', 'LineWidth', 1.5, 'DisplayName', '分布式光伏调控用户');

% % 绘制用户节点（使用通信模式的颜色）
%  user_pos = user_positions;
% list1 = find(communication_modes==1);
% scatter(user_pos(list1,1), user_pos(list1,2), 100, colors(1, :), 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 2 , 'DisplayName', mode_names{1});
% list2 = find(communication_modes==2);
% scatter(user_pos(list2,1), user_pos(list2,2), 100, colors(2, :), 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 2 , 'DisplayName', mode_names{2});
% list3 = find(communication_modes==3);
% scatter(user_pos(list3,1), user_pos(list3,2), 100, colors(3, :), 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 2 , 'DisplayName', mode_names{3});


% 绘制用户节点和连线
for i = 1:length(pairs)
    user_pos = user_positions(i, :);
    server_pos = server_positions(pairs(i), :);
    mode = communication_modes(i);
    
    if mode == 2 % HPCL
        % 找到与该用户最近的其他用户
        distances = user_distance_matrix(i, :);
        distances(i) = inf; % 避免自己与自己比较
        [~, nearest_user_idx] = min(distances);
        nearest_user_pos = user_positions(nearest_user_idx, :);
        
        % 绘制从该用户到最近用户的连线
        plot([user_pos(1), nearest_user_pos(1)], [user_pos(2), nearest_user_pos(2)], '--', ...
            'Color', colors(mode, :), 'LineWidth', 1.2, 'HandleVisibility', 'off');
        
        % 绘制从最近用户到服务器的连线
        plot([nearest_user_pos(1), server_pos(1)], [nearest_user_pos(2), server_pos(2)], '--', ...
            'Color', colors(mode, :), 'LineWidth', 1.2, 'HandleVisibility', 'off');
    elseif mode == 3  % HRF 模式
        % 找到与该用户最近的其他用户
        distances = user_distance_matrix(i, :);
        distances(i) = inf; % 避免自己与自己比较
        [~, nearest_user_idx] = min(distances);
        nearest_user_pos = user_positions(nearest_user_idx, :);
        
        % 绘制从该用户到最近用户的连线
        plot([user_pos(1), nearest_user_pos(1)], [user_pos(2), nearest_user_pos(2)], '-.', ...
            'Color', colors(mode, :), 'LineWidth', 1.5, 'HandleVisibility', 'off');
        
        % 绘制从最近用户到服务器的连线
        plot([nearest_user_pos(1), server_pos(1)], [nearest_user_pos(2), server_pos(2)], '-.', ...
            'Color', colors(mode, :), 'LineWidth', 1.5, 'HandleVisibility', 'off');
    else  % 5G 模式
        % 直接绘制从用户到服务器的连线
        plot([user_pos(1), server_pos(1)], [user_pos(2), server_pos(2)], ':', ...
            'Color', colors(mode, :), 'LineWidth', 1.5, 'HandleVisibility', 'off');
    end
    
    % 绘制用户节点（使用通信模式的颜色）
    % scatter(user_pos(1), user_pos(2), 100, colors(mode, :), 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 2 , 'DisplayName', mode_names{mode});
end

plot(NaN, NaN, ':', 'Color', colors(1, :), 'LineWidth', 1.5, 'DisplayName', '5G');
plot(NaN, NaN, '--', 'Color', colors(2, :), 'LineWidth', 1.5, 'DisplayName', 'HPCL');
plot(NaN, NaN, '-.', 'Color', colors(3, :), 'LineWidth', 1.5, 'DisplayName', 'HRF');


% 设置图例（避免重复）
% legend('Server Node', mode_names{:}, 'Location', 'bestoutside');
legend('服务器节点','用电信息采集用户','配电自动化用户','分布式光伏调控用户', 'Mode: 5G', 'Mode: HPCL', 'Mode: HRF', 'Location', 'bestoutside');
% legend('Server Node', 'Mode: 5G', 'Mode: HPCL', 'Mode: HRF', 'Location', 'bestoutside');
title('配电物联网边缘网元分布及通信模式示意图');
xlabel('X 坐标 (m)');
ylabel('Y 坐标 (m)');
grid on;
hold off;
end

