function h = drawBaseStation(position, size,bs_antennas)
% 绘制基站的图形图标
% position: 基站位置 [x,y,z]
% size: 图标大小
% h: 返回句柄以用于图例

% 定义基本颜色
dark_gray = [0.3, 0.3, 0.3];
light_gray = [0.7, 0.7, 0.7];
black = [0, 0, 0];
blue = [0, 0.4, 0.8];
red = [0.8, 0.2, 0.2]; % 添加红色定义

% 基站底座(底部)
base_r = size * 0.7;
base_h = size * 0.4;
[X, Y, Z] = cylinder(base_r, 16);
Z = Z * base_h;
% 移动到正确位置
X = X + position(1);
Y = Y + position(2);
Z = Z + position(3) - base_h-18; % 确保底部在指定位置
h_base = surf(X, Y, Z, 'FaceColor', dark_gray, 'EdgeColor', 'none', 'FaceLighting', 'gouraud');

% 基站中间部分(圆柱)
tower_r = size * 0.4;
tower_h = size * 1.5;
[X, Y, Z] = cylinder(tower_r, 16);
Z = Z * tower_h;
% 移动到正确位置
X = X + position(1);
Y = Y + position(2);
Z = Z + position(3)-18; % 从底座顶部开始
surf(X, Y, Z, 'FaceColor', light_gray, 'EdgeColor', 'none', 'FaceLighting', 'gouraud');

% 基站顶部(圆盘)
top_r = size * 0.5;
top_h = size * 0.2;
[X, Y, Z] = cylinder(top_r, 16);
Z = Z * top_h;
% 移动到正确位置
X = X + position(1);
Y = Y + position(2);
Z = Z + position(3) + tower_h-18; % 从塔顶开始
surf(X, Y, Z, 'FaceColor', blue, 'EdgeColor', 'none', 'FaceLighting', 'gouraud');

for i = 0:bs_antennas-1 % 从0到7，总共8个天线
    angle = i * (2*pi/bs_antennas); % 均匀分布在圆上
    dx = cos(angle) * size * 0.3;
    dy = sin(angle) * size * 0.3;
    
    % 垂直天线
    antenna_h = size * 0.1;
    line_width = 1;
    ant_x = position(1) + dx;
    ant_y = position(2) + dy;
    ant_z_bottom = position(3) + tower_h + top_h-18;
    ant_z_top = ant_z_bottom + antenna_h-18;
    
    % 绘制天线
    plot3([ant_x, ant_x], [ant_y, ant_y], [ant_z_bottom, ant_z_top], ...
        'LineWidth', line_width, 'Color', black);
    
    % 在天线顶部添加小球
    sphere_r = size * 0.08;
    [sx, sy, sz] = sphere(8);
    sx = sx * sphere_r + ant_x;
    sy = sy * sphere_r + ant_y;
    sz = sz * sphere_r + ant_z_top+18;
    surf(sx, sy, sz, 'FaceColor', red, 'EdgeColor', 'none');
end
 
% 添加照明效果使3D对象看起来更好
light('Position', [1 1 1], 'Style', 'infinite');
material dull;

% 返回底座句柄用于图例
h = h_base;
end