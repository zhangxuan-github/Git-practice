function plot_pairings_with_modes(user_positions, server_positions, pairs, communication_modes, mode_names)
% 绘制用户与服务器的配对图，根据通信模式调整颜色和图例

figure;
hold on;
set(gca, 'FontSize', 18);  % 设置坐标轴字体大小
legend('FontSize', 18);  % 设置图例字体大小
set(gcf, 'Position', [1, 1, 1000, 1000]);

% 定义颜色映射（根据模式数量）
colors = lines(length(mode_names)); % 自动生成不同颜色

% 绘制用户节点和服务器节点
scatter(server_positions(:,1), server_positions(:,2), 350, 'k', 'Marker', '^', 'MarkerFaceColor', 'none', 'LineWidth', 2 , 'DisplayName', '服务器节点'); % 固定黑色表示服务器

% 绘制用户节点和配对连线，根据通信模式区分颜色
for i = 1:length(pairs)
    user_pos = user_positions(i, :);
    server_pos = server_positions(pairs(i), :);
    mode = communication_modes(i);
    
    % 绘制用户节点（使用通信模式的颜色）
    scatter(user_pos(1), user_pos(2), 100, colors(mode, :), 'filled', 'DisplayName', mode_names{mode});
    
    % 绘制用户与服务器之间的连线（使用通信模式的颜色）
    plot([user_pos(1), server_pos(1)], [user_pos(2), server_pos(2)], '--', 'Color', colors(mode, :), 'LineWidth', 1.2, 'HandleVisibility', 'off');
end

% 设置图例（避免重复）
legend('Server Node', mode_names{:}, 'Location', 'bestoutside');
title('用户与服务器配对（基于通信模式）');
xlabel('X 坐标');
ylabel('Y 坐标');
grid on;
hold off;
end
