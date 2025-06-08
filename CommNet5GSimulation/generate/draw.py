import yaml
import folium
import numpy as np
from geopy.distance import geodesic
import argparse
import os

def load_yaml_config(file_path):
    """读取YAML配置文件"""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            data = yaml.safe_load(file)
        return data
    except FileNotFoundError:
        print(f"错误: 找不到文件 {file_path}")
        return None
    except yaml.YAMLError as e:
        print(f"错误: YAML文件格式错误 - {e}")
        return None

def create_sample_yaml():
    """创建示例YAML文件"""
    sample_data = {
        'gNBs': [
            {
                'id': 1,
                'name': 'gNB_1',
                'position': {
                    'latitude': 39.908860,
                    'longitude': 116.397390
                },
                'radius': 400,
                'noise_figure': 3,
                'num_transmit_antennas': 16,
                'transmit_power': 43,
                'carrier_frequency': 2600000000,
                'channel_bandwidth': 5000000,
                'subcarrier_spacing': 15000,
                'num_resource_blocks': 273,
                'slices': [
                    {
                        'slice_type': 'mMTC',
                        'qos_level': 10,
                        'min_bandwidth_guarantee': 20000
                    },
                    {
                        'slice_type': 'URLLC',
                        'qos_level': 2,
                        'min_bandwidth_guarantee': 30000
                    },
                    {
                        'slice_type': 'eMBB',
                        'qos_level': 4,
                        'min_bandwidth_guarantee': 20000
                    }
                ]
            },
            {
                'id': 2,
                'name': 'gNB_2',
                'position': {
                    'latitude': 39.909,
                    'longitude': 116.40
                },
                'radius': 400,
                'noise_figure': 4,
                'num_transmit_antennas': 16,
                'transmit_power': 38,
                'carrier_frequency': 2600000000,
                'channel_bandwidth': 5000000,
                'subcarrier_spacing': 15000,
                'num_resource_blocks': 273,
                'slices': [
                    {
                        'slice_type': 'mMTC',
                        'qos_level': 10,
                        'min_bandwidth_guarantee': 20000
                    },
                    {
                        'slice_type': 'URLLC',
                        'qos_level': 2,
                        'min_bandwidth_guarantee': 30000
                    },
                    {
                        'slice_type': 'eMBB',
                        'qos_level': 7,
                        'min_bandwidth_guarantee': 20000
                    }
                ]
            }
        ],
        'UEs': [
            {
                'id': 1,
                'name': 'UE_1',
                'position': {
                    'latitude': 39.910200,
                    'longitude': 116.399450
                },
                'noise_figure': 6,
                'num_transmit_antennas': 1,
                'transmit_power': 17,
                'connection_state': 0,
                'gnb_node_id': 0,
                'business_type': 'eMBB',
                'priority': 7,
                'slice_type': 'eMBB',
                'mobility_model': {
                    'speed': 7,
                    'direction': 113
                }
            },
            {
                'id': 2,
                'name': 'UE_2',
                'position': {
                    'latitude': 39.907500,
                    'longitude': 116.395100
                },
                'noise_figure': 6,
                'num_transmit_antennas': 1,
                'transmit_power': 19,
                'connection_state': 0,
                'gnb_node_id': 0,
                'business_type': 'eMBB',
                'priority': 3,
                'slice_type': 'eMBB',
                'mobility_model': {
                    'speed': 8,
                    'direction': 30
                }
            },
            {
                'id': 3,
                'name': 'UE_3',
                'position': {
                    'latitude': 39.919150,
                    'longitude': 116.399680
                },
                'noise_figure': 6,
                'num_transmit_antennas': 1,
                'transmit_power': 19,
                'connection_state': 0,
                'gnb_node_id': 0,
                'business_type': 'eMBB',
                'priority': 3,
                'slice_type': 'eMBB',
                'mobility_model': {
                    'speed': 8,
                    'direction': 30
                }
            },
            {
                'id': 4,
                'name': 'UE_4',
                'position': {
                    'latitude': 39.915800,
                    'longitude': 116.394800
                },
                'noise_figure': 6,
                'num_transmit_antennas': 1,
                'transmit_power': 19,
                'connection_state': 0,
                'gnb_node_id': 0,
                'business_type': 'eMBB',
                'priority': 3,
                'slice_type': 'eMBB',
                'mobility_model': {
                    'speed': 7,
                    'direction': 250
                }
            }
        ]
    }
    
    with open('5g_network_config.yaml', 'w', encoding='utf-8') as file:
        yaml.dump(sample_data, file, default_flow_style=False, allow_unicode=True)
    
    print("已创建示例YAML文件: 5g_network_config.yaml")
    return sample_data

