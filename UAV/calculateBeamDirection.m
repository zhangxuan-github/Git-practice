function [azimuth, elevation] = calculateBeamDirection(bs_pos, uav_pos)
% 计算波束方向的立体角（方位角和仰角）
% 输入参数：
%   bs_pos：基站位置坐标 [x, y, z]
%   uav_pos：无人机位置坐标 [x, y, z]
% 输出参数：
%   azimuth：方位角（度）
%   elevation：仰角（度）

relative_pos = uav_pos - bs_pos;

% 计算方位角（水平面上的角度）
azimuth = atan2(relative_pos(2), relative_pos(1));

% 计算仰角（与垂直轴的角度）
horizontal_distance = sqrt(relative_pos(1)^2 + relative_pos(2)^2);
elevation = atan2(relative_pos(3), horizontal_distance);

% 转换为角度
azimuth = azimuth * 180/pi;
elevation = elevation * 180/pi;

end