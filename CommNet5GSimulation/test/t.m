% 加载世界地图底图
geobasemap('topographic');

% 定义城市坐标（经纬度）
cities = table(...
    [51.5074; 40.7128; 35.6762; 48.8566; 1.3521], ...  % 纬度
    [-0.1278; -74.0060; 139.6503; 2.3522; 103.8198], ...  % 经度
    {'London'; 'New York'; 'Tokyo'; 'Paris'; 'Singapore'}, ...  % 城市名
    'VariableNames', {'Lat', 'Lon', 'Name'});

% 在地图上绘制城市位置
geoplot(cities.Lat, cities.Lon, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

% 添加城市标签
geolabel(cities.Name);

% 设置地图范围
geolimits([-60 90], [-180 180]);

% 添加标题和图例
title('世界主要城市分布');
legend('城市');