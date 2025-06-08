function sortedUeCell = sortUeByPriority(ueCell)
    % 从元胞数组中提取所有UE的优先级值
    priorities = cellfun(@(ue) ue.priority, ueCell);
    
    % 按优先级降序排序（高优先级在前）
    [~, sortedIndices] = sort(priorities, 'descend');
    
    % 根据排序索引重组元胞数组
    sortedUeCell = ueCell(sortedIndices);
end