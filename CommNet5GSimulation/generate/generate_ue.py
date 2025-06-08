import random
import yaml

# 设置北京的纬度和经度范围
LATITUDE_MAX = 40.2
LATITUDE_MIN = 39.4
LONGITUDE_MAX = 116.7
LONGITUDE_MIN = 115.8

# 设置速度和方向的范围
SPEED_MIN = 0.0
SPEED_MAX = 15.0
DIRECTION_MIN = 0.0
DIRECTION_MAX = 360.0

def generate_ue():
    """生成随机的UE配置"""
    ue = {
        'id': random.randint(1, 1000),
        'name': f'UE{random.randint(1, 1000)}',
        'position': {
            'latitude': round(random.uniform(LATITUDE_MIN, LATITUDE_MAX), 4),
            'longitude': round(random.uniform(LONGITUDE_MIN, LONGITUDE_MAX), 4)
        },
        'noiseFigure': round(random.uniform(5.0, 10.0), 1),
        'numTransmitAntennas': random.randint(1, 8),
        'transmitPower': round(random.uniform(20.0, 30.0), 1),
        'connectionState': 'Connected' if random.randint(0, 1) else 'Idle',
        'gnbNodeId': -1,
        'businessType': random.choice(['Data', 'Voice', 'Video']),
        'priority': random.randint(0, 10),
        'sliceType': random.choice(['eMBB', 'URLLC', 'mMTC']),
        'mobilityModel': {
            'speed': {
                'min': SPEED_MIN,
                'max': round(random.uniform(SPEED_MIN, SPEED_MAX), 1)
            },
            'direction': round(random.uniform(DIRECTION_MIN, DIRECTION_MAX), 1)
        }
    }
    return ue

def generate_ue_list(num_ues):
    """生成指定数量的随机UE列表"""
    return [generate_ue() for _ in range(num_ues)]

def save_to_yaml(ue_list, filename):
    """将UE列表保存到YAML文件"""
    with open(filename, 'w') as file:
        yaml.dump({'ueList': ue_list}, file, default_flow_style=False, indent=4)

# 生成指定数量的随机UE并保存到YAML文件
num_ues = 10  # 你可以更改这个数字来生成不同数量的UE
ue_list = generate_ue_list(num_ues)
save_to_yaml(ue_list, 'random_ues.yaml')