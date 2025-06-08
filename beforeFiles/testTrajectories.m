%% 无人机轨迹测试主程序
% 此程序用于调用主仿真代码，测试不同轨迹模式并比较性能
% 作者: Claude
% 日期: 2025-05-13

clear all;
close all;
clc;

% 存储各轨迹结果的数据结构
results = struct('mode_name', {}, 'avg_rx_power', {}, 'min_rx_power', {}, ...
                'avg_snr', {}, 'min_snr', {}, 'avg_misalignment', {}, 'max_misalignment', {});

% 轨迹模式名称
mode_names = {'圆周运动', '直线运动', '8字形轨迹', '随机轨迹'};

% 选择要测试的轨迹模式
test_modes = [];
[selection, ok] = listdlg('PromptString', '选择要测试的轨迹模式:', ...
                        'SelectionMode', 'multiple', ...
                        'ListString', mode_names, ...
                        'Name', '轨迹测试选择', ...
                        'ListSize', [300, 160], ...
                        'InitialValue', 1);

if ok == 0 || isempty(selection)
    % 用户取消，默认测试圆周运动
    test_modes = 1;
    disp('默认测试圆周运动模式');
else
    test_modes = selection;
    disp('将测试以下轨迹模式:');
    disp(mode_names(test_modes));
end

% 轨迹模式循环
for i = 1:length(test_modes)
    mode = test_modes(i);
    disp(['====== 开始测试 ', mode_names{mode}, ' 模式 ======']);
    
    % 设置轨迹模式并运行仿真
    trajectory_mode = mode;
    
    % 调用主仿真程序
    run_simulation;
    
    % 收集性能数据
    results(i).mode_name = mode_names{mode};
    results(i).avg_rx_power = avg_rx_power;
    results(i).min_rx_power = min_rx_power;
    results(i).avg_snr = avg_snr;
    results(i).min_snr = min_snr;
    results(i).avg_misalignment = avg_misalignment;
    results(i).max_misalignment = max_misalignment;
    
    disp(['====== 完成测试 ', mode_names{mode}, ' 模式 ======']);
    
    % 如果不是最后一个模式，暂停让用户查看结果
    if i < length(test_modes)
        disp('按任意键继续下一个轨迹模式测试...');
        pause;
    end
end

% 如果测试了多个轨迹模式，显示对比图
if length(results) > 1
    disp('生成轨迹模式对比分析...');
    plotTrajectoryComparison(results);
end

disp('所有测试完成！');

%% 辅助函数：运行主仿真
function run_simulation
    % 这个函数用于调用主仿真代码
    % 在实际使用中，您可以将这部分替换为直接调用newATG.m的代码
    
    % 示例：调用主仿真函数（假设它已经被修改为接受轨迹模式作为输入）
    % newATG(trajectory_mode);
    
    % 临时占位符 - 在实际使用中请删除这部分代码
    % 这里只是为了演示而生成一些随机性能指标
    global trajectory_mode;
    fprintf('正在运行轨迹模式 %d 的仿真...\n', trajectory_mode);
    
    % 在实际实现中，您应该删除下面这段代码，改为直接调用您的主仿真程序
    % 调用修改后的newATG主程序，例如：
    % run newATG.m
    
    % 如果您已经修改了newATG.m以接受全局变量trajectory_mode，
    % 下面这行代码应该被替换为对newATG.m的直接调用
    evalin('base', 'run(''newATG.m'')');
end