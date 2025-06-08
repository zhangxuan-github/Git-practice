classdef nrMobilityModel < handle
    properties
        % parameters
        speed
        direction

    end

    methods
        function obj = nrMobilityModel(speed, direction)
            obj.speed = speed;
            obj.direction = direction;
        end
        
        function [d_lat, d_lon] = calculateDisplacement(obj, dt, current_lat)
            % 计算给定时间内的经纬度位移
            % 输入:
            %   dt          - 时间间隔 (秒)
            %   current_lat - 当前纬度 (度)，用于经度计算
            % 输出:
            %   d_lat       - 纬度变化量 (度)
            %   d_lon       - 经度变化量 (度)
            
            % 地球半径 (米)
            R = 6371000;  % 平均半径
            
            % 1. 计算移动距离 (米)
            distance = obj.speed * dt;
            
            % 2. 将方向角转换为数学坐标系角度 (0°=正东，逆时针增加)
            math_angle = mod(90 - obj.direction, 360);
            
            % 3. 计算北向和东向位移分量
            d_north = distance * cosd(math_angle);
            d_east  = distance * sind(math_angle);
            
            % 4. 计算纬度变化 (米转度)
            d_lat = d_north / (pi/180 * R);
            
            % 5. 计算经度变化 (考虑纬度缩放)
            lat_rad = deg2rad(current_lat);
            d_lon = d_east / (pi/180 * R * cos(lat_rad));
        end

    end
end