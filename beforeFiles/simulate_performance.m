function performance_results = simulate_performance(pairs, user_positions, server_positions, selected_mode)
% 固定信道模型参数
num_users = size(user_positions, 1);
performance_results = zeros(num_users, 4); % 存储丢包率、时延、吞吐量、通信模式

% 假设简单的信道模型
for i = 1:num_users
    server_idx = pairs(i);
    distance = norm(user_positions(i,:) - server_positions(server_idx,:));
    [packet_loss, latency, throughput, model_index] = channel_models(distance, selected_mode);
    performance_results(i, :) = [packet_loss, latency, throughput, model_index];
end
end
