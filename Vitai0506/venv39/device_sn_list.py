# ====================================================== 程序声明 ======================================================
print("\n\033[93m【检测系统中所有可用摄像头，整合 VID、PID、SN 信息】\033[0m")
print("\033[31m\033[1m【目标设备：ViTai F225-0001】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
import cv2  # OpenCV
import subprocess  # 执行系统命令

# 目标设备关键词
TARGET_DEVICE_NAME = "ViTai"
# 目标 VID - PID 组合
TARGET_VID_PID_COMBINATIONS = ["F225-0001"]
# vevn312环境的Python解释器路径
PYTHON_VENV312 = "/home/ur/Vitai0506/venv312/bin/python"
# 设备SN解析脚本路径
DEVICE_SN = "/home/ur/Vitai0506/venv312/device_sn.py"
# SN码开头固定标识前缀
SN_PREFIX='GF225'

def get_sn_codes(): # 获取SN码
    try:
        python_312_path = PYTHON_VENV312 # Python解释器路径
        script_path = DEVICE_SN # 脚本路径
        result = subprocess.run(
            [python_312_path, script_path],
            capture_output=True,
            text=True,
            check=True
        )
        sns = [line.strip() for line in result.stdout.split('\n') if line.startswith(SN_PREFIX)] # 提取SN码
        return sns
    except subprocess.CalledProcessError as e:
        print(f"调用 {DEVICE_SN} 失败，错误输出：{e.stderr}")
        return []
    except Exception as e:
        print(f"获取SN码时发生未知错误：{e}")
        return []


def list_cameras():
    """获取可用摄像头索引"""
    index = 0
    camera_indices = []
    while True:  # 遍历可用摄像头索引
        cap = cv2.VideoCapture(index, cv2.CAP_V4L2)  # 打开摄像头
        if cap.isOpened():  # 检查摄像头是否可用
            camera_indices.append(index)  # 添加可用摄像头索引
            cap.release()
            index += 1
            continue
        cap.release()  # 释放摄像头资源
        if index > 3:  # 防止无限循环，可根据实际情况调整
            break
        index += 1
    return camera_indices  # 返回可用摄像头索引列表


def get_camera_devices():
    """获取摄像头设备节点信息"""
    try:
        cmd = ["v4l2-ctl", "--list-devices"]  # 执行v4l2-ctl命令
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        devices = []  # 存储设备节点信息
        for block in result.stdout.strip().split('\n\n'):  # 遍历设备块
            lines = block.split('\n')
            name = lines[0].strip()  # 设备名称
            nodes = [line.strip() for line in lines[1:] if '/dev/video' in line]  # 获取设备节点
            if nodes:
                devices.append((name, nodes))
        return devices
    except subprocess.CalledProcessError as e:
        print(f"执行 v4l2 - ctl 命令时出错: {e.stderr}")
        return []
    except Exception as e:
        print(f"获取设备节点信息时出现未知错误: {e}")
        return []


class USBDeviceInfo:  # USB 设备信息类
    def __init__(self):
        self.target_devices = []
        self.non_target_devices = []

    def get_info(self):
        """获取 USB 设备信息并分类"""
        try:
            result = subprocess.run(['lsusb'], capture_output=True, text=True, check=True)  # 执行 lsusb 命令
            output = result.stdout.splitlines()  # 获取 lsusb 命令输出
            for line in output:
                parts = line.split()
                if len(parts) < 6:
                    continue
                # 提取 VID/PID
                vid_pid = parts[5].split(':')
                vid = vid_pid[0].upper()
                pid = vid_pid[1].upper()
                vid_pid_combination = f"{vid}-{pid}"
                # 提取设备名称和制造商
                device_name = ' '.join(parts[6:])
                manufacturer = self._parse_manufacturer(device_name)
                # 构建设备信息
                device = {
                    "device_name": device_name,
                    "vid": vid,
                    "pid": pid,
                    "manufacturer": manufacturer,
                    "vid_pid_combination": vid_pid_combination
                }
                # 分类设备
                if TARGET_DEVICE_NAME.lower() in device_name.lower():  # 目标设备
                    self.target_devices.append(device)
                else:
                    self.non_target_devices.append(device)  # 非目标设备
                # 检查是否是指定的 VID - PID 组合
                if vid_pid_combination in TARGET_VID_PID_COMBINATIONS:
                    print(f"\033[31m识别到指定的 VID - PID 组合: {vid_pid_combination}\033[0m")
            return self.target_devices + self.non_target_devices
        except subprocess.CalledProcessError as e:
            print(f"执行 lsusb 命令时出错: {e.stderr}")
            return []
        except Exception as e:
            print(f"获取 USB 信息时出现未知错误: {e}")
            return []

    def _parse_manufacturer(self, device_name):
        """优化制造商解析逻辑"""
        if TARGET_DEVICE_NAME.lower() in device_name.lower():
            return TARGET_DEVICE_NAME  # 直接标记目标设备制造商
        # 其他制造商解析
        manufacturers = {
            "VMware, Inc.": ["VMware"],
            "Linux Foundation": ["Linux"],
            "Generic": ["Generic"]
        }
        for manu, keywords in manufacturers.items():  # 遍历制造商关键字
            for keyword in keywords:
                if keyword in device_name:
                    return manu
        return "N/A"


    def print_combined_info(self, sns): # 格式化输出设备信息
        """格式化输出设备信息"""
        if not (self.target_devices or self.non_target_devices):
            print("未找到 USB 设备信息")
            return
        # 添加 SN 码
        for idx, device in enumerate(self.target_devices):
            device["sn"] = sns[idx] if idx < len(sns) else "N/A"
        print("\nUSB 设备信息：")


        print("序号   | 设备名称                        | VID        | PID    | 制造商                 | SN")
        print("-" * 100)
        # 打印非目标设备
        for idx, device in enumerate(self.non_target_devices, 1):
            print(
                f"{idx:<6}| {device['device_name']:<30} | {device['vid']:<10} | {device['pid']:<6} | {device['manufacturer']:<20} | ")
        # 打印分隔线（如果有混合设备）
        if self.target_devices and self.non_target_devices:
            print("-" * 100)
        # 打印目标设备（绿色高亮）
        for idx, device in enumerate(self.target_devices, 1):
            print(
                # f"\033[32m{idx:<6}| {device['device_name']:<30} | {device['vid']:<10} | {device['pid']:<6} | {device['manufacturer']}\033[0m")
                f"\033[32m{idx:<6}| {device['device_name']:<30} | {device['vid']:<10} | {device['pid']:<6} | {device['manufacturer']:<20} | {device.get('sn', 'N/A')}\033[0m")
        print("-" * 100)


def main():
    # 获取摄像头信息
    camera_indices = list_cameras()
    print("\n检测到的摄像头索引：", camera_indices)
    # 获取设备节点信息
    devices = get_camera_devices()
    print("\n摄像头设备节点信息：")
    for name, nodes in devices:
        print(f"设备名称：{name}")
        print(f"设备节点：{nodes}\n")
    # 获取 USB 设备信息
    usb_info = USBDeviceInfo()
    usb_info.get_info()
    sns = get_sn_codes()
    usb_info.print_combined_info(sns) 


if __name__ == '__main__':
    main()
# ----------------------------------------------------------------------------------------------------------------------
