% 添加单个无人机轨迹选择函数
function mode = selectTrajectoryForUAV(uav_idx)
    mode_names = {'圆周运动', '直线运动', '8字形轨迹', '随机轨迹'};
    
    if uav_idx == -1 
            % 创建对话框标题
            dlg_title = sprintf('选择无人机的轨迹模式', 1);
            % 显示选择对话框
            [mode, ok] = listdlg('ListString', mode_names, ...
                         'SelectionMode', 'single', ...
                         'Name', dlg_title, ...
                         'PromptString', sprintf('为全部无人机选择轨迹模式:', uav_idx), ...
                         'ListSize', [200, 160]);
    else
        % 创建对话框标题
        dlg_title = sprintf('选择无人机 %d 的轨迹模式', uav_idx);
        
        % 显示选择对话框
        [mode, ok] = listdlg('ListString', mode_names, ...
                             'SelectionMode', 'single', ...
                             'Name', dlg_title, ...
                             'PromptString', sprintf('为无人机 %d 选择轨迹模式:', uav_idx), ...
                             'ListSize', [200, 160]);             
    % 如果用户取消，使用默认模式(圆周)
    if ok == 0
        mode = 1;
        fprintf('无人机 %d 使用默认轨迹模式: %s\n', uav_idx, mode_names{mode});
    else
        fprintf('无人机 %d 选择轨迹模式: %s\n', uav_idx, mode_names{mode});
    end
end