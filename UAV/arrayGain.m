function gain = arrayGain(azimuth, elevation, target_azimuth, target_elevation, num_antennas, beam_width)
% 计算天线阵列增益
% 输入参数：
%   azimuth：实际方位角（度）
%   elevation：实际仰角（度）
%   target_azimuth：目标方位角（度）
%   target_elevation：目标仰角（度）
%   num_antennas：天线数目
%   beam_width：波束宽度（度）
% 输出参数：
%   gain：天线增益（线性值，非dB）

% 计算方向误差（度）
azimuth_error = abs(azimuth - target_azimuth);
elevation_error = abs(elevation - target_elevation);

% 将方位角误差限制在-180到180度范围内
if azimuth_error > 180
    azimuth_error = 360 - azimuth_error;
end

% 计算总角度误差
angle_error = sqrt(azimuth_error^2 + elevation_error^2);

% 使用指定的波束宽度
beamwidth = beam_width;

% 计算增益
if angle_error <= beamwidth/2
    % 主瓣区域 - 3dB带宽内
    gain_dB = 10*log10(num_antennas) - 3 * (2*angle_error/beamwidth)^2;
else
    % 旁瓣区域，用简化模型
    gain_dB = 10*log10(num_antennas) - 3 - 20*log10(angle_error/(beamwidth/2));
    gain_dB = max(gain_dB, -10);  % 设置最小增益
end

gain = 10^(gain_dB/10);

end