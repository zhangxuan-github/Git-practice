% --- 示例：使用独立的函数管理并行池和并行操作 ---
run_parallel_simulation();
function run_parallel_simulation()
    % 这个主函数协调并行池的开启、操作执行和关闭

    fprintf('--- 开始并行仿真 ---\n');

    % 1. 开启并行池
    openParallelPool();

    % 2. 执行并行操作
    % 模拟每秒执行一次并行操作，共执行 10 秒
    num_iterations = 10;
    all_results = cell(1, num_iterations);

    fprintf('\n开始执行 %d 次并行操作 (每次间隔 1 秒)...\n', num_iterations);

    for k = 1:num_iterations
        fprintf('--- 第 %d 次操作 ---\n', k);
        % 调用执行并行操作的函数
        current_op_result = performParallelOperation(k);
        all_results{k} = current_op_result; % 存储本次操作的结果

        fprintf('  本次操作结果总和: %.4f\n', current_op_result);

        % 暂停 1 秒，模拟时间间隔
        if k < num_iterations
            pause(1);
        end
    end

    fprintf('\n所有 %d 次并行操作已完成。\n', num_iterations);

    % 3. 关闭并行池
    closeParallelPool();

    fprintf('\n--- 并行仿真结束 ---\n');

    % 可选：显示所有结果
    disp('所有次操作的总和结果：');
    disp([all_results{:}]);
end

% --- 并行池管理函数 ---

function openParallelPool()
    % 检查并启动并行池
    fprintf('正在检查或启动并行池...\n');
    currentPool = gcp('nocreate'); % 获取当前并行池对象，如果不存在则返回空
    if isempty(currentPool)
        parpool(4); % 启动默认数量的并行工作者
        fprintf('并行池已启动。\n');
    else
        fprintf('并行池已存在并活跃。\n');
    end
end

function closeParallelPool()
    % 关闭并行池
    fprintf('正在关闭并行池...\n');
    delete(gcp('nocreate')); % 关闭当前活跃的并行池
    fprintf('并行池已关闭。\n');
end

% --- 并行操作函数 ---

function total_sum = performParallelOperation(iteration_id)
    % 这是一个封装了并行操作的函数
    % iteration_id 可用于在操作中引入一些变化

    num_sub_tasks = 100; % 假设每次操作包含 100 个小的独立计算
    temp_results = zeros(1, num_sub_tasks);

    tic_parfor = tic; % 记录 parfor 内部执行时间
    parfor i = 1:num_sub_tasks
        % 模拟一个计算密集型任务
        % 结果与 iteration_id 相关，以显示每次操作的不同
        temp_results(i) = sin(i * iteration_id / 100) * cos(i * iteration_id / 50) + rand();
    end
    toc_parfor = toc(tic_parfor);
    fprintf('  parfor 内部计算耗时: %.4f 秒\n', toc_parfor);

    total_sum = sum(temp_results); % 返回本次操作的总和
end