def get_slice_color(slice_type):
    """根据切片类型返回颜色"""
    colors = {
        'eMBB': 'blue',
        'URLLC': 'red',
        'mMTC': 'green'
    }
    return colors.get(slice_type, 'gray')

def create_5g_network_map(config_data):
    """从配置数据创建5G网络地图"""
    gnbs = config_data.get('gNBs', [])
    ues = config_data.get('UEs', [])
    
    if not gnbs and not ues:
        print("错误: 配置文件中没有找到gNBs或UEs数据")
        return None
    
    # 计算地图中心点
    all_lats = []
    all_lons = []
    
    for gnb in gnbs:
        all_lats.append(gnb['position']['latitude'])
        all_lons.append(gnb['position']['longitude'])
    
    for ue in ues:
        all_lats.append(ue['position']['latitude'])
        all_lons.append(ue['position']['longitude'])
    
    if not all_lats:
        print("错误: 无法获取坐标信息")
        return None
    
    center_lat = sum(all_lats) / len(all_lats)
    center_lon = sum(all_lons) / len(all_lons)
    
    # 创建地图
    m = folium.Map(
        location=[center_lat, center_lon],
        zoom_start=15,
        tiles='OpenStreetMap'
    )
    
    # 添加基站和覆盖范围
    for gnb in gnbs:
        lat = gnb['position']['latitude']
        lon = gnb['position']['longitude']
        
        # 构建基站信息弹窗
        slices_info = ""
        if 'slices' in gnb:
            slices_info = "<br><b>网络切片:</b><br>"
            for slice_info in gnb['slices']:
                slices_info += f"- {slice_info['slice_type']}: QoS={slice_info['qos_level']}<br>"
        
        popup_text = f"""
        <b>{gnb['name']}</b><br>
        ID: {gnb['id']}<br>
        发射功率: {gnb['transmit_power']} dBm<br>
        噪声系数: {gnb['noise_figure']} dB<br>
        覆盖半径: {gnb['radius']} m<br>
        天线数: {gnb['num_transmit_antennas']}<br>
        载波频率: {gnb['carrier_frequency']/1e9:.1f} GHz<br>
        信道带宽: {gnb['channel_bandwidth']/1e6:.0f} MHz<br>
        子载波间隔: {gnb['subcarrier_spacing']/1000:.0f} kHz<br>
        资源块数: {gnb['num_resource_blocks']}
        {slices_info}
        """
        
        # 基站标记
        folium.Marker(
            [lat, lon],
            popup=folium.Popup(popup_text, max_width=300),
            tooltip=gnb['name'],
            icon=folium.Icon(color='red', icon='broadcast-tower', prefix='fa')
        ).add_to(m)
        
        # 覆盖范围圆圈
        folium.Circle(
            location=[lat, lon],
            radius=gnb['radius'],
            popup=f"{gnb['name']} 覆盖范围 ({gnb['radius']}m)",
            color='red',
            fillColor='red',
            fillOpacity=0.1,
            weight=2
        ).add_to(m)
    
    # 添加用户设备
    ue_colors = ['blue', 'green', 'purple', 'orange', 'darkblue', 'darkgreen']
    
    for i, ue in enumerate(ues):
        lat = ue['position']['latitude']
        lon = ue['position']['longitude']
        
        # 计算与各基站的距离
        distances_info = "<br><b>距离基站:</b><br>"
        closest_gnb = None
        min_distance = float('inf')
        
        for gnb in gnbs:
            gnb_lat = gnb['position']['latitude']
            gnb_lon = gnb['position']['longitude']
            
            dist = geodesic((lat, lon), (gnb_lat, gnb_lon)).meters
            coverage_status = "✓覆盖" if dist <= gnb['radius'] else "✗超出"
            distances_info += f"- {gnb['name']}: {dist:.1f}m ({coverage_status})<br>"
            
            if dist < min_distance:
                min_distance = dist
                closest_gnb = gnb
        
        # 构建UE信息弹窗
        mobility_info = ""
        if 'mobility_model' in ue:
            mobility_info = f"""
            移动速度: {ue['mobility_model']['speed']} m/s<br>
            移动方向: {ue['mobility_model']['direction']}°<br>
            """
        
        popup_text = f"""
        <b>{ue['name']}</b><br>
        ID: {ue['id']}<br>
        业务类型: {ue['business_type']}<br>
        切片类型: {ue['slice_type']}<br>
        优先级: {ue['priority']}<br>
        发射功率: {ue['transmit_power']} dBm<br>
        噪声系数: {ue['noise_figure']} dB<br>
        天线数: {ue['num_transmit_antennas']}<br>
        {mobility_info}
        {distances_info}
        """
        
        # 根据切片类型选择颜色
        ue_color = get_slice_color(ue.get('slice_type', 'eMBB'))
        
        # 用户设备标记
        folium.Marker(
            [lat, lon],
            popup=folium.Popup(popup_text, max_width=300),
            tooltip=ue['name'],
            icon=folium.Icon(color=ue_color, icon='mobile', prefix='fa')
        ).add_to(m)
        
        # 添加移动方向箭头（如果有移动信息）
        if 'mobility_model' in ue and ue['mobility_model']['speed'] > 0:
            direction = ue['mobility_model']['direction']
            speed = ue['mobility_model']['speed']
            
            # 箭头长度根据速度调整
            arrow_length = 0.0005 * (speed / 10)  # 基础长度乘以速度因子
            
            end_lat = lat + arrow_length * np.cos(np.radians(direction))
            end_lon = lon + arrow_length * np.sin(np.radians(direction))
            
            folium.PolyLine(
                locations=[[lat, lon], [end_lat, end_lon]],
                color=ue_color,
                weight=4,
                opacity=0.8,
                popup=f"{ue['name']} 移动方向: {direction}°, 速度: {speed}m/s"
            ).add_to(m)
    
    # 添加图例
    legend_html = f'''
    <div style="position: fixed; 
                bottom: 50px; left: 50px; width: 250px; height: 200px; 
                background-color: white; border:2px solid grey; z-index:9999; 
                font-size:12px; padding: 10px">
    <p><b>5G网络图例</b></p>
    <p><i class="fa fa-broadcast-tower" style="color:red"></i> 基站 (gNB)</p>
    <p><i class="fa fa-mobile" style="color:blue"></i> eMBB用户</p>
    <p><i class="fa fa-mobile" style="color:red"></i> URLLC用户</p>
    <p><i class="fa fa-mobile" style="color:green"></i> mMTC用户</p>
    <p>🔴 覆盖范围</p>
    <p>→ 移动方向</p>
    <p><small>基站数: {len(gnbs)}, 用户数: {len(ues)}</small></p>
    </div>
    '''
    m.get_root().html.add_child(folium.Element(legend_html))
    
    return m

