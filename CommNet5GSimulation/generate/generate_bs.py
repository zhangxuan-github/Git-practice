import random
import yaml

# 设置北京的纬度和经度范围
LATITUDE_MIN, LATITUDE_MAX = 39.4, 40.2
LONGITUDE_MIN, LONGITUDE_MAX = 115.8, 116.7

# 5G NR标准参数参考
SCS_TO_MAX_RB = {
    15: 275,   # kHz -> 最大资源块数
    30: 275,
    60: 264,
    120: 264
}

BW_TO_MAX_RB = {
    5: 25,     # MHz -> 最大资源块数
    10: 52,
    15: 79,
    20: 106,
    25: 133,
    30: 160,
    40: 216,
    50: 270,
    100: 275
}

# 定义基站类
class GnB:
    def __init__(self):
        self.id = random.randint(1, 1000)
        self.name = f"gNB{self.id}"
        self.position = {
            "latitude": round(random.uniform(LATITUDE_MIN, LATITUDE_MAX), 6),
            "longitude": round(random.uniform(LONGITUDE_MIN, LONGITUDE_MAX), 6),
        }
        self.radius = round(random.uniform(500.0, 1500.0), 1)  # 更合理的覆盖半径范围
        self.noise_figure = round(random.uniform(2.0, 7.0), 1)  # 典型基站噪声系数范围
        
        # 天线配置应符合实际部署
        antenna_choices = [32, 64, 128, 256]  # Massive MIMO配置
        self.num_transmit_antennas = random.choice(antenna_choices)
        
        # 发射功率应符合实际基站范围
        self.transmit_power = round(random.uniform(40.0, 50.0), 1)  # dBm
        
        # 载波频率应符合中国5G频段分配
        self.carrier_frequency = random.choice([3.5e9, 4.9e9])  # n78或n79频段
        
        # 信道带宽应符合5G标准
        bandwidth_choices = [5, 10, 20, 40, 50, 80, 100]  # MHz
        self.channel_bandwidth = random.choice(bandwidth_choices) * 1e6  # 转换为Hz
        
        # 子载波间隔应与带宽匹配
        scs_choices = [15, 30, 60]  # kHz
        self.subcarrier_spacing = random.choice(scs_choices) * 1e3  # 转换为Hz
        
        # 资源块数应根据带宽和SCS计算
        max_rb = min(
            SCS_TO_MAX_RB[self.subcarrier_spacing/1e3], 
            BW_TO_MAX_RB[self.channel_bandwidth/1e6]
        )
        self.num_resource_blocks = random.randint(max_rb//2, max_rb)  # 使用50%-100%资源
        
        self.connected_ues = []
        self.slices = []
        self.mobility_update_interval = random.choice([50, 100, 200])  # 毫秒

    def add_slice(self, slice):
        self.slices.append(slice)

# 定义切片类
class Slice:
    def __init__(self, slice_type):
        self.slice_type = slice_type
        
        # 根据切片类型设置不同的QoS参数
        if slice_type == "URLLC":
            self.qos_level = random.randint(8, 10)  # 最高优先级
            self.min_bandwidth_guarantee = round(random.uniform(5.0, 20.0), 1)  # Mbps
            self.max_latency = random.choice([1, 2, 5])  # 毫秒
        elif slice_type == "eMBB":
            self.qos_level = random.randint(5, 7)
            self.min_bandwidth_guarantee = round(random.uniform(50.0, 200.0), 1)
            self.max_latency = random.choice([10, 20, 50])
        else:  # mMTC
            self.qos_level = random.randint(1, 4)
            self.min_bandwidth_guarantee = round(random.uniform(1.0, 10.0), 1)
            self.max_latency = random.choice([100, 200, 500])
        
        # 切片容量应合理
        self.max_ues = random.randint(50, 500)

# 生成随机的基站列表
def generate_gnbs(num_gnbs):
    gnbs = []
    for _ in range(num_gnbs):
        gnb = GnB()
        
        # 为每个基站添加1-3个切片，确保类型唯一
        slice_types = ["eMBB", "URLLC", "mMTC"]
        num_slices = random.randint(1, min(3, len(slice_types)))
        selected_types = random.sample(slice_types, num_slices)
        
        for slice_type in selected_types:
            gnb.add_slice(Slice(slice_type))
        
        gnbs.append(gnb)
    return gnbs

# 将基站列表转换为字典列表
def gnbs_to_dict(gnbs):
    return [
        {
            "id": gnb.id,
            "name": gnb.name,
            "position": gnb.position,
            "radius": gnb.radius,
            "noise_figure": gnb.noise_figure,
            "num_transmit_antennas": gnb.num_transmit_antennas,
            "transmit_power": gnb.transmit_power,
            "carrier_frequency": gnb.carrier_frequency,
            "channel_bandwidth": gnb.channel_bandwidth,
            "subcarrier_spacing": gnb.subcarrier_spacing,
            "num_resource_blocks": gnb.num_resource_blocks,
            "mobility_update_interval": gnb.mobility_update_interval,
            "connected_ues": gnb.connected_ues,
            "slices": [
                {
                    "slice_type": slice.slice_type,
                    "qos_level": slice.qos_level,
                    "min_bandwidth_guarantee": slice.min_bandwidth_guarantee,
                    "max_latency": slice.max_latency,
                    "max_ues": slice.max_ues
                }
                for slice in gnb.slices
            ],
        }
        for gnb in gnbs
    ]

# 将基站列表保存到YAML文件
def save_to_yaml(gnbs, filename):
    with open(filename, "w") as f:
        yaml.dump({"gnbs": gnbs_to_dict(gnbs)}, f, indent=4)

# 生成指定数量的随机基站并保存到YAML文件
num_gnbs = 10  # 生成10个基站
gnbs = generate_gnbs(num_gnbs)
save_to_yaml(gnbs, "gnbs_config.yaml")