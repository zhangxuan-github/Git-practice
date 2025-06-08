





import os
import matlab.engine
import numpy as np

# 获取当前 Python 脚本所在目录
script_dir = os.path.dirname(os.path.abspath(__file__))

# 构建相对路径（5G通信的仿真matlab代码位于同层simultion文件夹中）
relative_path = os.path.join(script_dir, 'simulation')

# 转换为 MATLAB 路径格式（使用正斜杠）
matlab_path = relative_path.replace('\\', '/')
print(matlab_path);

# 启动MATLAB引擎
eng = matlab.engine.start_matlab()
eng.addpath(matlab_path, nargout=0)  # 添加MATLAB路径

# 调用MATLAB函数
res = eng.main()

# print(result)

# 关闭引擎
eng.quit()