def print_network_analysis(config_data):
    """打印网络分析信息"""
    gnbs = config_data.get('gNBs', [])
    ues = config_data.get('UEs', [])
    
    print("=" * 60)
    print("5G网络配置分析")
    print("=" * 60)
    
    print(f"\n📡 基站信息 (共{len(gnbs)}个):")
    for gnb in gnbs:
        print(f"  {gnb['name']} (ID: {gnb['id']})")
        print(f"    位置: ({gnb['position']['latitude']:.6f}, {gnb['position']['longitude']:.6f})")
        print(f"    覆盖: {gnb['radius']}m, 功率: {gnb['transmit_power']}dBm")
        print(f"    频率: {gnb['carrier_frequency']/1e9:.1f}GHz, 带宽: {gnb['channel_bandwidth']/1e6:.0f}MHz")
        if 'slices' in gnb:
            print(f"    切片: {', '.join([s['slice_type'] for s in gnb['slices']])}")
    
    print(f"\n📱 用户设备信息 (共{len(ues)}个):")
    for ue in ues:
        print(f"  {ue['name']} (ID: {ue['id']})")
        print(f"    位置: ({ue['position']['latitude']:.6f}, {ue['position']['longitude']:.6f})")
        print(f"    类型: {ue['business_type']}, 切片: {ue['slice_type']}, 优先级: {ue['priority']}")
        if 'mobility_model' in ue:
            print(f"    移动: {ue['mobility_model']['speed']}m/s, 方向: {ue['mobility_model']['direction']}°")
        
        # 计算与各基站的距离
        print("    距离基站:")
        for gnb in gnbs:
            dist = geodesic(
                (ue['position']['latitude'], ue['position']['longitude']),
                (gnb['position']['latitude'], gnb['position']['longitude'])
            ).meters
            status = "✓" if dist <= gnb['radius'] else "✗"
            print(f"      {gnb['name']}: {dist:.1f}m {status}")
    
    # 基站间距离分析
    if len(gnbs) > 1:
        print(f"\n🔗 基站间距离:")
        for i in range(len(gnbs)):
            for j in range(i+1, len(gnbs)):
                dist = geodesic(
                    (gnbs[i]['position']['latitude'], gnbs[i]['position']['longitude']),
                    (gnbs[j]['position']['latitude'], gnbs[j]['position']['longitude'])
                ).meters
                print(f"  {gnbs[i]['name']} ↔ {gnbs[j]['name']}: {dist:.1f}m")

