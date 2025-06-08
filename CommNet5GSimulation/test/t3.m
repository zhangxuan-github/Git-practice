% 假设我们有映射表将实际ID转换为矩阵索引
userIDs = [105, 231, 348, 412, 567];  % 实际用户ID
bsIDs = [1001, 1008, 2005, 3010];     % 实际基站ID

% 创建用户ID到索引的映射
userIDMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
for i = 1:length(userIDs)
    userIDMap(userIDs(i)) = i;
end

% 创建基站ID到索引的映射
bsIDMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
for i = 1:length(bsIDs)
    bsIDMap(bsIDs(i)) = i;
end

% 创建距离矩阵
distanceMatrix = zeros(length(userIDs), length(bsIDs));

% 填充矩阵
for u = 1:length(userIDs)
    for b = 1:length(bsIDs)
        % 生成示例距离数据
        distanceMatrix(u, b) = 0.5 + 9.5 * rand();  % 0.5到10公里范围
    end
end

% 使用示例：获取用户348到基站1008的距离
user_id = 348;
bs_id = 1008;
user_idx = userIDMap(user_id);
bs_idx = bsIDMap(bs_id);
distance = distanceMatrix(user_idx, bs_idx);
fprintf('用户%d到基站%d的距离是%.2f公里\n', user_id, bs_id, distance);

% 保存映射和矩阵
% save('distance_matrix_data.mat', 'distanceMatrix', 'userIDs', 'bsIDs', 'userIDMap', 'bsIDMap');