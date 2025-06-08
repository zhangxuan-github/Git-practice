function plot_pairings(user_positions, server_positions, pairs)
figure;
set(gca, 'FontSize', 18);  % 设置坐标轴字体大小
legend('FontSize', 18);  % 设置图例字体大小
set(gcf, 'Position', [1, 1, 1000, 1000]);
hold on;

% 绘制用户节点和服务器节点
h1 = scatter(user_positions(:,1), user_positions(:,2), 'b', 'filled', 'DisplayName', '用户节点');
h2 = scatter(server_positions(:,1), server_positions(:,2), 'r', 'filled', 'DisplayName', '服务器节点');

% 绘制用户与服务器之间的连线
for i = 1:length(pairs)
    user_pos = user_positions(i, :);
    server_pos = server_positions(pairs(i), :);
    plot([user_pos(1), server_pos(1)], [user_pos(2), server_pos(2)], 'k--', 'LineWidth', 1.2);
end

legend([h1, h2]);
title('用户与服务器配对');
xlabel('X 坐标');
ylabel('Y 坐标');
grid on;
hold off;
end
