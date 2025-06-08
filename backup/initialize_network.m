function [numNodes, nodePositions, distanceMatrix] = initialize_network(numNodes)
    % 初始化网络节点
    nodePositions = rand(numNodes, 2) * 1000; % 随机生成节点位置
    distanceMatrix = pdist2(nodePositions, nodePositions); % 节点间距离矩阵
end
