import yaml
import folium
from folium import plugins
from folium.features import DivIcon
import math

# 解析YAML数据
data = """
gNBs:
- id: 1
  name: gNB_1
  position:
    latitude: 39.908860
    longitude: 116.397390
    height: 50.0
  radius: 400
  noise_figure: 3
  num_transmit_antennas: 16
  transmit_power: 43
  carrier_frequency: 3500000000
  channel_bandwidth: 100000000
  subcarrier_spacing: 30000
  num_resource_blocks: 273
  slices:
  - slice_type: mMTC
    qos_level: 10
    resource_weight: 0.10
  - slice_type: URLLC
    qos_level: 2
    resource_weight: 0.25
  - slice_type: eMBB
    qos_level: 4
    resource_weight: 0.60

- id: 2
  name: gNB_2
  position:
    latitude: 39.917820
    longitude: 116.397390
    height: 50.0
  radius: 400
  noise_figure: 4
  num_transmit_antennas: 16
  transmit_power: 38
  carrier_frequency: 3500000000
  channel_bandwidth: 100000000
  subcarrier_spacing: 30000
  num_resource_blocks: 273
  slices:
  - slice_type: mMTC
    qos_level: 10
    resource_weight: 0.15
  - slice_type: URLLC
    qos_level: 2
    resource_weight: 0.25
  - slice_type: eMBB
    qos_level: 7
    resource_weight: 0.55

UEs:
- id: 1
  name: UE_1
  position:
    latitude: 39.910860
    longitude: 116.399890
    height: 50.0
  noise_figure: 6
  num_transmit_antennas: 1
  transmit_power: 17
  connection_state: 0
  gnb_node_id: 1
  business_type: eMBB
  priority: 7
  slice_type: eMBB
  mobility_model:
    speed: 7
    direction: 113
- id: 2
  name: UE_2
  position:
    latitude: 39.907360
    longitude: 116.395390
    height: 50.0
  noise_figure: 6
  num_transmit_antennas: 1
    transmit_power: 19
  connection_state: 0
  gnb_node_id: 1
  business_type: eMBB
  priority: 3
  slice_type: eMBB
  mobility_model:
    speed: 8
    direction: 30
- id: 3
  name: UE_3
  position:
    latitude: 39.919620
    longitude: 116.395890
    height: 50.0
  noise_figure: 6
  num_transmit_antennas: 1
  transmit_power: 19
  connection_state: 0
  gnb_node_id: 2
  business_type: eMBB
  priority: 3
  slice_type: eMBB
  mobility_model:
    speed: 8
    direction: 30
- id: 4
  name: UE_4
  position:
    latitude: 39.915820
    longitude: 116.399190
    height: 50.0
  noise_figure: 6
  num_transmit_antennas: 1
  transmit_power: 19
  connection_state: 0
  gnb_node_id: 2
  business_type: eMBB
  priority: 3
  slice_type: eMBB
  mobility_model:
    speed: 7
    direction: 250

area:
  latitudeTopLeft: 39.922000
  longitudeTopLeft: 116.393000
  latitudeBottomRight: 39.905000
  longitudeBottomRight: 116.402000
"""

# 解析YAML数据
config = yaml.safe_load(data)

# 扩大区域范围 (约1.5倍)
area = config['area']
lat_top_left = area['latitudeTopLeft']
lon_top_left = area['longitudeTopLeft']
lat_bottom_right = area['latitudeBottomRight']
lon_bottom_right = area['longitudeBottomRight']

# 计算中心点
center_lat = (lat_top_left + lat_bottom_right) / 2
center_lon = (lon_top_left + lon_bottom_right) / 2

# 扩大区域范围 (约1.5倍)
lat_span = abs(lat_top_left - lat_bottom_right)
lon_span = abs(lon_top_left - lon_bottom_right)

expanded_lat_top_left = center_lat + lat_span * 0.75
expanded_lon_top_left = center_lon - lon_span * 0.75
expanded_lat_bottom_right = center_lat - lat_span * 0.75
expanded_lon_bottom_right = center_lon + lon_span * 0.75

