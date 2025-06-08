import yaml
import numpy as np
from scipy.io import savemat


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
            # 转换键为小驼峰格式
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
    
    # 保存为.mat文件
    savemat(mat_file, data_camel)
    print(f"数据已转换并保存到 '{mat_file}'")
    
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


if __name__ == "__main__":
    yaml_file = "D:/Project/NanJing28Institute/CommNet5GSimulation/5g_nr_simulation_data.yaml"
    mat_file = "D:/Project/NanJing28Institute/CommNet5GSimulation/5g_nr_simulation_data.mat"
    yaml_to_mat(yaml_file, mat_file)