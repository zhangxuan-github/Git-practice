function [packet_loss, latency, throughput, mode_index] = channel_models(distance, selected_mode)
% 假设简单模型
switch selected_mode
    case '随机通信模式选择'
        modes = {'5G', 'HPCL', 'HRF'};
        mode_index = randi(3);
        mode = modes{mode_index};
    case '基于业务需求的通信模式选择'
        if distance < 50
            mode = '5G';
            mode_index = 1;
        elseif distance < 100
            mode = 'HPCL';
            mode_index = 2;
        else
            mode = 'HRF';
            mode_index = 3;
        end
end

% 模拟参数
switch mode
    case '5G'
        packet_loss = rand() * 0.1; % 丢包率
        latency = rand() * 10; % 时延
        throughput = rand() * 100; % 吞吐量
    case 'HPCL'
        packet_loss = rand() * 0.2;
        latency = rand() * 20;
        throughput = rand() * 80;
    case 'HRF'
        packet_loss = rand() * 0.3;
        latency = rand() * 30;
        throughput = rand() * 60;
end
end
