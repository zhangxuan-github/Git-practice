function plot_results(results)
    % 提取业务类型
    businessTypes = fieldnames(results);
    latency = zeros(1, length(businessTypes));
    throughput = zeros(1, length(businessTypes));
    packetLoss = zeros(1, length(businessTypes));
    
    % 收集数据
    for i = 1:length(businessTypes)
        latency(i) = results.(businessTypes{i}).latency;
        throughput(i) = results.(businessTypes{i}).throughput;
        packetLoss(i) = results.(businessTypes{i}).packetLoss;
    end
    
    % 绘制图表
    figure;

    set(gca, 'FontSize', 18);  % 设置坐标轴字体大小
    legend('FontSize', 18);  % 设置图例字体大小
    set(gcf, 'Position', [100, 100, 1000, 1500]); % 调整图像宽1200，高800

    subplot(3, 1, 1);
    bar(latency * 1e3);
    set(gca, 'XTickLabel', businessTypes);
    % xtickangle(45); % 设置横轴标签角度为45度
    ylabel('延迟 (ms)');
    title('延迟比较');
    
    subplot(3, 1, 2);
    bar(throughput / 1e6);
    set(gca, 'XTickLabel', businessTypes);
    % xtickangle(45); % 设置横轴标签角度为45度
    ylabel('吞吐量 (Mbps)');
    title('吞吐量比较');
    
    subplot(3, 1, 3);
    bar(packetLoss * 100);
    set(gca, 'XTickLabel', businessTypes);
    % xtickangle(45); % 设置横轴标签角度为45度
    ylabel('丢包率 (%)');
    title('丢包率比较');
    % 设置坐标轴和图例的字体大小
end
