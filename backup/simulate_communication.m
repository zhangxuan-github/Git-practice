function results = simulate_communication(numNodes, nodePositions, distanceMatrix, modes, businessType)
    % 模拟通信过程
    results = struct();
    latency = zeros(numNodes, 1);
    throughput = zeros(numNodes, 1);
    packetLoss = zeros(numNodes, 1);
    
    for i = 1:numNodes
        % 根据业务类型选择通信模式
        mode = multi_mode_algorithm(businessType, modes);
        % 计算每个节点的性能
        latency(i) = mean(distanceMatrix(i, :)) / (mode.Bandwidth * 1e-6);
        throughput(i) = mode.Bandwidth * (1 - rand() * 0.1); % 模拟随机吞吐量
        packetLoss(i) = rand() * 0.05; % 随机丢包率
    end
    
    % 汇总性能指标
    results.latency = mean(latency);
    results.throughput = mean(throughput);
    results.packetLoss = mean(packetLoss);
    fprintf('业务: %s, 延迟: %.3f ms, 吞吐量: %.3f Mbps, 丢包率: %.3f%%\n', ...
        businessType, results.latency * 1e3, results.throughput / 1e6, results.packetLoss * 100);
end
