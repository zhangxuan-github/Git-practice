import yaml
import scipy.io as sio
import os
import numpy as np

# 指定文件路径
yaml_file = 'gNB_UAV.yaml'
mat_file = 'gNB_UAV.mat'

# 检查输入文件是否存在
if not os.path.exists(yaml_file):
    print(f"错误: 找不到文件 {yaml_file}")
    exit(1)

# 读取YAML文件
with open(yaml_file, 'r', encoding='utf-8') as f:
    try:
        yaml_data = yaml.safe_load(f)
        print("YAML文件读取成功")
    except yaml.YAMLError as e:
        print(f"YAML解析错误: {e}")
        exit(1)

# 递归处理数据，确保所有数据类型都兼容MATLAB
def process_for_matlab(data):
    if isinstance(data, dict):
        return {k: process_for_matlab(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [process_for_matlab(item) for item in data]
    elif isinstance(data, (int, float, str, bool, np.ndarray)):
        return data
    else:
        return str(data)  # 将不兼容的类型转为字符串

# 处理数据使其兼容MATLAB
matlab_data = process_for_matlab(yaml_data)

# 保存为MAT文件
try:
    sio.savemat(mat_file, {'config': matlab_data})
    print(f"转换完成: {yaml_file} -> {mat_file}")
except Exception as e:
    print(f"MAT文件写入错误: {e}")
    exit(1)