# 创建地图对象
m = folium.Map(
    location=[center_lat, center_lon],
    zoom_start=15,
    tiles='https://webrd02.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}',
    attr='高德地图',
    control_scale=True
)

# 添加卫星图层选项
folium.TileLayer(
    tiles='https://webst02.is.autonavi.com/appmaptile?style=6&x={x}&y={y}&z={z}',
    attr='高德卫星图',
    name='卫星视图'
).add_to(m)

# 绘制原始区域边界
folium.Rectangle(
    bounds=[(lat_top_left, lon_top_left), (lat_bottom_right, lon_bottom_right)],
    color='#ff7800',
    weight=2,
    fill=True,
    fill_color='#ffff00',
    fill_opacity=0.1,
    popup='原始监控区域',
    tooltip='原始区域范围'
).add_to(m)

# 绘制扩大后的区域边界
folium.Rectangle(
    bounds=[(expanded_lat_top_left, expanded_lon_top_left), 
            (expanded_lat_bottom_right, expanded_lon_bottom_right)],
    color='#3388ff',
    weight=2,
    fill=False,
    dash_array='5, 5',
    popup='扩大后的监控区域',
    tooltip='扩大区域范围'
).add_to(m)

# 绘制基站及其覆盖范围
gnb_colors = ['#ff0000', '#0000ff']  # 不同基站使用不同颜色
gnb_icons = ['signal', 'signal']  # 基站图标

for i, gnb in enumerate(config['gNBs']):
    # 基站位置
    lat, lon = gnb['position']['latitude'], gnb['position']['longitude']
    radius = gnb['radius']  # 覆盖半径（米）
    
    # 绘制覆盖范围
    folium.Circle(
        location=[lat, lon],
        radius=radius,
        color=gnb_colors[i],
        weight=1,
        fill=True,
        fill_color=gnb_colors[i],
        fill_opacity=0.15,
        popup=f"{gnb['name']}覆盖范围(半径:{radius}米)"
    ).add_to(m)
    
    # 绘制基站位置
    folium.Marker(
        location=[lat, lon],
        popup=folium.Popup(f"""
            <div style="width:250px">
                <h4>{gnb['name']} 基站信息</h4>
                <p><b>位置</b>: {lat:.6f}°N, {lon:.6f}°E</p>
                <p><b>高度</b>: {gnb['position']['height']}米</p>
                <p><b>发射功率</b>: {gnb['transmit_power']} dBm</p>
                <p><b>频率</b>: {gnb['carrier_frequency']/1e9:.1f} GHz</p>
                <p><b>带宽</b>: {gnb['channel_bandwidth']/1e6} MHz</p>
                <p><b>资源块</b>: {gnb['num_resource_blocks']}</p>
                <p><b>切片配置</b>:
                    <ul>
                        <li>mMTC: {gnb['slices'][0]['resource_weight']*100}%</li>
                        <li>URLLC: {gnb['slices'][1]['resource_weight']*100}%</li>
                        <li>eMBB: {gnb['slices'][2]['resource_weight']*100}%</li>
                    </ul>
                </p>
            </div>
        """, max_width=300),
        tooltip=f"{gnb['name']} (功率:{gnb['transmit_power']}dBm)",
        icon=folium.Icon(color=gnb_colors[i][1:], icon=gnb_icons[i], prefix='fa')
    ).add_to(m)

# 绘制用户设备(UE)
ue_colors = ['#00ff00', '#ff00ff', '#ffff00', '#00ffff']  # 不同UE使用不同颜色
ue_icons = ['mobile', 'mobile', 'mobile-alt', 'tablet']  # UE图标

