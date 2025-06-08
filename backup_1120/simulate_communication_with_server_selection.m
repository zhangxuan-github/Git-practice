function result = simulate_communication_with_server_selection(numNodes, numServers, nodePositions, serverPositions, distanceMatrix, modes, userRequirements, businessType)
    % 初始化通信性能参数
    latency = zeros(1, numNodes + numServers);
    throughput = zeros(1, numNodes + numServers);
    packetLoss = zeros(1, numNodes + numServers);
    
    % 遍历每个用户，根据其需求选择最合适的通信模式
    for i = 1:numNodes
        user = userRequirements(i);
        
        % 判断当前业务类型
        if strcmp(user.businessType, businessType)
            % 根据需求选择通信模式
            selectedMode = select_best_mode(user, modes);
            
            % 仿真用户到服务器的性能
            for j = 1:numServers
                dist = distanceMatrix(i, numNodes + j);
                
                % 计算传播时延（光速假设）
                propagationDelay = dist / 3e8;  % 光速3e8 m/s
                
                % 计算处理时延（假设为常数）
                processingDelay = 5e-3;  % 假设处理时延为5ms
                
                % 总时延 = 传播时延 + 处理时延
                latency(i) = latency(i) + propagationDelay + processingDelay;
                
                % 吞吐量使用Shannon Capacity模型： C = B * log2(1 + SNR)
                % 假设SNR为简单的信噪比模型，可以根据距离调整SNR
                SNR = 10 * log10((selectedMode.Bandwidth / dist)); % 假设SNR与带宽和距离的关系
                throughput(i) = throughput(i) + selectedMode.Bandwidth * log2(1 + 10^(SNR/10));
                
                % 丢包率假设与距离相关，距离越远丢包率越高
                packetLoss(i) = packetLoss(i) + 1 - exp(-dist / selectedMode.Range);
            end
        end
    end
    
    % 将仿真结果返回
    result.latency = mean(latency);
    result.throughput = mean(throughput);
    result.packetLoss = mean(packetLoss);
end
