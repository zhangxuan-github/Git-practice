function createLinearBeam(bs_pos, uav_pos, color, beam_idx,beam_width)
% 创建线性波束效果，类似于图片中的细长波束
% bs_pos: 基站位置
% uav_pos: 无人机位置
% color: 波束颜色
% beam_idx: 波束编号（用于区分不同波束）

% 1. 基础射线 - 从基站到无人机的直线
plot3([bs_pos(1), uav_pos(1)], [bs_pos(2), uav_pos(2)], [bs_pos(3), uav_pos(3)], ...
    '-', 'Color', color, 'LineWidth', beam_width);

% 2. 在无人机位置绘制标记
plot3(uav_pos(1), uav_pos(2), uav_pos(3), 'o', 'Color', color, ...
    'MarkerSize', 8, 'MarkerFaceColor', color);

% 3. 计算波束方向向量
beam_vec = uav_pos - bs_pos;
beam_length = norm(beam_vec);
beam_dir = beam_vec / beam_length;

% 4. 创建垂直于波束方向的两个基向量
if abs(beam_dir(3)) < 0.9
    perp1 = cross([0, 0, 1], beam_dir);
else
    perp1 = cross([1, 0, 0], beam_dir);
end
perp1 = perp1 / norm(perp1);
perp2 = cross(beam_dir, perp1);
perp2 = perp2 / norm(perp2);

% 5. 波束宽度参数（可调整）
width_start = 0.5;  % 基站附近的宽度
width_end = beam_width;     % 无人机附近的宽度

% 6. 计算波束边缘点（四边形）
corners = cell(1, 4);

% 在基站附近的四个角点
corners{1} = bs_pos + width_start * perp1;
corners{2} = bs_pos - width_start * perp1;
corners{3} = bs_pos - width_start * perp2;
corners{4} = bs_pos + width_start * perp2;

% 在无人机附近的四个角点
corners{5} = uav_pos + width_end * perp1;
corners{6} = uav_pos - width_end * perp1;
corners{7} = uav_pos - width_end * perp2;
corners{8} = uav_pos + width_end * perp2;

% 7. 绘制四个面（侧面）
patch_color = color;
alpha_value = 0.3;  % 透明度

% 面1
patch([corners{1}(1), corners{5}(1), corners{6}(1), corners{2}(1)], ...
      [corners{1}(2), corners{5}(2), corners{6}(2), corners{2}(2)], ...
      [corners{1}(3), corners{5}(3), corners{6}(3), corners{2}(3)], ...
      patch_color, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');

% 面2
patch([corners{2}(1), corners{6}(1), corners{7}(1), corners{3}(1)], ...
      [corners{2}(2), corners{6}(2), corners{7}(2), corners{3}(2)], ...
      [corners{2}(3), corners{6}(3), corners{7}(3), corners{3}(3)], ...
      patch_color, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');

% 面3
patch([corners{3}(1), corners{7}(1), corners{8}(1), corners{4}(1)], ...
      [corners{3}(2), corners{7}(2), corners{8}(2), corners{4}(2)], ...
      [corners{3}(3), corners{7}(3), corners{8}(3), corners{4}(3)], ...
      patch_color, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');

% 面4
patch([corners{4}(1), corners{8}(1), corners{5}(1), corners{1}(1)], ...
      [corners{4}(2), corners{8}(2), corners{5}(2), corners{1}(2)], ...
      [corners{4}(3), corners{8}(3), corners{5}(3), corners{1}(3)], ...
      patch_color, 'FaceAlpha', alpha_value, 'EdgeColor', 'none');
end