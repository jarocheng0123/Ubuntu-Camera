print("\n\033[93m【相机预览与参数查看程序：实时预览摄像头画面，显示驱动信息和参数表格】\033[0m\n")

import os
import cv2
import subprocess
from prettytable import PrettyTable

# 十六进制参数 ID 与中文名称的映射
PARAM_MAP = {
    "0x00980900": "亮度",
    "0x00980901": "对比度",
    "0x00980902": "饱和度",
    "0x00980903": "色调",
    "0x0098090c": "自动白平衡",
    "0x00980910": "伽马值",
    "0x00980913": "增益",
    "0x00980918": "电源频率",
    "0x0098091a": "白平衡",
    "0x0098091b": "清晰度",
    "0x0098091c": "背光补偿",
    "0x009a0901": "自动曝光",
    "0x009a0902": "绝对曝光时间",
    "0x009a0903": "动态帧率曝光",
    "0x009a090a": "绝对焦点",
    "0x009a090c": "连续自动对焦",
}

# 菜单参数选项的预设值映射
MENU_OPTIONS_MAP = {
    "0x00980918": {
        "options": {0: "表示禁用", 1: "表示 50Hz", 2: "表示 60Hz"},
        "note": "；".join([f"{k}: {v}" for k, v in {0: "表示禁用", 1: "表示 50Hz", 2: "表示 60Hz"}.items()])
    },
    "0x009a0901": {
        "options": {1: "表示手动模式", 3: "表示光圈优先模式"},
        "note": "；".join([f"{k}: {v}" for k, v in {1: "表示手动模式", 3: "表示光圈优先模式"}.items()])
    },
    "0x0098090c": {"note": "0 关闭，1 开启"},
    "0x009a0903": {"note": "0 关闭，1 开启"},
    "0x009a090c": {"note": "0 关闭，1 开启"}
}

def get_available_cameras():
    """自动发现所有物理摄像头设备"""
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")]

    for device in video_devices:
        try:
            # 检查设备是否为物理摄像头（基于驱动名称）
            result = subprocess.run(
                ["v4l2-ctl", "-d", device, "--all"],
                capture_output=True,
                text=True,
                timeout=5
            )
            output = result.stdout

            if "Driver name      : uvcvideo" in output:
                # 尝试用 OpenCV 打开设备
                cap = cv2.VideoCapture(device)
                if cap.isOpened():
                    available.append(device)
                    cap.release()
        except Exception as e:
            print(f"检测设备 {device} 时出错: {str(e)}")

    return available


def get_driver_info(device_path):
    """获取驱动信息"""
    try:
        result = subprocess.run(
            ["v4l2-ctl", "-d", device_path, "--all"],
            capture_output=True,
            text=True,
            check=True
        )
        output = result.stdout.split('\n') # 按行分割
        driver_info = {}

        for line in output: # 逐行解析
            line = line.strip() # 去除首尾空格
            if line.startswith("Driver name"): # 匹配驱动名称
                driver_info["DriverName"] = line.split(':', 1)[1].strip() # 驱动名称
            elif line.startswith("Card type"): # 匹配设备型号
                driver_info["DeviceModel"] = line.split(':', 1)[1].strip() # 设备型号
            elif line.startswith("Bus info"): # 匹配总线信息
                driver_info["BusInfo"] = line.split(':', 1)[1].strip() # 总线信息
            elif line.startswith("Driver version"): # 匹配驱动版本
                driver_info["DriverVersion"] = line.split(':', 1)[1].strip() # 驱动版本
            elif line.startswith("Width/Height"): # 匹配分辨率
                parts = line.split(':', 1)[1].strip().split() # 分割分辨率
                if parts: # 匹配分辨率
                    res_str = parts[0]
                    if '/' in res_str:
                        width, height = res_str.split('/')
                    elif 'x' in res_str:
                        width, height = res_str.split('x')
                    else:
                        width, height = res_str, '未知'
                    driver_info["Resolution"] = f"{width}×{height}"
            elif line.startswith("Pixel Format"): # 匹配像素格式
                pixel_format_part = line.split(':', 1)[1].strip()
                pixel_format = pixel_format_part.split()[0].strip("'")
                driver_info["PixelFormat"] = f"{pixel_format} (4:2:2)"
            elif line.startswith("Frames per second"): # 匹配帧率
                parts = line.split(':', 1)[1].strip().split()
                driver_info["FrameRate"] = parts[0] + " " + parts[1][1:] if len(parts) >= 2 else parts[0]

        return driver_info # 返回驱动信息

    except subprocess.CalledProcessError as e:
        print(f"获取驱动信息失败: {e.stderr}")
        return {}


def parse_v4l2_controls(device_path): # 解析参数
    """获取摄像头参数"""
    try:
        result = subprocess.run(
            ["v4l2-ctl", "-d", device_path, "-l"],
            capture_output=True,
            text=True,
            check=True
        )
        output = result.stdout.split('\n')
        all_controls = []
        current_section = None

        for line in output:
            line = line.strip()
            if line.startswith("User Controls") or line.startswith("Camera Controls"): # 区分用户参数和相机参数
                current_section = line.split()[0]
            elif current_section and line:
                parts = line.split()
                if len(parts) >= 3 and parts[1].startswith("0x"): # 匹配参数行
                    all_controls.append((current_section, line))

        return all_controls

    except subprocess.CalledProcessError as e:
        print(f"获取摄像头参数失败: {e.stderr}")
        return []


