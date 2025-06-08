
function [x_meters, y_meters] = relativePositionInRectangle(lat_topLeft, lon_topLeft, ...
                                                          lat_bottomRight, lon_bottomRight, ...
                                                          lat_point, lon_point)
%relativePositionInRectangle 计算点相对于矩形左下角的米制位置
%   [x_meters, y_meters] = relativePositionInRectangle(lat_topLeft, lon_topLeft, ...
%                                                      lat_bottomRight, lon_bottomRight, ...
%                                                      lat_point, lon_point)
%
%   输入:
%     lat_topLeft       - 矩形左上角的纬度
%     lon_topLeft       - 矩形左上角的经度
%     lat_bottomRight   - 矩形右下角的纬度
%     lon_bottomRight   - 矩形右下角的经度
%     lat_point         - 目标点的纬度
%     lon_point         - 目标点的经度
%
%   输出:
%     x_meters          - 目标点相对于左下角原点的X坐标 (米)
%     y_meters          - 目标点相对于左下角原点的Y坐标 (米)
%
%   注意:
%     此函数假定地球为WGS84椭球体，并使用haversine公式近似计算距离。
%     为了更精确的计算，推荐使用Mapping Toolbox中的geodetic functions。

% 获取矩形的左下角经纬度
lat_bottomLeft = lat_bottomRight;
lon_bottomLeft = lon_topLeft;

% 定义地球半径 (WGS84椭球体平均半径，单位:米)
% 更精确的做法是使用地球椭球模型，但对于小范围的矩形，平均半径近似足够。
R = 6371000; % 米

% --- 计算目标点到左下角原点的距离 ---
% 使用haversine公式计算距离，这是一个近似值，对于小范围区域足够。
% 如果需要更高精度，请使用Mapping Toolbox中的distance函数。

% 1. 计算目标点到左下角点的水平距离 (x轴方向)
%    这相当于计算目标点和左下角点在同一纬度上的经度差所对应的距离。
%    我们需要找到目标点在左下角经度上的投影点，即 (lat_point, lon_bottomLeft)
delta_lon_x = deg2rad(lon_point - lon_bottomLeft);
lat_rad_point_x = deg2rad(lat_point);
x_meters = R * cos(lat_rad_point_x) * delta_lon_x;


% 2. 计算目标点到左下角点的垂直距离 (y轴方向)
%    这相当于计算目标点和左下角点在同一经度上的纬度差所对应的距离。
%    我们需要找到目标点在左下角纬度上的投影点，即 (lat_bottomLeft, lon_point)
delta_lat_y = deg2rad(lat_point - lat_bottomLeft);
y_meters = R * delta_lat_y;

% 修正方向：
% 经度增加为X轴正方向 (东)
% 纬度增加为Y轴正方向 (北)
% 默认情况下，delta_lon_x和delta_lat_y已经考虑了方向。

end

