
function [numNodes, numServers, nodePositions, serverPositions, distanceMatrix] = initialize_network_with_servers(numUsers)

numNodes = numUsers;
% 假设服务器数量是基站数量的1/20
numServers = ceil(numUsers / 40);

% 用户节点位置（随机分布）
nodePositions = rand(numUsers, 2) * 1500; % 假设区域大小1000x1000

% 服务器节点位置（随机分布）
serverPositions = rand(numServers, 2) * 1500; % 假设区域大小1000x1000

% % 绘制用户节点和服务器节点的位置
% figure;
% scatter(nodePositions(:,1), nodePositions(:,2), 10, 'b', 'filled'); % 用户节点以蓝色表示
% hold on;
% scatter(serverPositions(:,1), serverPositions(:,2), 50, 'r', 'filled'); % 服务器节点以红色表示
%
% % 设置图形标题和标签
% title('用户和服务器的位置');
% xlabel('X 坐标');
% ylabel('Y 坐标');
% legend('用户节点', '服务器节点', 'Location', 'best');
% grid on;
%
% % 显示图形
% hold off;

% 用户节点总数
numUsers = size(nodePositions, 1);

% 用户节点的分组比例
group1_ratio = 0.4;  % 模式1占40%
group2_ratio = 0.3;  % 模式2占30%
group3_ratio = 0.3;  % 模式3占30%

% 计算每组用户的数量
numGroup1 = floor(numUsers * group1_ratio);
numGroup2 = floor(numUsers * group2_ratio);
numGroup3 = numUsers - numGroup1 - numGroup2;  % 剩下的用户分配给第三组

% 随机打乱用户节点索引
userGroups = randperm(numUsers);

% 将用户节点分配到三个组
group1 = userGroups(1:numGroup1);  % 第一组
group2 = userGroups(numGroup1+1:numGroup1+numGroup2);  % 第二组
group3 = userGroups(numGroup1+numGroup2+1:end);  % 第三组

% 绘制用户节点和服务器节点的位置
color1 = [0.239, 0.537, 0.639];  % #3D89A3
color2 = [0.369, 0.780, 0.816];  % #5EC7D0
color3 = [0.514, 0.518, 0.510];  % #838482
color4 = [0.945, 0.843, 0.337];  % #F1D756

color1 = [0.2196, 0.2196, 0.2196];  % #383838
color2 = [0.3608, 0.6549, 0.7804];  % #5CA7C7
color3 = [0.8314, 0.2078, 0.1765];  % #D4352D
color4 = [0.9843, 0.8039, 0.4167];  % #FBCE6A

figure;
set(gcf, 'Position', [1000, 100, 1000, 1000]); % 调整图像宽1200，高800
% 绘制第一组用户节点 (通信模式1) - 使用绿色
scatter(nodePositions(group1, 1), nodePositions(group1, 2), 50, color1, 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 1);
hold on;

% 绘制第二组用户节点 (通信模式2) - 使用蓝色
scatter(nodePositions(group2, 1), nodePositions(group2, 2), 50, color2, 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 1);

% 绘制第三组用户节点 (通信模式3) - 使用紫色
scatter(nodePositions(group3, 1), nodePositions(group3, 2), 50, color3, 'Marker', 'o', 'MarkerFaceColor', 'none', 'LineWidth', 1);

% 绘制服务器节点 - 使用红色
scatter(serverPositions(:, 1), serverPositions(:, 2), 350, color4, 'Marker', '^', 'MarkerFaceColor', 'none', 'LineWidth', 2);

% 添加图例
legend('Mode: 5G', 'Mode: HPLC', 'Mode: HRF', '服务器节点', 'Location', 'best');

% 设置图形标题和坐标轴标签
title('用户节点和服务器节点位置');
xlabel('X坐标');
ylabel('Y坐标');
% 设置坐标轴和图例的字体大小
set(gca, 'FontSize', 18);  % 设置坐标轴字体大小
legend('FontSize', 18);  % 设置图例字体大小

% 计算用户和服务器之间的距离矩阵
distanceMatrix = zeros(numUsers + numServers, numUsers + numServers);

% 计算用户之间的距离
for i = 1:numUsers
    for j = 1:numUsers
        distanceMatrix(i, j) = norm(nodePositions(i, :) - nodePositions(j, :));
    end
end

% 计算用户与服务器之间的距离
for i = 1:numUsers
    for j = 1:numServers
        distanceMatrix(i, numUsers + j) = norm(nodePositions(i, :) - serverPositions(j, :));
        distanceMatrix(numUsers + j, i) = distanceMatrix(i, numUsers + j);
    end
end
end