def convert_to_table(all_controls): # 解析为表格格式
    """转换为表格格式"""
    table = []
    for section, line in all_controls: # 逐行解析
        parts = line.split()
        param_id = parts[1]
        param_type = parts[2].replace("(", "").replace(")", "")
        english_name = parts[0]
        param_name = PARAM_MAP.get(param_id, param_id)

        min_val = max_val = step = default_val = current_val = "" # 初始化
        flags = ""
        menu_options = []

        # 处理菜单选项映射
        for part in parts: # 匹配菜单选项
            if part.startswith("min="):
                min_val = part.split("=")[1]
            elif part.startswith("max="):
                max_val = part.split("=")[1]
            elif part.startswith("step="):
                step = part.split("=")[1]
            elif part.startswith("default="):
                default_val = part.split("=")[1]
            elif part.startswith("value="):
                current_val = part.split("=")[1]
            elif part.startswith("flags="):
                flags = part.split("=")[1]
            elif part.startswith("(") and part.endswith(")"):
                menu_options.append(part[1:-1])

        # 处理备注信息
        note = ""
        if param_id in MENU_OPTIONS_MAP: # 匹配菜单选项
            note = MENU_OPTIONS_MAP[param_id].get("note", "")
        elif param_type == "menu":
            note = "；".join([f"{i}: {opt}" for i, opt in enumerate(menu_options)])
        elif param_type == "bool":
            note = "0 关闭，1 开启"
        elif flags == "inactive":
            note = "非激活"
        elif not note:
            note = "/"

        # 处理特殊参数类型
        if param_type in ("menu", "bool"):
            min_val = max_val = step = "/"

        # 处理菜单选项
        table.append([
            param_name,
            english_name,
            param_id,
            param_type,
            min_val,
            max_val,
            step,
            default_val,
            current_val,
            note
        ])

    return table # 返回表格


def print_driver_info(driver_info, device_index): # 打印驱动信息
    """打印驱动信息"""
    print(f"摄像头 {device_index} 驱动信息:")
    print(f"驱动名称\t{driver_info.get('DriverName', '未知')}")
    print(f"设备型号\t{driver_info.get('DeviceModel', '未知')}")
    print(f"总线信息\t{driver_info.get('BusInfo', '未知')}")
    print(f"驱动版本\t{driver_info.get('DriverVersion', '未知')}")
    print(f"分辨率\t{driver_info.get('Resolution', '未知')}")
    print(f"像素格式\t{driver_info.get('PixelFormat', '未知')}")
    print(f"帧率\t{driver_info.get('FrameRate', '未知')}")
    print()

def print_parameter_table(table, device_index): # 打印参数表格
    table_obj = PrettyTable()
    table_obj.field_names = ["中文名称", "英文名称", "参数 ID", "类型", "最小值", "最大值", "步长", "默认值", "当前值", "备注"]
    for row in table:
        table_obj.add_row(row)
    print(f"摄像头 {device_index} 参数信息:")
    print(table_obj)
    print()

# 获取设备信息
def get_device_id(device_path):
    """获取设备的 VID-PID 组合"""
    try:
        cmd = ["udevadm", "info", "-q", "property", device_path]
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        vid = "N/A"
        pid = "N/A"
        # 获取设备信息
        for line in result.stdout.splitlines():
            if line.startswith("ID_VENDOR_ID="):
                vid = line.split('=')[1].strip().upper()
            elif line.startswith("ID_MODEL_ID="):
                pid = line.split('=')[1].strip().upper()
        return f"{vid}-{pid}" if vid != "N/A" and pid != "N/A" else "UNKNOWN"
    except Exception as e:
        print(f"获取设备ID失败: {str(e)}")
        return "UNKNOWN"


# 主程序
available_devices = get_available_cameras() # 获取可用摄像头列表
caps = [] # 保存摄像头对象
device_ids = [] # 保存设备ID

# 打开摄像头
for idx, device_path in enumerate(available_devices):
    cap = cv2.VideoCapture(device_path)
    if not cap.isOpened():
        print(f"无法打开摄像头设备 {device_path}")
        continue

    # 获取设备ID
    device_id = get_device_id(device_path)
    device_ids.append(device_id)

    # 获取驱动信息
    driver_info = get_driver_info(device_path)
    caps.append(cap)
    driver_info = get_driver_info(device_path)
    all_controls = parse_v4l2_controls(device_path)
    parameter_table = convert_to_table(all_controls)

    # 打印参数信息
    print_driver_info(driver_info, idx)
    print_parameter_table(parameter_table, idx)

print("\n\033[93m【预览按下 Q 键退出】\033[0m\n")
while True:
    all_frames_read = True # 是否所有摄像头都读取到了画面
    for i, cap in enumerate(caps): # 逐个读取摄像头画面
        ret, frame = cap.read()
        if not ret:
            print(f"无法读取摄像头 {i} 画面")
            all_frames_read = False
            break
        cv2.imshow(device_ids[i], frame) # 显示画面

    if not all_frames_read:
        break

    if cv2.waitKey(1) & 0xFF == ord('q'): # 按下 q 键退出
        break

# 释放资源
for cap in caps:
    cap.release()
cv2.destroyAllWindows()