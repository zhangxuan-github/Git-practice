function doubleMap = createUeGnbDistanceMap(ueCell, gnbCell)
    % 创建外层Map: UE ID -> (内层Map: gNB ID -> 距离)
    doubleMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
    
    % 遍历所有UE
    for i = 1:length(ueCell)
        ue = ueCell{i};
        ueId = ue.id;
        uePos = ue.position;
        
        % 创建内层Map: gNB ID -> 距离
        innerMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
        
        % 遍历所有基站
        for j = 1:length(gnbCell)
            gnb = gnbCell{j};
            gnbId = gnb.id;
            gnbPos = gnb.position;
            
            % 计算UE到基站的距离
            distance = tools.calculateHaversineDistance(uePos, gnbPos);
            
            % 检查是否在基站覆盖范围内
            if distance > gnb.radius
                distance = -inf; % 超出覆盖范围
            end
            
            % 添加到内层Map
            innerMap(gnbId) = distance;
        end
        
        % 添加到外层Map
        doubleMap(ueId) = innerMap;
    end
end
