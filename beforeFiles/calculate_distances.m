function [dist_matrix_user, dist_matrix, user_positions, server_positions] = calculate_distances( ...
    num_electric_nodes, num_automation_nodes, num_new_energy_nodes, num_servers)

total_users = num_electric_nodes + num_automation_nodes + num_new_energy_nodes;

% 随机生成用户和服务器的位置
user_positions = rand(total_users, 2) * 1500; % 用户节点位置
server_positions = rand(num_servers, 2) * 1500; % 服务器位置

% 计算距离矩阵
dist_matrix = pdist2(user_positions, server_positions);
dist_matrix_user = pdist2(user_positions, user_positions);
end