for i, ue in enumerate(config['UEs']):
    lat, lon = ue['position']['latitude'], ue['position']['longitude']
    gnb_id = ue['gnb_node_id']
    speed = ue['mobility_model']['speed']
    direction = ue['mobility_model']['direction']
    
    # 找到连接的基站位置
    connected_gnb = next((g for g in config['gNBs'] if g['id'] == gnb_id), None)
    
    # 绘制UE位置和移动方向
    folium.Marker(
        location=[lat, lon],
        popup=folium.Popup(f"""
            <div style="width:250px">
                <h4>{ue['name']} 用户设备</h4>
                <p><b>位置</b>: {lat:.6f}°N, {lon:.6f}°E</p>
                <p><b>业务类型</b>: {ue['business_type']}</p>
                <p><b>优先级</b>: {ue['priority']}</p>
                <p><b>连接基站</b>: gNB_{gnb_id}</p>
                <p><b>移动速度</b>: {speed} m/s ({speed*3.6:.1f} km/h)</p>
                <p><b>移动方向</b>: {direction}°</p>
                <p><b>发射功率</b>: {ue['transmit_power']} dBm</p>
            </div>
        """, max_width=300),
        tooltip=f"{ue['name']} ({ue['business_type']})",
        icon=folium.Icon(color=ue_colors[i][1:], icon=ue_icons[i], prefix='fa')
    ).add_to(m)
    
    # 绘制移动方向箭头
    arrow_length = 50  # 箭头长度（米）
    rad = math.radians(direction)
    end_lat = lat + (arrow_length / 111000) * math.cos(rad)
    end_lon = lon + (arrow_length / (111000 * math.cos(math.radians(lat)))) * math.sin(rad)
    
    folium.PolyLine(
        locations=[(lat, lon), (end_lat, end_lon)],
        color=ue_colors[i],
        weight=2,
        opacity=0.7,
        arrow_heads=True,
        arrow_head_ratio=0.5,
        arrow_head_size=5,
        tooltip=f"移动方向: {direction}°"
    ).add_to(m)
    
    # 绘制UE到基站的连接线
    if connected_gnb:
        gnb_lat = connected_gnb['position']['latitude']
        gnb_lon = connected_gnb['position']['longitude']
        
        folium.PolyLine(
            locations=[(lat, lon), (gnb_lat, gnb_lon)],
            color='#808080',
            weight=1,
            dash_array='5, 5',
            opacity=0.5,
            tooltip=f"{ue['name']} → {connected_gnb['name']}"
        ).add_to(m)

# 添加比例尺
folium.plugins.ScaleBar(position='bottomleft').add_to(m)

# 添加图层控制
folium.LayerControl().add_to(m)

# 添加标题
title_html = '''
    <h3 align="center" style="font-size:16px"><b>北京5G网络部署可视化</b></h3>
    <p align="center" style="font-size:12px">基站覆盖范围与用户设备分布</p>
'''
m.get_root().html.add_child(folium.Element(title_html))

# 添加图例
legend_html = '''
<div style="position: fixed; 
     bottom: 50px; left: 50px; width: 180px; height: 230px; 
     border:2px solid grey; z-index:9999; font-size:12px;
     background-color:white; opacity:0.85; padding:10px;
     border-radius:5px;">
     
     <p style="margin:0"><b>图例说明</b></p>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:15px; background-color:red; margin-right:5px;"></div>
         <span>基站1覆盖范围</span>
     </div>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:15px; background-color:blue; margin-right:5px;"></div>
         <span>基站2覆盖范围</span>
     </div>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:15px; background-color:green; margin-right:5px;"></div>
         <span>用户设备</span>
     </div>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:2px; background-color:gray; margin-right:5px;"></div>
         <span>设备连接</span>
     </div>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:2px; background-color:#ff7800; margin-right:5px;"></div>
         <span>原始监控区域</span>
     </div>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:2px; background-color:#3388ff; margin-right:5px; border-style:dashed;"></div>
         <span>扩大监控区域</span>
     </div>
     <div style="display:flex; align-items:center; margin-top:5px;">
         <div style="width:15px; height:2px; background-color:green; margin-right:5px; border-style:solid;"></div>
         <span>移动方向</span>
     </div>
</div>
'''
m.get_root().html.add_child(folium.Element(legend_html))

# 保存地图
m.save('5g_network_visualization.html')
print("地图已保存为 5g_network_visualization.html")