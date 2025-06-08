function distance = calculateHaversineDistance(pos1, pos2)
    % 使用Haversine公式计算地球表面两点间距离
    % 输入: pos1 = [纬度1, 经度1], pos2 = [纬度2, 经度2] (单位: 度)
    % 输出: 距离 (单位: 米)
    
    R = 6371000; % 地球半径(米)
    lat1 = deg2rad(pos1(1));
    lon1 = deg2rad(pos1(2));
    lat2 = deg2rad(pos2(1));
    lon2 = deg2rad(pos2(2));
    
    dlat = lat2 - lat1;
    dlon = lon2 - lon1;
    
    a = sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    
    distance = R * c;
end