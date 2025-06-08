function [distances, beam_directions, received_powers, snrs, beam_misalignments, ...
    multi_beam_directions, multi_beam_gains, tracking_buffers] = ...
    calculateCommunicationParams(t, uav_trajectories, bs_position, tracking_buffers, ...
    wavelength, path_loss_exponent, shadow_fading_std, bs_antennas, beam_width, ...
    tx_power_dBm, noise_floor_dBm, distances, beam_directions, received_powers, ...
    snrs, beam_misalignments, multi_beam_directions, multi_beam_gains, uav_nums)
% 计算通信参数
% 计算距离、波束方向、接收功率、信噪比、波束对准误差等

% 为每个无人机计算通信参数
for uav_idx = 1:uav_nums
    % 获取当前无人机位置
    current_pos = squeeze(uav_trajectories(t, uav_idx, :))';
    
    % 计算基站到无人机的距离
    distances(t, uav_idx) = norm(current_pos - bs_position);
    
    % 计算理想波束方向（如果有完美跟踪）
    [ideal_azimuth, ideal_elevation] = calculateBeamDirection(bs_position, current_pos);
    
    % 更新跟踪缓冲区并计算实际波束方向（考虑追踪延迟）
    new_direction = [ideal_azimuth, ideal_elevation];
    
    % 更新跟踪缓冲区
    tracking_buffers = [tracking_buffers(2:end, :, :); zeros(1, uav_nums, 2)];
    tracking_buffers(end, uav_idx, :) = new_direction;
    current_beam_direction = squeeze(tracking_buffers(1, uav_idx, :))';
    beam_directions(t, uav_idx, :) = current_beam_direction;
    
    % 计算波束对准误差
    azimuth_error = abs(ideal_azimuth - current_beam_direction(1));
    if azimuth_error > 180
        azimuth_error = 360 - azimuth_error;
    end
    elevation_error = abs(ideal_elevation - current_beam_direction(2));
    beam_misalignments(t, uav_idx) = sqrt(azimuth_error^2 + elevation_error^2);
    
    % 计算路径损耗
    path_loss_dB = 20*log10(4*pi*distances(t, uav_idx)/wavelength) + 10*path_loss_exponent*log10(distances(t, uav_idx)/1);
    
    % 添加阴影衰落
    shadow_fading_dB = shadow_fading_std * randn();
    
    % 计算天线增益
    antenna_gain = arrayGain(ideal_azimuth, ideal_elevation, current_beam_direction(1), current_beam_direction(2), bs_antennas, beam_width);
    antenna_gain_dB = 10*log10(antenna_gain);
    
    % 计算接收功率
    rx_power_dBm = tx_power_dBm + antenna_gain_dB - path_loss_dB - shadow_fading_dB;
    received_powers(t, uav_idx) = rx_power_dBm;
    
    % 计算信噪比
    snrs(t, uav_idx) = rx_power_dBm - noise_floor_dBm;
    
    % 存储波束方向和增益
    multi_beam_directions(t, uav_idx, :) = current_beam_direction;
    multi_beam_gains(t, uav_idx) = antenna_gain;
end

end