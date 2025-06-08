import random
import yaml
import numpy as np
from dataclasses import dataclass
from typing import List, Tuple, Dict, Any
from scipy.io import savemat

@dataclass
class nrSlice:
    """5G网络切片类"""
    sliceType: str
    qosLevel: int
    minBandwidthGuarantee: int  # 改为int类型，单位为Hz

@dataclass
class nrMobilityModel:
    """移动模型类"""
    speed: float  # m/s
    direction: float  # 度数 (0-360)

@dataclass
class nrGNB:
    """5G基站类"""
    id: int
    name: str
    position: Tuple[float, float]  # (latitude, longitude)
    radius: float  # 覆盖半径 (米)
    noiseFigure: float  # dB
    numTransmitAntennas: int
    transmitPower: float  # dBm
    carrierFrequency: float  # Hz
    channelBandwidth: float  # Hz
    subcarrierSpacing: float  # Hz
    numResourceBlocks: int
    slices: List[nrSlice]

@dataclass
class nrUE:
    """5G用户设备类"""
    id: int
    name: str
    position: Tuple[float, float]  # (latitude, longitude)
    noiseFigure: float  # dB
    numTransmitAntennas: int
    transmitPower: float  # dBm
    connectionState: int  # 0=Idle, 1=Connected
    gnbNodeId: int
    businessType: str
    priority: int
    sliceType: str
    mobilityModel: nrMobilityModel

