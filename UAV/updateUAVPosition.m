function [uav_trajectories, uav_positions, current_directions] = updateUAVPosition(...
    t, uav_trajectories, uav_positions, uav_trajectory_modes, time_vector, ...
    bs_position, uav_speed, uav_flight_radius, uav_height, current_directions, ...
    change_direction_prob, dt, uav_nums)
% 更新无人机位置函数
% 根据不同轨迹模式更新每个无人机的位置

for uav_idx = 1:uav_nums
    % 获取当前无人机位置
    current_pos = squeeze(uav_trajectories(t-1, uav_idx, :))';
    
    % 获取此无人机的轨迹模式
    current_mode = uav_trajectory_modes(uav_idx);
    
    % 根据轨迹模式更新位置
    switch current_mode
        case 1 % 圆周运动
            % 为每个无人机设置独特的圆周参数
            radius = uav_flight_radius * (0.7 + 0.6 * uav_idx/uav_nums);
            phase_offset = 2 * pi * (uav_idx - 1) / uav_nums;
            angular_speed = uav_speed / radius * (0.5 + 0.8 * rand(1));
            angle = angular_speed * time_vector(t) + phase_offset;
            
            new_pos = [
                radius * cos(angle), 
                radius * sin(angle), 
                uav_height + 15 * sin(angle/3 + uav_idx*pi/4)
            ];
            
        case 2 % 直线运动
            % 为每个无人机设置独特的直线参数
            angle = (2 * pi * (uav_idx - 1) / uav_nums) + (pi/8 * sin(time_vector(t)/10));
            speed_factor = 0.8 + 0.4 * sin(time_vector(t)/15 + uav_idx);
            
            new_pos = current_pos + uav_speed * speed_factor * dt * [cos(angle), sin(angle), 0.1*sin(time_vector(t)/5 + uav_idx)];
            
            % 边界检查与折返逻辑
            if norm(new_pos(1:2)) > 500
                vec_to_origin = -new_pos(1:2) / norm(new_pos(1:2));
                new_pos(1:2) = new_pos(1:2) + 2 * uav_speed * dt * vec_to_origin;
            end
            
        case 3 % 8字形轨迹
            % 为每个无人机设置独特的8字形参数
            scale_factor = 0.7 + 0.6 * (uav_idx/uav_nums);
            scale = 150 * scale_factor;
            phase = uav_idx * pi/3;
            t_param = time_vector(t) * (0.3 + 0.2 * uav_idx/uav_nums) + phase;
            
            new_pos = [
                scale * sin(t_param),
                scale * sin(t_param) * cos(t_param),
                uav_height + 10 * scale_factor * sin(t_param*1.5)
            ];
            
        case 4 % 随机轨迹
            % 为每个无人机设置独特的随机参数
            probability_factor = 0.7 + 0.6 * (uav_idx/uav_nums);
            step_factor = 0.6 + 0.8 * (uav_idx/uav_nums);
            
            % 随机改变方向，但添加无人机特定的变化概率
            if rand < change_direction_prob * probability_factor
                random_change = (rand(1,3) - 0.5) * 2;
                random_change(3) = random_change(3) * 0.2 * uav_idx/uav_nums;
                current_directions(uav_idx,:) = current_directions(uav_idx,:) + random_change;
                current_directions(uav_idx,:) = current_directions(uav_idx,:) / norm(current_directions(uav_idx,:));
            end
            
            % 计算新位置，使用无人机特定步长因子
            movement = current_directions(uav_idx,:) * uav_speed * step_factor * dt;
            new_pos = current_pos + movement;
            
            % 无人机特定高度范围约束
            min_height = 20 + 10 * (uav_idx-1)/uav_nums;
            max_height = 70 + 30 * (uav_idx-1)/uav_nums;
            
            if new_pos(3) < min_height
                new_pos(3) = min_height;
                current_directions(uav_idx,3) = abs(current_directions(uav_idx,3));
            elseif new_pos(3) > max_height
                new_pos(3) = max_height;
                current_directions(uav_idx,3) = -abs(current_directions(uav_idx,3));
            end
            
            % 无人机特定的最大飞行半径约束
            max_radius = 200 + 100 * (uav_idx-1)/uav_nums;
            distance_from_bs = norm(new_pos - bs_position);
            
            if distance_from_bs > max_radius
                % 复杂的返回逻辑：混合当前方向和返回方向
                vec_to_bs = (bs_position - current_pos) / norm(bs_position - current_pos);
                blend_factor = min(1.0, (distance_from_bs - max_radius * 0.9) / (max_radius * 0.1));
                blend_direction = (1-blend_factor) * current_directions(uav_idx,:) + blend_factor * vec_to_bs;
                blend_direction = blend_direction / norm(blend_direction);
                
                current_directions(uav_idx,:) = blend_direction;
                new_pos = current_pos + blend_direction * uav_speed * dt;
            end
    end
    
    % 存储新位置
    uav_trajectories(t, uav_idx, :) = new_pos;
    
    % 更新工作数组中的位置
    uav_positions(uav_idx,:) = new_pos;
end

end