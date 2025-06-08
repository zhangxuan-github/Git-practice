function sortedGnbs = getCoveredGnbsForUe(ueId, doubleMap, gnbCell)
    % 获取指定UE的覆盖基站并按距离排序
    % 输入:
    %   ueId - 用户设备ID
    %   doubleMap - 双层距离Map
    %   gnbCell - 基站元胞数组
    % 输出:
    %   sortedGnbs - 按距离排序的基站对象元胞数组
    
    % 验证UE ID存在
    if ~isKey(doubleMap, ueId)
        error('UE ID %d not found in distance map', ueId);
    end
    
    % 获取该UE的距离映射
    distanceMap = doubleMap(ueId);
    
    % 创建临时结构数组存储基站和距离
    gnbList = struct('gnb', {}, 'distance', {});
    
    % 遍历所有基站
    for i = 1:length(gnbCell)
        gnb = gnbCell{i};
        gnbId = gnb.id;
        
        % 验证基站ID存在
        if ~isKey(distanceMap, gnbId)
            continue;
        end
        
        distance = distanceMap(gnbId);
        
        % 只添加覆盖范围内的基站
        if ~isinf(distance) && distance >= 0
            gnbList(end+1) = struct('gnb', gnb, 'distance', distance);
        end
    end
    
    % 如果没有覆盖的基站，返回空元胞数组
    if isempty(gnbList)
        sortedGnbs = {};
        return;
    end
    
    % 按距离升序排序
    [~, sortIdx] = sort([gnbList.distance]);
    sortedGnbs = {gnbList(sortIdx).gnb};
end