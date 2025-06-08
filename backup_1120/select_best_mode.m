function selectedMode = select_best_mode(user, modes)
    % 选择通信模式的逻辑：
    % 1. 带宽满足速率需求；
    % 2. 时延满足时延需求；
    % 3. 根据与服务器的距离，选择适合的模式。
    
    selectedMode = [];
    
    % 假设所有模式都有不同的带宽、时延要求
    modeNames = fieldnames(modes);
    possibleModes = {};
    
    for i = 1:length(modeNames)
        mode = modes.(modeNames{i});
        
        % 判断带宽和时延是否满足需求
        if mode.Bandwidth >= user.rateDemand && mode.Latency <= user.latencyDemand
            % 计算与服务器的距离对于该模式的适应性（简单的权衡模型）
            if user.distanceToServer <= mode.Range
                possibleModes{end+1} = mode; % 将符合要求的模式加入
            end
        end
    end
    
    % 从符合要求的模式中，选择带宽最大且延迟最小的模式
    if ~isempty(possibleModes)
        % 可以选择带宽最大且延迟最小的模式作为最优模式
        selectedMode = possibleModes{1}; % 初步选择第一个模式作为默认
        for i = 2:length(possibleModes)
            if possibleModes{i}.Bandwidth > selectedMode.Bandwidth
                selectedMode = possibleModes{i};
            elseif possibleModes{i}.Bandwidth == selectedMode.Bandwidth && possibleModes{i}.Latency < selectedMode.Latency
                selectedMode = possibleModes{i};
            end
        end
    else
        % 如果没有满足条件的模式，选择带宽最大、延迟最小的模式
        selectedMode = modes.Mode_HRF; % 默认选择5G模式
    end
end
