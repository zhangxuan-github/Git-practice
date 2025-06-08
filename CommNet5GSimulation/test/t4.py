import math

# 移动距离（米）
distance = 2  

# 纬度（假设为北京的纬度，39.9 度）
latitude = 39.9  

# 计算纬度变化
delta_lat = distance / 111139
print(f"移动 {distance} 米时，纬度变化约为 {delta_lat:.8f} 度")

# 计算经度变化
delta_lon = distance / (111320 * math.cos(math.radians(latitude)))
print(f"移动 {distance} 米时，经度变化约为 {delta_lon:.8f} 度")