# ====================================================== 程序声明 ======================================================
print("\n\033[93m【V4L2 快速参数设置程序：利用 V4L2 命令批量设置摄像头参数，提供多种模式】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
import os
import subprocess

# 程序配置3组参数，用户可以自定义，当前 default默认值，value厂商值，setvalue用户值
SETTING_MODE = "setvalue"

# 参数定义结构
BASE_CAMERA_PARAMS = [
    {
        "chinese_name": "亮度",
        "v4l2_param": "brightness",
        "hex_numbers": "0x00980900",
        "type": "int",
        "min": -64,
        "max": 64,
        "step": 1,
        "default": -39,
        "value": -39,
        "options": "",
        "setvalue": -64
    },
    {
        "chinese_name": "对比度",
        "v4l2_param": "contrast",
        "hex_numbers": "0x00980901",
        "type": "int",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 39,
        "value": 39,
        "options": "",
        "setvalue": 39
    },
    {
        "chinese_name": "饱和度",
        "v4l2_param": "saturation",
        "hex_numbers": "0x00980902",
        "type": "int",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 72,
        "value": 72,
        "options": "",
        "setvalue": 72
    },
    {
        "chinese_name": "色调",
        "v4l2_param": "hue",
        "hex_numbers": "0x00980903",
        "type": "int",
        "min": -180,
        "max": 180,
        "step": 1,
        "default": 0,
        "value": 0,
        "options": "",
        "setvalue": 0
    },
    {
        "chinese_name": "自动白平衡",
        "v4l2_param": "white_balance_automatic",
        "hex_numbers": "0x0098090c",
        "type": "bool",
        "min": None,
        "max": None,
        "step": None,
        "default": 1,
        "value": 0,
        "options": "0 表示关闭；1 表示开启",
        "setvalue": 0
    },
    {
        "chinese_name": "伽马值",
        "v4l2_param": "gamma",
        "hex_numbers": "0x00980910",
        "type": "int",
        "min": 100,
        "max": 500,
        "step": 1,
        "default": 300,
        "value": 300,
        "options": "",
        "setvalue": 300
    },
    {
        "chinese_name": "增益",
        "v4l2_param": "gain",
        "hex_numbers": "0x00980913",
        "type": "int",
        "min": 1,
        "max": 128,
        "step": 1,
        "default": 64,
        "value": 64,
        "options": "",
        "setvalue": 64
    },
    {
        "chinese_name": "电源频率",
        "v4l2_param": "power_line_frequency",
        "hex_numbers": "0x00980918",
        "type": "menu",
        "min": 0,
        "max": 2,
        "step": None,
        "default": 1,
        "value": 1,
        "options": "0 表示禁用；1 表示 50Hz；2 表示 60Hz",
        "setvalue": 1
    },
    {
        "chinese_name": "白平衡温度",
        "v4l2_param": "white_balance_temperature",
        "hex_numbers": "0x0098091a",
        "type": "int",
        "min": 2800,
        "max": 6500,
        "step": 10,
        "default": 6500,
        "value": 6500,
        "options": "",
        "setvalue": 6000
    },
    {
        "chinese_name": "清晰度",
        "v4l2_param": "sharpness",
        "hex_numbers": "0x0098091b",
        "type": "int",
        "min": 0,
        "max": 100,
        "step": 1,
        "default": 75,
        "value": 75,
        "options": "",
        "setvalue": 75
    },
    {
        "chinese_name": "背光补偿",
        "v4l2_param": "backlight_compensation",
        "hex_numbers": "0x0098091c",
        "type": "int",
        "min": 0,
        "max": 2,
        "step": 1,
        "default": 0,
        "value": 0,
        "options": "",
        "setvalue": 0
    },
    {
        "chinese_name": "自动曝光",
        "v4l2_param": "auto_exposure",
        "hex_numbers": "0x009a0901",
        "type": "menu",
        "min": 0,
        "max": 3,
        "step": None,
        "default": 3,
        "value": 1,
        "options": "1 表示手动模式；3 表示光圈优先模式",
        "setvalue": 1
    },
    {
        "chinese_name": "绝对曝光时间",
        "v4l2_param": "exposure_time_absolute",
        "hex_numbers": "0x009a0902",
        "type": "int",
        "min": 0,
        "max": 10000,
        "step": 1,
        "default": 20,
        "value": 20,
        "options": "",
        "setvalue": 20
    },
    {
        "chinese_name": "动态帧率曝光",
        "v4l2_param": "exposure_dynamic_framerate",
        "hex_numbers": "0x009a0903",
        "type": "bool",
        "min": None,
        "max": None,
        "step": None,
        "default": 0,
        "value": 0,
        "options": "0 表示关闭；1 表示开启",
        "setvalue": 1
    },
    {
        "chinese_name": "绝对对焦",
        "v4l2_param": "focus_absolute",
        "hex_numbers": "0x009a090a",
        "type": "int",
        "min": 0,
        "max": 1023,
        "step": 1,
        "default": 68,
        "value": 68,
        "options": "",
        "setvalue": 68
    },
    {
        "chinese_name": "连续自动对焦",
        "v4l2_param": "focus_automatic_continuous",
        "hex_numbers": "0x009a090c",
        "type": "bool",
        "min": None,
        "max": None,
        "step": None,
        "default": 1,
        "value": 1,
        "options": "0 表示关闭；1 表示开启",
        "setvalue": 1
    }
]

def list_cameras(): # 获取可用摄像头列表
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")]

    for device in video_devices: # 检测可用设备
        try:
            index = int(device.split('video')[1])
            cmd = ["udevadm", "info", "-q", "property", device]
            result = subprocess.run(cmd, capture_output=True, text=True)
            vid, pid = "N/A", "N/A"
            for line in result.stdout.splitlines():
                if line.startswith("ID_VENDOR_ID="):
                    vid = line.split('=')[1].strip().upper()
                elif line.startswith("ID_MODEL_ID="):
                    pid = line.split('=')[1].strip().upper()
            device_id = f"{vid}-{pid}" if vid != "N/A" and pid != "N/A" else "UNKNOWN"
            available.append((index, device_id))
        except Exception as e:
            print(f"设备检测错误: {str(e)}")
    return available

def get_supported_controls(device): # 获取可用参数列表
    result = subprocess.run(f"v4l2-ctl -d {device} -l", shell=True, capture_output=True, text=True) # 获取可用参数列表
    supported_controls = []
    for line in result.stdout.splitlines():
        if line.startswith("User Controls") or line.startswith("Camera Controls"):
            continue
        parts = line.split()
        if len(parts) >= 3 and parts[1].startswith("0x"):
            control_name = parts[0] # 参数名
            supported_controls.append(control_name)
    return supported_controls # 返回可用参数列表

def set_camera_params(index, params, mode): # 设置摄像头参数
    device = f"/dev/video{index}"
    supported_controls = get_supported_controls(device) # 获取可用参数列表
    for param in params:
        if param["v4l2_param"] not in supported_controls:
            print(f"设备 {device} 不支持参数 {param['chinese_name']}，跳过设置")
            continue
        if mode == "default": # 从默认值设置
            val = param["default"]
        elif mode == "value": # 从当前值设置
            val = param["value"]
        elif mode == "setvalue": # 从设置值设置
            val = param["setvalue"]
        else:
            continue
        cmd = f"v4l2-ctl -d {device} --set-ctrl={param['v4l2_param']}={val}" # 设置参数
        result = subprocess.run(cmd, shell=True, check=False, capture_output=True, text=True)
        if result.returncode != 0: # 检查设置是否成功
            print(f"设置 {param['chinese_name']} 失败，设备: {device}，错误信息: {result.stderr}")

def main():
    camera_info = list_cameras() # 获取可用摄像头列表
    if not camera_info:
        print("未检测到摄像头设备")
        return
    for index, device_id in camera_info:
        set_camera_params(index, BASE_CAMERA_PARAMS, SETTING_MODE)

if __name__ == "__main__":
    main()
# ----------------------------------------------------------------------------------------------------------------------
