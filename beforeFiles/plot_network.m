function plot_network(user_positions, server_positions, num_users_type)
figure;

set(gca, 'FontSize', 18);  % 设置坐标轴字体大小
legend('FontSize', 18);  % 设置图例字体大小
% set(gcf, 'Position', [1, 1, 1000, 1000]);
% 获取屏幕大小
screenSize = get(0, 'ScreenSize');

% 设置图形窗口大小为 800x600，并居中
width = 800;
height = 600;
x = (screenSize(3) - width) / 2;
y = (screenSize(4) - height) / 2;

set(gcf, 'Position', [x, y, width, height]);


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


% legend('用户节点', '服务器节点');
legend('show', 'Location', 'best');

title('网络拓扑');
xlabel('X 坐标 (m)');
ylabel('Y 坐标 (m)');
grid on;
end
