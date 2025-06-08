function plotNetwork(gNBArray, UEArray)
% plotNetworkGeo: 绘制多个 gNB 和 UE 的地理位置，以及每个 gNB 的覆盖范围。
%   gNBArray: nrGNBaseStation 对象的元胞数组
%   UEArray: nrUserEquipment 对象的元胞数组

    figure; % 创建一个新的图形窗口

    % 创建一个轴对象，用于地图绘制
    ax = axesm('mercator', 'MapLatLimit', [-90 90], 'MapLonLimit', [-180 180]); % 使用墨卡托投影
    gridm on; % 添加地理网格
    framem on; % 添加地图边框
    set(ax, 'Layer', 'top'); % 确保网格和边框在数据上方
    
    title('5G 网络仿真视图：多 gNB 和 UE 地理部署');
    xlabel('经度');
    ylabel('纬度');
    
    hold on; % 保持图形，以便在同一图中绘制所有元素

    % 绘制所有 gNB 的位置和覆盖范围
    if ~isempty(gNBArray)
        for gNB_idx = 1:length(gNBArray)
            current_gNB = gNBArray{gNB_idx};
            if ~isempty(current_gNB) && numel(current_gNB.position) >= 2
                lat_gNB = current_gNB.position(1);
                lon_gNB = current_gNB.position(2);
                
                % 绘制 gNB 位置 (使用红色填充方形)
                plotm(lat_gNB, lon_gNB, 's', 'MarkerSize', 10, 'MarkerFaceColor', [0.85 0.33 0.1], 'DisplayName', 'gNB');
                
                % 绘制 gNB 覆盖范围 (使用红色虚线圆)
                % 将米转换为度并绘制圆
                [lat_circle, lon_circle] = scircle1(lat_gNB, lon_gNB, current_gNB.radius, [], 'degrees');
                plotm(lat_circle, lon_circle, '--', 'Color', [0.85 0.33 0.1], 'LineWidth', 1, 'DisplayName', 'gNB 覆盖范围');
            else
                warning('gNBArray 中索引 %d 处的 gNB 对象无效或其 position 属性不包含足够的坐标。', gNB_idx);
            end
        end
    else
        warning('gNBArray 为空。');
    end

    % 绘制所有 UE 的位置
    if ~isempty(UEArray)
        for ue_idx = 1:length(UEArray)
            current_UE = UEArray{ue_idx};
            if ~isempty(current_UE) && numel(current_UE.position) >= 2
                lat_UE = current_UE.position(1);
                lon_UE = current_UE.position(2);
                
                % 根据 businessType 给 UE 设置不同的颜色
                switch current_UE.businessType
                    case 'eMBB'
                        color = [0 0.447 0.741]; % 蓝色
                        displayName = 'eMBB UE';
                    case 'URLLC'
                        color = [0.466 0.674 0.188]; % 绿色
                        displayName = 'URLLC UE';
                    case 'mMTC'
                        color = [0.929 0.694 0.125]; % 黄色
                        displayName = 'mMTC UE';
                    otherwise
                        color = [0.5 0.5 0.5]; % 灰色 (默认)
                        displayName = 'Other UE';
                end
                plotm(lat_UE, lon_UE, 'o', 'MarkerSize', 7, 'MarkerFaceColor', color, 'DisplayName', displayName);
            else
                warning('UEArray 中索引 %d 处的 UE 对象无效或其 position 属性不包含足够的坐标。', ue_idx);
            end
        end
    else
        warning('UEArray 为空。');
    end

    hold off; % 释放图形
    
    % 创建自定义图例项，避免重复显示
    h = findobj(gca, 'Type', 'Line');
    labels = get(h, 'DisplayName');
    [~, unique_idx] = unique(labels);
    legend(h(unique_idx), 'Location', 'best');
end