def main():
    parser = argparse.ArgumentParser(description='5G网络配置可视化工具')
    parser.add_argument('-f', '--file', default='5g_nr_simulation_data.yaml',
                       help='YAML配置文件路径 (默认: 5g_nr_simulation_data.yaml)')
    parser.add_argument('-o', '--output', default='5g_network_map.html',
                       help='输出HTML文件名 (默认: 5g_network_map.html)')
    parser.add_argument('--create-sample', action='store_true',
                       help='创建示例YAML配置文件')
    
    args = parser.parse_args()
    
    # 如果需要创建示例文件
    # if args.create_sample:
    #     create_sample_yaml()
    #     return
    
    # 检查配置文件是否存在
    if not os.path.exists(args.file):
        print(f"配置文件 {args.file} 不存在。")
        print("使用 --create-sample 参数创建示例配置文件。")
        return
    
    # 读取配置文件
    config_data = load_yaml_config(args.file)
    if config_data is None:
        return
    
    # 创建地图
    network_map = create_5g_network_map(config_data)
    if network_map is None:
        return
    
    # 保存地图
    network_map.save(args.output)
    print(f"✅ 地图已保存为 '{args.output}'")
    
    # 打印网络分析
    print_network_analysis(config_data)
    
    print(f"\n📋 使用说明:")
    print(f"1. 用浏览器打开 '{args.output}' 查看交互式地图")
    print("2. 点击标记查看详细信息")
    print("3. 红色圆圈表示基站覆盖范围")
    print("4. 彩色箭头表示用户设备移动方向")
    print("5. 不同颜色表示不同的网络切片类型")

if __name__ == "__main__":
    main()