class NRDataGenerator:
    """5G NR数据生成器"""
    
    # 标准载波频率定义 (使用规整的频率值)
    STANDARD_CARRIER_FREQUENCIES = {
        'FR1': [
            700e6,   # n28
            1800e6,  # n3  
            1900e6,  # n1
            2100e6,  # n1
            2600e6,  # n7
            3500e6,  # n78
            3700e6,  # n78
            4500e6,  # n79
            4900e6,  # n79
        ],
        'FR2': [
            26.5e9,  # n257
            28.0e9,  # n257/n261
            37.0e9,  # n260
            39.0e9,  # n260
        ]
    }
    
    # 子载波间距选项 (Hz)
    SCS_OPTIONS = {
        'FR1': [15e3, 30e3, 60e3],      # FR1支持的SCS
        'FR2': [60e3, 120e3, 240e3]     # FR2支持的SCS
    }
    
    # 信道带宽选项 (Hz)
    BANDWIDTH_OPTIONS = {
        'FR1': [5e6, 10e6, 15e6, 20e6, 25e6, 30e6, 40e6, 50e6, 60e6, 70e6, 80e6, 90e6, 100e6],
        'FR2': [50e6, 100e6, 200e6, 400e6]
    }
    
    # 业务类型
    BUSINESS_TYPES = ['eMBB', 'URLLC', 'mMTC', 'Industrial', 'Automotive', 'Entertainment']
    
    # 切片类型
    SLICE_TYPES = ['eMBB', 'URLLC', 'mMTC', 'Custom']
    
    def __init__(self, area_bounds: Tuple[float, float, float, float] = (39.9, 40.1, 116.3, 116.5)):
        """
        初始化数据生成器
        area_bounds: (lat_min, lat_max, lon_min, lon_max) 区域边界
        """
        self.area_bounds = area_bounds
        
    def calculate_num_resource_blocks(self, bandwidth: float, scs: float) -> int:
        """
        根据带宽和子载波间距计算资源块数量
        NR资源块 = 12个子载波
        """
        num_subcarriers = int(bandwidth / scs)
        num_rb = num_subcarriers // 12
        
        # 5G NR标准的RB数量限制
        max_rb_mapping = {
            5e6: 25, 10e6: 52, 15e6: 79, 20e6: 106, 25e6: 133,
            30e6: 160, 40e6: 216, 50e6: 270, 60e6: 324, 70e6: 378,
            80e6: 432, 90e6: 486, 100e6: 540, 200e6: 1080, 400e6: 2160
        }
        
        return min(num_rb, max_rb_mapping.get(bandwidth, num_rb))
    
    def generate_gnb_params(self, band_type: str = 'mixed', force_params: Dict = None) -> Dict[str, Any]:
        """
        生成符合5G NR规范的基站参数
        force_params: 强制使用的参数，用于创建相同射频参数的基站组
        """
        
        if force_params:
            # 使用强制参数（用于创建相同射频参数的基站）
            return force_params.copy()
        
        # 选择频段类型
        if band_type == 'FR1':
            carrier_freqs = self.STANDARD_CARRIER_FREQUENCIES['FR1']
            scs_options = self.SCS_OPTIONS['FR1']
            bw_options = self.BANDWIDTH_OPTIONS['FR1']
        elif band_type == 'FR2':
            carrier_freqs = self.STANDARD_CARRIER_FREQUENCIES['FR2']
            scs_options = self.SCS_OPTIONS['FR2']
            bw_options = self.BANDWIDTH_OPTIONS['FR2']
        else:  # mixed
            if random.random() < 0.8:  # 80% FR1, 20% FR2
                carrier_freqs = self.STANDARD_CARRIER_FREQUENCIES['FR1']
                scs_options = self.SCS_OPTIONS['FR1']
                bw_options = self.BANDWIDTH_OPTIONS['FR1']
            else:
                carrier_freqs = self.STANDARD_CARRIER_FREQUENCIES['FR2']
                scs_options = self.SCS_OPTIONS['FR2']
                bw_options = self.BANDWIDTH_OPTIONS['FR2']
        
        # 选择标准载波频率
        carrier_freq = random.choice(carrier_freqs)
        
        # 选择子载波间距
        scs = 30
        
        # 选择信道带宽
        bandwidth = random.choice(bw_options)
        
        # 计算资源块数量
        num_rb = self.calculate_num_resource_blocks(bandwidth, scs)
        
        return {
            'carrierFrequency': carrier_freq,
            'subcarrierSpacing': scs,
            'channelBandwidth': bandwidth,
            'numResourceBlocks': num_rb,
        }
    
    def generate_slice(self) -> nrSlice:
        """生成网络切片"""
        slice_type = random.choice(self.SLICE_TYPES)
        
        # 根据切片类型设置QoS等级和带宽保证
        if slice_type == 'URLLC':
            qos_level = random.randint(1, 3)  # 高优先级
            min_bw = random.randint(1000000, 10000000)  # 1-10 MHz (int)
        elif slice_type == 'eMBB':
            qos_level = random.randint(4, 7)  # 中等优先级
            min_bw = random.randint(10000000, 100000000)  # 10-100 MHz (int)
        elif slice_type == 'mMTC':
            qos_level = random.randint(8, 10)  # 低优先级
            min_bw = random.randint(100000, 5000000)  # 0.1-5 MHz (int)
        else:  # Custom
            qos_level = random.randint(1, 10)
            min_bw = random.randint(1000000, 50000000)  # 1-50 MHz (int)
            
        return nrSlice(slice_type, qos_level, min_bw)
    
    def generate_mobility_model(self) -> nrMobilityModel:
        """生成移动模型"""
        # 速度范围：0-120 km/h (转换为 m/s)
        speed_kmh = random.uniform(0, 120)
        speed_ms = speed_kmh / 3.6
        
        # 方向：0-360度
        direction = random.uniform(0, 360)
        
        return nrMobilityModel(speed_ms, direction)
    
    def generate_position(self) -> Tuple[float, float]:
        """在指定区域内生成随机位置"""
        lat_min, lat_max, lon_min, lon_max = self.area_bounds
        lat = random.uniform(lat_min, lat_max)
        lon = random.uniform(lon_min, lon_max)
        return (lat, lon)
    
    def generate_gnb(self, gnb_id: int, band_type: str = 'mixed', force_params: Dict = None) -> nrGNB:
        """
        生成5G基站
        force_params: 强制使用的射频参数，用于创建相同射频参数的基站组
        """
        gnb_params = self.generate_gnb_params(band_type, force_params)
        
        # 生成切片（1-3个切片）
        num_slices = random.randint(1, 3)
        slices = [self.generate_slice() for _ in range(num_slices)]
        
        gnb = nrGNB(
            id=gnb_id,
            name=f"gNB_{gnb_id}",
            position=self.generate_position(),
            radius=random.uniform(100, 2000),  # 100m - 2km覆盖半径
            noiseFigure=random.uniform(2.0, 5.0),  # 2-5 dB
            numTransmitAntennas=random.choice([2, 4, 8, 16, 32, 64]),
            transmitPower=random.uniform(30, 46),  # 30-46 dBm
            carrierFrequency=gnb_params['carrierFrequency'],
            channelBandwidth=gnb_params['channelBandwidth'],
            subcarrierSpacing=gnb_params['subcarrierSpacing'],
            numResourceBlocks=gnb_params['numResourceBlocks'],
            slices=slices
        )
        
        return gnb
    
    def generate_ue(self, ue_id: int, gnb_list: List[nrGNB]) -> nrUE:
        """生成5G用户设备"""
        # 选择连接的基站
        connected_gnb = random.choice(gnb_list) if gnb_list else None
        connection_state = 1 if connected_gnb and random.random() > 0.1 else 0
        gnb_node_id = connected_gnb.id if connected_gnb else 0
        
        # 选择切片类型
        if connected_gnb and connected_gnb.slices:
            slice_type = random.choice(connected_gnb.slices).sliceType
        else:
            slice_type = random.choice(self.SLICE_TYPES)
        
        ue = nrUE(
            id=ue_id,
            name=f"UE_{ue_id}",
            position=self.generate_position(),
            noiseFigure=random.uniform(5.0, 9.0),  # 5-9 dB (UE噪声较高)
            numTransmitAntennas=random.choice([1, 2, 4]),  # UE天线数较少
            transmitPower=random.uniform(10, 23),  # 10-23 dBm (UE功率较低)
            connectionState=connection_state,
            gnbNodeId=gnb_node_id,
            businessType=random.choice(self.BUSINESS_TYPES),
            priority=random.randint(1, 10),
            sliceType=slice_type,
            mobilityModel=self.generate_mobility_model()
        )
        
        return ue
    
    def generate_interference_groups(self, num_groups: int = 3, gnbs_per_group: List[int] = None) -> List[Dict]:
        """
        生成干扰组 - 每组内的基站使用相同的射频参数
        num_groups: 干扰组数量
        gnbs_per_group: 每组的基站数量列表
        """
        if gnbs_per_group is None:
            gnbs_per_group = [random.randint(2, 4) for _ in range(num_groups)]
        
        interference_groups = []
        
        for group_id in range(num_groups):
            # 为该组生成统一的射频参数
            group_params = self.generate_gnb_params('mixed')
            
            group_info = {
                'group_id': group_id + 1,
                'params': group_params,
                'num_gnbs': gnbs_per_group[group_id],
                'description': f"干扰组{group_id + 1} - "
                             f"载波频率: {group_params['carrierFrequency']/1e9:.1f}GHz, "
                             f"带宽: {group_params['channelBandwidth']/1e6:.0f}MHz, "
                             f"SCS: {group_params['subcarrierSpacing']/1e3:.0f}kHz"
            }
            interference_groups.append(group_info)
        
        return interference_groups


