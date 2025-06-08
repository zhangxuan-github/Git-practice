% 加载数据
data = load('gNB_UAV.mat');
config = data.config;  % 假设配置在 config 变量中

% 检查 UEs 字段
if isfield(config, 'UEs')
    ues = config.UEs;
    fprintf('找到 UEs 字段，包含 %d 个元素\n', length(ues));
    
    % 检查类型
    fprintf('ues 的类型是: %s\n', class(ues));
    %名字
    fprintf('ues 的名字是: %s\n', ues{1}.name);
    % 根据类型进行不同处理
    if isstruct(ues)
        % 结构体数组
        fprintf('ues 是结构体数组\n');
        
        % 显示第一个元素的字段
        fprintf('第一个元素的字段:\n');
        disp(fieldnames(ues(1)));
        
        % 尝试访问 name 字段
        if isfield(ues(1), 'name')
            fprintf('找到名为 %s 的UE\n', ues(1).name);
        else
            fprintf('没有找到 name 字段\n');
        end
        
    elseif iscell(ues)
        % 元胞数组
        fprintf('ues 是元胞数组\n');
        
        % 显示第一个元素
        fprintf('第一个元素内容:\n');
        disp(ues{1});
        
        % 如果第一个元素是结构体
        if isstruct(ues{1}) && isfield(ues{1}, 'name')
            fprintf('找到名为 %s 的UE\n', ues{1}.name);
        end
        
    else
        % 其他类型
        fprintf('ues 是其他类型，无法使用点符号索引\n');
        fprintf('ues 的内容:\n');
        disp(ues);
    end
else
    fprintf('配置中没有 UEs 字段\n');
    
    % 显示配置的所有字段
    fprintf('配置中的可用字段:\n');
    disp(fieldnames(config));
end