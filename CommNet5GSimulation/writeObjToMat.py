import yaml
import scipy.io as sio

from models.Client import Client
from models.AntennaArray import AntennaArray
from models.BaseStation import BaseStation
from models.Beamforming import Beamforming
from models.Cell import Cell
from models.ChannelModel import ChannelModel
from models.Distributor import Distributor
from models.Frequency import Frequency
from models.MobilityModel import MobilityModel
from models.PassLossModel import PassLossModel
from models.Noise import Noise
from models.Slice import Slice
from models.SliceBusinessGenerator import SliceBusinessGenerator

def load_network_from_yaml(yaml_file):
    """
    从YAML配置文件加载网络配置并创建相应对象
    
    参数:
        yaml_file (str): YAML配置文件路径
        
    返回:
        dict: 包含创建的网络对象的字典
    """
    # 加载YAML配置
    with open(yaml_file, 'r', encoding='utf-8') as file:
        config = yaml.safe_load(file)
    
    # 创建各种模型和对象
    network = {}
    
    # 存储仿真区域和时间
    network['area'] = config['area']
    network['simulation_time'] = config['simulation_time']
    
    # 创建通道模型
    channel_model = ChannelModel(
        config['channel_model']['type'],
        config['channel_model']['params']
    )
    network['channel_model'] = channel_model
    
    # 创建路径损耗模型
    pass_loss_model = PassLossModel(
        config['pass_loss_model']['type'],
        config['pass_loss_model']['params']
    )
    network['pass_loss_model'] = pass_loss_model
    
    # 创建噪声模型
    noise = Noise(
        config['noise']['type'],
        config['noise']['params']
    )
    network['noise'] = noise
    
    # 创建分布器
    distributors = {}
    for dist_id, dist_config in config['distributors'].items():
        distributor = Distributor(
            dist_config['type'],
            dist_config['params']
        )
        distributors[dist_id] = distributor
    network['distributors'] = distributors
    
    # 创建基站和小区
    base_stations = []
    for bs_config in config['base_stations']:
        # 创建基站对象 (功率单位: mW)
        bs = BaseStation(
            bs_config['id'],
            bs_config['latitude'],
            bs_config['longitude'],
            bs_config['capacity'],  # 使用capacity代替bandwidth
            bs_config['power'] * 1000  # 将W转换为mW
        )
        
        # 创建频谱
        for freq_config in bs_config['frequencies']:
            frequency = Frequency(
                freq_config['name'],
                freq_config['center_frequency'],
                freq_config['range']
            )
            bs.frequencies.append(frequency)
        
        # 创建天线阵列
        antenna = AntennaArray(
            bs_config['antenna']['type'],
            bs_config['antenna']['params']
        )
        bs.antenna_array = antenna
        
        # 创建波束成形算法
        beamforming = Beamforming(
            bs_config['beamforming']['type']
        )
        bs.beamforming = beamforming
        
        # 创建切片
        for slice_config in bs_config['slices']:
            network_slice = Slice(
                slice_config['id'],
                slice_config['type'],
                slice_config['resource_ratio'],
                slice_config['min_sinr_guarantee'],
                slice_config['min_bandwidth_guarantee'],
                slice_config['qos_level']
            )
            bs.slices.append(network_slice)
        
        # 创建小区
        for cell_config in bs_config['cells']:
            cell = Cell(
                cell_config['id'],
                cell_config['use_frequencies'],
                cell_config['bandwidth_weight'],
                cell_config['power_weight'],
                cell_config['power_control_step'],
                cell_config['azimuth_angle'],
                cell_config['sector_angle'],
                cell_config['radius'],
                [s.id for s in bs.slices]  # 使用基站的切片ID列表
            )
            bs.cells.append(cell)
        
        base_stations.append(bs)
    network['base_stations'] = base_stations
    
    # 创建客户端
    clients = []
    for client_config in config['clients']:
        client = Client(
            client_config['id'],
            client_config['latitude'],
            client_config['longitude'],
            client_config['slice_type']
        )
        
        # 创建移动性模型
        mobility_model = MobilityModel(
            client_config['mobility_model']['type'],
            client_config['mobility_model']['params'],
            distributors[client_config['mobility_model']['distributor']]
        )
        client.mobility_model = mobility_model
        
        clients.append(client)
    network['clients'] = clients
    
    # 创建切片业务生成器
    slice_business_generators = []
    for gen_config in config['slice_business_generators']:
        generator = SliceBusinessGenerator(
            # 查找对应类型的切片ID
            next((s.id for bs in base_stations for s in bs.slices if s.type == gen_config['slice_type']), None),
            gen_config['slice_type'],
            distributors[gen_config['distributor']]
        )
        slice_business_generators.append(generator)
    network['slice_business_generators'] = slice_business_generators
    
    return network

def save_network_to_mat(network, output_file='wireless_network_model.mat'):
    """
    将网络配置保存到MAT文件
    
    参数:
        network (dict): 网络对象字典
        output_file (str): 输出MAT文件路径
    """
    data_to_save = {
        'simulation_time': network['simulation_time'],
        'channel_model': network['channel_model'].to_dict(),
        'pass_loss_model': network['pass_loss_model'].to_dict(),
        'noise': network['noise'].to_dict(),
        'base_stations': [bs.to_dict() for bs in network['base_stations']],
        'clients': [client.to_dict() for client in network['clients']],
        'slice_business_generators': [gen.to_dict() for gen in network['slice_business_generators']],
        'area': network['area']
    }
    sio.savemat(output_file, data_to_save)
    print(f"数据已成功保存到 {output_file} 文件中")

def print_network_stats(network):
    """
    打印网络统计信息
    
    参数:
        network (dict): 网络对象字典
    """
    base_stations = network['base_stations']
    clients = network['clients']
    
    print("\n网络概况统计:")
    print(f"总基站数: {len(base_stations)}")
    print(f"总小区数: {sum(len(bs.cells) for bs in base_stations)}")
    print(f"总客户端数: {len(clients)}")
    
    # 计算各类型切片的客户端数量
    slice_types = {1: "eMBB", 2: "URLLC", 3: "mMTC"}
    for slice_id, slice_name in slice_types.items():
        count = sum(1 for c in clients if c.slice_type == slice_id)
        print(f"{slice_name}客户端数: {count}")
    
    print("\n使用频段情况:")
    freq_usage = {}
    for bs in base_stations:
        for freq in bs.frequencies:
            if freq.name in freq_usage:
                freq_usage[freq.name] += 1
            else:
                freq_usage[freq.name] = 1
    
    for freq, count in freq_usage.items():
        print(f"  {freq}: {count}个基站")

    print("\n基站功率情况(mW):")
    for bs in base_stations:
        print(f"  基站ID {bs.id}: {bs.power} mW")  # 显示功率单位为mW

if __name__ == "__main__":
    # 从YAML文件加载网络配置
    network = load_network_from_yaml('config/network_config.yaml')
    
    # 打印网络统计信息
    print_network_stats(network)
    
    # 保存到MAT文件
    save_network_to_mat(network)