def to_camel_case(snake_str):
    """
    将下划线分隔的字符串转换为小驼峰格式
    例如: slice_type -> sliceType
    """
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def convert_to_camel_case(data):
    """
    递归地将所有字典键转换为小驼峰格式
    
    Args:
        data: 要转换的数据结构 (dict, list, 或基本类型)
    
    Returns:
        转换后的数据结构
    """
    if isinstance(data, dict):
        new_dict = {}
        for key, value in data.items():
            # 已经是驼峰格式的键不需要转换
            if '_' not in key and key[0].islower() and any(c.isupper() for c in key[1:]):
                camel_key = key
            else:
                camel_key = to_camel_case(key)
            # 递归转换值
            new_dict[camel_key] = convert_to_camel_case(value)
        return new_dict
    elif isinstance(data, list):
        return [convert_to_camel_case(item) for item in data]
    else:
        return data


def yaml_to_mat(yaml_file, mat_file):
    """
    将YAML文件转换为MATLAB .mat文件，并将所有属性名称转换为小驼峰格式
    
    Args:
        yaml_file (str): YAML文件路径
        mat_file (str): .mat文件保存路径
    """
    # 加载YAML数据
    with open(yaml_file, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    
    # 转换键为小驼峰格式
    data_camel = convert_to_camel_case(data)
    
    # 打印转换前后的示例（用于验证）
    print("\n转换示例:")
    if isinstance(data, dict) and 'gnbs' in data and data['gnbs'] and isinstance(data['gnbs'][0], dict):
        first_gnb_original = data['gnbs'][0]
        first_gnb_camel = data_camel['gnbs'][0]
        print("原始格式 (snake_case):")
        for key in list(first_gnb_original.keys())[:5]:  # 打印前5个键
            print(f"  {key}: {first_gnb_original[key]}")
        
        print("\n转换后格式 (camelCase):")
        for key in list(first_gnb_camel.keys())[:5]:  # 打印前5个键
            print(f"  {key}: {first_gnb_camel[key]}")
    
    # 保存为.mat文件
    savemat(mat_file, data_camel)
    print(f"数据已转换并保存到 '{mat_file}'")


def main():
    """主函数 - 生成示例数据"""
    # 初始化生成器 (北京区域)
    generator = NRDataGenerator(area_bounds=(39.8, 40.2, 116.2, 116.6))
    
    # 设置基站生成参数
    num_gnbs = 15
    num_interference_groups = 3  # 干扰组数量
    gnbs_per_group = [3, 4, 2]  # 每组的基站数量
    
    # 生成干扰组
    interference_groups = generator.generate_interference_groups(num_interference_groups, gnbs_per_group)
    
    print("=== 5G NR 网络仿真数据生成器 ===\n")
    print("干扰组配置:")
    for group in interference_groups:
        print(f"  {group['description']}")
    
    # 生成基站
    gnb_list = []
    gnb_id = 1
    
    print(f"\n生成{num_gnbs}个5G基站...")
    
    # 先生成干扰组内的基站
    for group in interference_groups:
        print(f"\n--- {group['description']} ---")
        for i in range(group['num_gnbs']):
            gnb = generator.generate_gnb(gnb_id, force_params=group['params'])
            gnb_list.append(gnb)
            
            print(f"基站 {gnb.id}: {gnb.name}")
            print(f"  位置: ({gnb.position[0]:.4f}, {gnb.position[1]:.4f})")
            print(f"  载波频率: {gnb.carrierFrequency/1e9:.1f} GHz")
            print(f"  子载波间距: {gnb.subcarrierSpacing/1e3:.0f} kHz")
            print(f"  信道带宽: {gnb.channelBandwidth/1e6:.0f} MHz")
            print(f"  资源块数: {gnb.numResourceBlocks}")
            print(f"  发射功率: {gnb.transmitPower:.1f} dBm")
            print(f"  天线数: {gnb.numTransmitAntennas}")
            print(f"  覆盖半径: {gnb.radius:.0f} m")
            
            gnb_id += 1
    
    # 生成剩余的独立基站
    remaining_gnbs = num_gnbs - sum(gnbs_per_group)
    if remaining_gnbs > 0:
        print(f"\n--- 独立基站 (无干扰组) ---")
        for i in range(remaining_gnbs):
            gnb = generator.generate_gnb(gnb_id, band_type='mixed')
            gnb_list.append(gnb)
            
            print(f"基站 {gnb.id}: {gnb.name}")
            print(f"  位置: ({gnb.position[0]:.4f}, {gnb.position[1]:.4f})")
            print(f"  载波频率: {gnb.carrierFrequency/1e9:.1f} GHz")
            print(f"  子载波间距: {gnb.subcarrierSpacing/1e3:.0f} kHz")
            print(f"  信道带宽: {gnb.channelBandwidth/1e6:.0f} MHz")
            print(f"  资源块数: {gnb.numResourceBlocks}")
            
            gnb_id += 1
    
    # 生成用户设备
    num_ues = 50
    ue_list = []
    
    print(f"\n\n生成{num_ues}个用户设备...")
    for i in range(num_ues):
        ue = generator.generate_ue(i + 1, gnb_list)
        ue_list.append(ue)
    
    # 统计信息
    connected_ues = sum(1 for ue in ue_list if ue.connectionState == 1)
    fr1_count = sum(1 for gnb in gnb_list if gnb.carrierFrequency < 6e9)
    fr2_count = len(gnb_list) - fr1_count
    
    print(f"\n=== 网络统计信息 ===")
    print(f"基站总数: {len(gnb_list)}")
    print(f"  - FR1基站: {fr1_count}")
    print(f"  - FR2基站: {fr2_count}")
    print(f"用户设备总数: {len(ue_list)}")
    print(f"已连接UE数量: {connected_ues}")
    print(f"连接率: {connected_ues/len(ue_list)*100:.1f}%")
    
    # 干扰分析
    print(f"\n=== 干扰分析 ===")
    print(f"干扰组数量: {len(interference_groups)}")
    
    # 统计每个干扰组的详细信息
    for group in interference_groups:
        group_gnbs = [gnb for gnb in gnb_list 
                     if gnb.carrierFrequency == group['params']['carrierFrequency'] and
                        gnb.channelBandwidth == group['params']['channelBandwidth'] and
                        gnb.subcarrierSpacing == group['params']['subcarrierSpacing']]
        
        print(f"\n干扰组 {group['group_id']}:")
        print(f"  载波频率: {group['params']['carrierFrequency']/1e9:.1f} GHz")
        print(f"  信道带宽: {group['params']['channelBandwidth']/1e6:.0f} MHz")
        print(f"  子载波间距: {group['params']['subcarrierSpacing']/1e3:.0f} kHz")
        print(f"  基站数量: {len(group_gnbs)}")
        print(f"  基站ID: {[gnb.id for gnb in group_gnbs]}")
        
        # 计算组内基站的平均距离（用于干扰强度估算）
        if len(group_gnbs) > 1:
            distances = []
            for i, gnb1 in enumerate(group_gnbs):
                for gnb2 in group_gnbs[i+1:]:
                    # 简单的距离计算（假设地球是平面）
                    lat_diff = gnb1.position[0] - gnb2.position[0]
                    lon_diff = gnb1.position[1] - gnb2.position[1]
                    distance = ((lat_diff * 111000)**2 + (lon_diff * 111000 * np.cos(np.radians(gnb1.position[0])))**2)**0.5
                    distances.append(distance)
            
            avg_distance = np.mean(distances)
            min_distance = min(distances)
            print(f"  平均站间距离: {avg_distance:.0f} m")
            print(f"  最小站间距离: {min_distance:.0f} m")
    
    # 载波频率分布
    freq_distribution = {}
    for gnb in gnb_list:
        freq_ghz = gnb.carrierFrequency / 1e9
        freq_key = f"{freq_ghz:.1f}GHz"
        freq_distribution[freq_key] = freq_distribution.get(freq_key, 0) + 1
    
    print(f"\n=== 载波频率分布 ===")
    for freq, count in sorted(freq_distribution.items()):
        print(f"{freq}: {count}个基站")
    
    # 保存数据到YAML文件
    save_data = input("\n是否保存数据到YAML文件? (y/n): ")
    if save_data.lower() == 'y':
        # 转换为可序列化的格式
        gnb_data = []
        for gnb in gnb_list:
            gnb_dict = {
                'id': gnb.id,
                'name': gnb.name,
                'position': {
                    'latitude': gnb.position[0],
                    'longitude': gnb.position[1]
                },
                'radius': gnb.radius,
                'noise_figure': gnb.noiseFigure,
                'num_transmit_antennas': gnb.numTransmitAntennas,
                'transmit_power': gnb.transmitPower,
                'carrier_frequency': gnb.carrierFrequency,
                'channel_bandwidth': gnb.channelBandwidth,
                'subcarrier_spacing': gnb.subcarrierSpacing,
                'num_resource_blocks': gnb.numResourceBlocks,
                'slices': [{'slice_type': s.sliceType, 'qos_level': s.qosLevel, 'min_bandwidth_guarantee': s.minBandwidthGuarantee} for s in gnb.slices]
            }
            gnb_data.append(gnb_dict)
        
        ue_data = []
        for ue in ue_list:
            ue_dict = {
                'id': ue.id,
                'name': ue.name,
                'position': {
                    'latitude': ue.position[0],
                    'longitude': ue.position[1]
                },
                'noise_figure': ue.noiseFigure,
                'num_transmit_antennas': ue.numTransmitAntennas,
                'transmit_power': ue.transmitPower,
                'connection_state': ue.connectionState,
                'gnb_node_id': ue.gnbNodeId,
                'business_type': ue.businessType,
                'priority': ue.priority,
                'slice_type': ue.sliceType,
                'mobility_model': {'speed': ue.mobilityModel.speed, 'direction': ue.mobilityModel.direction}
            }
            ue_data.append(ue_dict)
        
        # 添加干扰组信息
        interference_groups_data = []
        for group in interference_groups:
            group_data = {
                'group_id': group['group_id'],
                'carrier_frequency': group['params']['carrierFrequency'],
                'channel_bandwidth': group['params']['channelBandwidth'],
                'subcarrier_spacing': group['params']['subcarrierSpacing'],
                'num_resource_blocks': group['params']['numResourceBlocks'],
                'gnb_ids': [gnb.id for gnb in gnb_list 
                           if gnb.carrierFrequency == group['params']['carrierFrequency'] and
                              gnb.channelBandwidth == group['params']['channelBandwidth'] and
                              gnb.subcarrierSpacing == group['params']['subcarrierSpacing']],
                'description': group['description']
            }
            interference_groups_data.append(group_data)
        
        data_export = {
            'gnbs': gnb_data,
            'ues': ue_data,
            'interference_groups': interference_groups_data,
            'metadata': {
                'num_gnbs': len(gnb_list),
                'num_ues': len(ue_list),
                'num_interference_groups': len(interference_groups),
                'area_bounds': generator.area_bounds,
                'generation_time': str(np.datetime64('now')),
                'description': '5G NR网络仿真数据 - 包含干扰组信息'
            }
        }
        
        yaml_file = '5g_nr_simulation_data.yaml'
        with open(yaml_file, 'w', encoding='utf-8') as f:
            yaml.dump(data_export, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
        
        print(f"数据已保存到 '{yaml_file}'")
        
        # 询问是否转换为MAT文件
        convert_to_mat = input("是否将YAML数据转换为MATLAB .mat文件? (y/n): ")
        if convert_to_mat.lower() == 'y':
            mat_file = '5g_nr_simulation_data.mat'
            yaml_to_mat(yaml_file, mat_file)
            print("YAML数据已转换为小驼峰格式并保存为MATLAB .mat文件")
            print("文件包含基站、UE和干扰组的完整信息，可用于MATLAB中的网络仿真和干扰分析。")


if __name__ == "__main__":
    main()