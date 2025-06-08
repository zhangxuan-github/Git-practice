function analyzePerformance(received_powers, snrs, beam_misalignments, beam_width, ...
    mode_names, uav_trajectory_modes, uav_nums)
% 分析和输出性能指标
% 输出每个无人机的性能统计

fprintf('\n===== 性能指标统计 (共%d架无人机) =====\n', uav_nums);

for uav_idx = 1:uav_nums
    fprintf('\n--- 无人机 %d 性能指标 [%s模式] ---\n', uav_idx, mode_names{uav_trajectory_modes(uav_idx)});
    
    avg_rx_power = mean(received_powers(:, uav_idx));
    min_rx_power = min(received_powers(:, uav_idx));
    avg_snr = mean(snrs(:, uav_idx));
    min_snr = min(snrs(:, uav_idx));
    avg_misalignment = mean(beam_misalignments(:, uav_idx));
    max_misalignment = max(beam_misalignments(:, uav_idx));
    
    fprintf('平均接收功率: %.2f dBm\n', avg_rx_power);
    fprintf('最小接收功率: %.2f dBm\n', min_rx_power);
    fprintf('平均SNR: %.2f dB\n', avg_snr);
    fprintf('最小SNR: %.2f dB\n', min_snr);
    fprintf('平均波束对准误差: %.2f 度\n', avg_misalignment);
    fprintf('最大波束对准误差: %.2f 度\n', max_misalignment);
    fprintf('波束宽度设置: %.2f 度\n', beam_width);
end

end