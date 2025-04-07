#!/bin/bash

CODENAME=$(lsb_release -cs)  # Ubuntu版本代号
CURRENT_USER=$(logname)  # 当前用户
USER_HOME=$(getent passwd "$CURRENT_USER" | awk -F: '{print $6}') # 用户主目录
USER_DESKTOP="${USER_HOME}/桌面" # 桌面路径

WORK_DIR="${USER_HOME}/vitai" # 工作目录
VENV_NAME="vitai_venv" # 虚拟环境名称
PYTHON_VERSION="3.9" # Python版本
PYTHON_CAMERA_LIST="camera_list.py" # 相机列表
PYTHON_CAMERA_OPEN="camera_open.py" # 相机预览
PYTHON_CAMERA_VITAI="camera_vitai.py" # 单相机调试脚本
PYTHON_CAMERA_VITAI_DOUBLE="camera_vitai_double.py" # 多相机调试脚本

PYTHON_VENV="${WORK_DIR}/${VENV_NAME}/bin/activate"  # 虚拟环境路径
PYTHON_TO_DESKTOP="${USER_DESKTOP}/vitai.desktop" # 桌面快捷方式

MIRROR_URL="https://pypi.tuna.tsinghua.edu.cn/simple" # pip源
UDEV_RULE_FILE="/etc/udev/rules.d/99-vitai-camera.rules" # udev规则文件

#==================================================================================================================
echo -e "\n\033[1;33m使用sudo权限运行脚本\033[0m"

# 脚本说明标题
echo -e "\n\033[1;31mUbuntu Vitai 相机调试脚本说明\033[0m"

# 功能说明
echo -e "\n\033[1;32m功能说明：\033[0m"
printf "  \033[32m%-40s %s\033[0m\n" "${PYTHON_CAMERA_LIST}" "用于列出相机列表"
printf "  \033[32m%-40s %s\033[0m\n" "${PYTHON_CAMERA_OPEN}" "用于打开相机预览"
printf "  \033[32m%-40s %s\033[0m\n" "${PYTHON_CAMERA_VITAI}" "用于单相机参数调试"
printf "  \033[32m%-40s %s\033[0m\n" "${PYTHON_CAMERA_VITAI_DOUBLE}" "用于多相机参数调试"
printf "  \033[32m%-40s %s\033[0m\n" "${PYTHON_TO_DESKTOP}" "  激活环境并执行脚本"

# 注意事项
echo -e "\n\033[1;31m注意事项：\033[0m"
echo -e "  - 激活环境：source ${PYTHON_VENV}"
echo -e "  - 多摄像头调试脚本 ${PYTHON_CAMERA_VITAI_DOUBLE} 尚未实现多摄像头参数设置"
echo -e "  - 调试脚本 ${PYTHON_CAMERA_VITAI} ${PYTHON_CAMERA_VITAI_DOUBLE} 对于部分参数设置存在问题"
echo -e "  - # AutoExposure 自动曝光 # WhiteBalance 白平衡  和 一些其他参数"

# 分隔线
echo -e "\n\033[31m============================================================\033[0m"

# 操作手册
echo -e "\n\033[1;32m操作手册：\033[0m"
echo -e "\033[31m==========================================================\033[0m"
echo -e " - 添加用户到video组：sudo usermod -aG video $CURRENT_USER"
echo -e " - 验证权限：groups $USER | grep video"
echo -e " - 查看参数：v4l2-ctl -d /dev/video0 --all"
echo -e " - 查看设备: v4l2-ctl --list-devices"
echo -e " - 查找设备：lsusb | grep \"ViTai\""
echo -e " - 查看进程: lsof | grep video"
echo -e " - 关闭进程: killall -9 python3"
echo -e " - 关闭进程: killall -9 opencv"
echo -e "\033[31m==========================================================\033[0m"

# 执行测试和预览
echo -e "\n\033[1;32m执行测试和预览：\033[0m"
echo -e "\033[31m==========================================================\033[0m"
echo -e " - 激活环境：source ${PYTHON_VENV}"
echo -e " - 设备列表：python ${WORK_DIR}/${PYTHON_CAMERA_LIST}"
echo -e " - 实时预览：python ${WORK_DIR}/${PYTHON_CAMERA_OPEN}"
echo -e " - 单个相机参数设置：python ${WORK_DIR}/${PYTHON_CAMERA_VITAI}"
echo -e " - 多个相机参数设置：python ${WORK_DIR}/${PYTHON_CAMERA_VITAI_DOUBLE}"
echo -e "\033[31m==========================================================\033[0m"

# 其他提示
echo -e "\n\033[1;31m其他提示：\033[0m"
echo -e "\033[31m==========================================================\033[0m"
echo -e " - 预览按下 Q 键退出"
echo -e " - 安装完成自动执行脚本 ${PYTHON_CAMERA_LIST} ${PYTHON_CAMERA_OPEN}\n"     
echo -e "\033[31m==========================================================\033[0m"

#==================================================================================================================

# 检查文件是否存在

if [ -d "$WORK_DIR" ]; then
    echo -e "\n\033[32m发现 ${WORK_DIR} 文件夹存在，内容如下：\033[0m"
    ls -l "$WORK_DIR"
    while true; do
        read -p $'\n\033[33m是否要清空并重建文件夹？(Y/y/N/n): \033[0m' answer
        case $answer in
            [Yy]*)
                echo -e "\n\033[33m即将清空并重建文件夹...\033[0m"
                rm -rf "$WORK_DIR"
                if ! mkdir -p "$WORK_DIR"; then
                    echo -e "\n\033[31m创建文件夹时出错，请检查权限。\033[0m"
                    exit 1
                fi
                break
                ;;
            [Nn]*)
                echo -e "\n\033[33m已取消对文件夹的操作。\033[0m"
                break
                ;;
            *)
                echo -e "\n\033[31m输入无效，请输入 Y/y 或 N/n。\033[0m"
                ;;
        esac
    done
else
    echo -e "\n\033[31m ${WORK_DIR} 文件夹不存在，开始创建...\033[0m"
    if ! mkdir -p "$WORK_DIR"; then
        echo -e "\n\033[31m创建文件夹时出错，请检查权限。\033[0m"
        exit 1
    fi
fi

#==================================================================================================================
echo -e "\n\033[32m设置系统源为阿里云镜像\033[0m"

# 备份原有源文件
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

ALIYUN_MIRROR_CONTENT=$(cat <<EOF
deb http://mirrors.aliyun.com/ubuntu/ ${CODENAME} main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODENAME} main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${CODENAME}-backports main restricted universe multiverse
EOF
)

# 写入新的源文件内容
echo "$ALIYUN_MIRROR_CONTENT" | sudo tee /etc/apt/sources.list > /dev/null

echo -e "\n\033[32m更新软件源信息\033[0m"

# 更新软件源信息
sudo apt update

#==================================================================================================================

# 系统级依赖安装
echo -e "\n\033[32m添加ppa源\033[0m"

apt install -y software-properties-common  # 添加ppa源
for _ in {1..3}; do
    add-apt-repository -y universe && add-apt-repository -y ppa:deadsnakes/ppa && break
    sleep 5
done

echo -e "\n\033[32m安装系统级依赖\033[0m"

apt install -y --no-install-recommends \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-dev python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION}-tk tk-dev tcl-dev \
    libv4l-dev v4l-utils libusb-1.0-0-dev \
    python3-opencv libatlas3-base \
    libopenjp2-7 libqt5gui5 \
    qtbase5-dev libqt5x11extras5-dev \
    cython3 ffmpeg libcap-dev git g++ make build-essential libcamera-dev

#==================================================================================================================

# 创建Python虚拟环境
echo -e "\n\033[32m创建Python${PYTHON_VERSION}虚拟环境\033[0m"
python${PYTHON_VERSION} -m venv "${WORK_DIR}/${VENV_NAME}"

# 激活虚拟环境并安装Python依赖
echo -e "\n\033[32m安装Python${PYTHON_VERSION}依赖到虚拟环境\033[0m"
source "${PYTHON_VENV}"
pip config set global.index-url "$MIRROR_URL"
pip install --upgrade pip setuptools wheel PyQt5
for _ in {1..3}; do
    pip install --no-cache-dir --force-reinstall --timeout=600 --retries=5 \
        'numpy >= 1.24.4' \
        "pyusb == 1.2.1" \
        "picamera2 == 0.3.25" \
        "psutil == 5.9.5" \
        'cython >= 3.0.11' \
        'opencv_python >= 4.10.0.84' && break
done

#==================================================================================================================

# 检验安装和环境配置
echo -e "\n\033[31m==========================================================\033[0m"
source "${PYTHON_VENV}"  
echo -e "\033[31m当前虚拟环境Python版本：$(python --version 2>&1)\033[0m"
echo -e "\033[31mPython解释器路径：$(which python)\033[0m"
echo -e "\033[31mOpenCV版本：$(python -c 'import cv2;print(cv2.__version__)' 2>/dev/null || echo '未安装')\033[0m"
echo -e "\033[31mPyUSB版本：$(python -c 'import usb;print(usb.__version__)' 2>/dev/null || echo '未安装')\033[0m"
echo -e "\033[31mV4L2版本：$(v4l2-ctl --version 2>/dev/null || echo '未安装')\033[0m"
echo -e "\033[31m==========================================================\033[0m"

############################################################################################
echo -e "\n\033[32m 相机列表脚本 ${PYTHON_CAMERA_LIST} \033[0m"
cat << 'EOF' > "${WORK_DIR}/${PYTHON_CAMERA_LIST}"
# 打印相机设备列表

import cv2 # OpenCV
import subprocess # 执行系统命令

# 目标设备关键词
TARGET_DEVICE_NAME = "ViTai"

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
        for block in result.stdout.strip().split('\n\n'): # 遍历设备块
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


class USBDeviceInfo: # USB 设备信息类
    def __init__(self):
        self.target_devices = []
        self.non_target_devices = []

    def get_info(self):
        """获取 USB 设备信息并分类"""
        try:
            result = subprocess.run(['lsusb'], capture_output=True, text=True, check=True)  # 执行 lsusb 命令
            output = result.stdout.splitlines() # 获取 lsusb 命令输出
            for line in output:
                parts = line.split()
                if len(parts) < 6:
                    continue
                # 提取 VID/PID
                vid_pid = parts[5].split(':')
                vid = vid_pid[0].upper()
                pid = vid_pid[1].upper()
                # 提取设备名称和制造商
                device_name = ' '.join(parts[6:])
                manufacturer = self._parse_manufacturer(device_name)
                # 构建设备信息
                device = {
                    "device_name": device_name,
                    "vid": vid,
                    "pid": pid,
                    "manufacturer": manufacturer
                }
                # 分类设备
                if TARGET_DEVICE_NAME.lower() in device_name.lower():  # 目标设备
                    self.target_devices.append(device)
                else:
                    self.non_target_devices.append(device)  # 非目标设备
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

    def print_info(self):
        """格式化输出设备信息"""
        if not (self.target_devices or self.non_target_devices):
            print("未找到 USB 设备信息")
            return
        # 打印表头
        print("\nUSB 设备信息：")
        print("序号   | 设备名称                        | VID        | PID    | 制造商")
        print("-" * 80)
        # 打印非目标设备
        for idx, device in enumerate(self.non_target_devices, 1):
            print(
                f"{idx:<6}| {device['device_name']:<30} | {device['vid']:<10} | {device['pid']:<6} | {device['manufacturer']}")
        # 打印分隔线（如果有混合设备）
        if self.target_devices and self.non_target_devices:
            print("-" * 80)
        # 打印目标设备（绿色高亮）
        for idx, device in enumerate(self.target_devices, 1):
            print(
                f"\033[32m{idx:<6}| {device['device_name']:<30} | {device['vid']:<10} | {device['pid']:<6} | {device['manufacturer']}\033[0m")
        print("-" * 80)


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
    usb_info.print_info()


if __name__ == '__main__':
    main()


EOF

############################################################################################
echo -e "\n\033[32m 相机预览脚本 ${PYTHON_CAMERA_OPEN} \033[0m"
cat << 'EOF' > "$WORK_DIR/${PYTHON_CAMERA_OPEN}"
# 打开相机实时画面
import os
import cv2
import subprocess

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
        "options": {0: "禁用", 1: "50 Hz", 2: "60 Hz"},
        "note": "；".join([f"{k}: {v}" for k, v in {0: "禁用", 1: "50 Hz", 2: "60 Hz"}.items()])
    },
    "0x009a0901": {
        "options": {1: "手动", 3: "光圈优先"},
        "note": "；".join([f"{k}: {v}" for k, v in {1: "手动", 3: "光圈优先"}.items()])
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
        output = result.stdout.split('\n')
        driver_info = {}

        for line in output: # 逐行解析
            line = line.strip()
            if line.startswith("Driver name"):
                driver_info["DriverName"] = line.split(':', 1)[1].strip()
            elif line.startswith("Card type"):
                driver_info["DeviceModel"] = line.split(':', 1)[1].strip()
            elif line.startswith("Bus info"):
                driver_info["BusInfo"] = line.split(':', 1)[1].strip()
            elif line.startswith("Driver version"):
                driver_info["DriverVersion"] = line.split(':', 1)[1].strip()
            elif line.startswith("Width/Height"):
                parts = line.split(':', 1)[1].strip().split()
                if parts:
                    res_str = parts[0]
                    if '/' in res_str:
                        width, height = res_str.split('/')
                    elif 'x' in res_str:
                        width, height = res_str.split('x')
                    else:
                        width, height = res_str, '未知'
                    driver_info["Resolution"] = f"{width}×{height}"
            elif line.startswith("Pixel Format"):
                pixel_format_part = line.split(':', 1)[1].strip()
                pixel_format = pixel_format_part.split()[0].strip("'")
                driver_info["PixelFormat"] = f"{pixel_format} (4:2:2)"
            elif line.startswith("Frames per second"):
                parts = line.split(':', 1)[1].strip().split()
                driver_info["FrameRate"] = parts[0] + " " + parts[1][1:] if len(parts) >= 2 else parts[0]

        return driver_info

    except subprocess.CalledProcessError as e:
        print(f"获取驱动信息失败: {e.stderr}")
        return {}


def parse_v4l2_controls(device_path):
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
        if param_id in MENU_OPTIONS_MAP:
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

    return table


def print_driver_info(driver_info, device_index):
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


# 菜单选项映射
def print_parameter_table(table, device_index):
    column_widths = {
        "中文名称": 20,
        "英文名称": 30,
        "参数 ID": 16,
        "类型": 8,
        "最小值": 8,
        "最大值": 8,
        "步长": 6,
        "默认值": 8,
        "当前值": 8,
        "备注": 20
    }

    # 打印表头（左对齐）
    header = "".join([f"{name:<{width}}" for name, width in column_widths.items()])
    print(f"摄像头 {device_index} 参数信息:")
    print(header)
    print("-" * len(header))

    for row in table:
        formatted_row = []
        for i, col in enumerate(row):
            col_name = ["中文名称", "英文名称", "参数 ID", "类型", "最小值", "最大值", "步长", "默认值", "当前值", "备注"][i]
            # 强制左对齐，截断过长内容（如需完整显示可删除[:column_widths[col_name]]）
            formatted_col = f"{col[:column_widths[col_name]]:<{column_widths[col_name]}}"
            formatted_row.append(formatted_col)
        print("".join(formatted_row))
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
available_devices = get_available_cameras()
caps = []
device_ids = []

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


EOF

############################################################################################
echo -e "\n\033[32m 单相机调试脚本 ${PYTHON_CAMERA_VITAI} \033[0m"
cat << 'EOF' > "$WORK_DIR/${PYTHON_CAMERA_VITAI}"
# 单相机处理脚本
import os
import cv2
import json
import time
import subprocess
import tkinter as tk
from tkinter import ttk
from queue import Queue, Empty
from threading import Thread, Event, Lock

# 全局配置
MAX_FPS = 30 # 最大帧率
CONFIG_FILE = "camera_params.json" # 配置文件路径

# 定义队列用于传递帧数据
frame_queue = Queue(maxsize=2)

# 相机配置类
class CameraConfig: 
# 十六进制
# 中文名
# 默认值
# 值域
# 选项
# opencv常量

    PARAM_MAP = {
        "0x00980900": { 
            "chinese_name": "亮度", 
            "value": -64, 
            "range": (-64, 64), 
            "options": "",
            "cv_constant": cv2.CAP_PROP_BRIGHTNESS 
        },
        "0x00980901": {
            "chinese_name": "对比度",
            "value": 39,
            "range": (0, 100),
            "options": "",
            "cv_constant": cv2.CAP_PROP_CONTRAST
        },
        "0x00980902": {
            "chinese_name": "饱和度",
            "value": 72,
            "range": (0, 100),
            "options": "",
            "cv_constant": cv2.CAP_PROP_SATURATION
        },
        "0x00980903": {
            "chinese_name": "色调",
            "value": 0,
            "range": (-180, 180),
            "options": "",
            "cv_constant": cv2.CAP_PROP_HUE
        },
        "0x0098090c": {
            "chinese_name": "自动白平衡",
            "value": 0,
            "range": (0, 1),
            "options": "关闭；开启",
            "cv_constant": cv2.CAP_PROP_AUTO_WB
        },
        "0x00980910": {
            "chinese_name": "伽马值",
            "value": 300,
            "range": (100, 500),
            "options": "",
            "cv_constant": cv2.CAP_PROP_GAMMA
        },
        "0x00980913": {
            "chinese_name": "增益",
            "value": 64,
            "range": (1, 128),
            "options": "",
            "cv_constant": cv2.CAP_PROP_GAIN
        },
        "0x00980918": {
            "chinese_name": "电源频率",
            "value": 1,
            "range": (0, 2),
            "options": "禁用；50 Hz；60 Hz",
            "cv_constant": None
        },
        "0x0098091a": {
            "chinese_name": "白平衡",
            "value": 6000,
            "range": (2800, 6500),
            "options": "",
            "cv_constant": cv2.CAP_PROP_WHITE_BALANCE_BLUE_U
        },
        "0x0098091b": {
            "chinese_name": "清晰度",
            "value": 75,
            "range": (0, 100),
            "options": "",
            "cv_constant": cv2.CAP_PROP_SHARPNESS
        },
        "0x0098091c": {
            "chinese_name": "背光补偿",
            "value": 0,
            "range": (0, 2),
            "options": "",
            "cv_constant": None
        },
        "0x009a0901": {
            "chinese_name": "自动曝光",
            "value": 1,
            "range": (1, 3),
            "options": "手动；光圈优先",
            "cv_constant": cv2.CAP_PROP_AUTO_EXPOSURE
        },
        "0x009a0902": {
            "chinese_name": "绝对曝光时间",
            "value": 20,
            "range": (0, 10000),
            "options": "",
            "cv_constant": cv2.CAP_PROP_EXPOSURE
        },
        "0x009a0903": {
            "chinese_name": "动态帧率曝光",
            "value": 0,
            "range": (0, 1),
            "options": "关闭；开启",
            "cv_constant": None
        },
        "0x009a090a": {
            "chinese_name": "绝对焦点",
            "value": 68,
            "range": (0, 1023),
            "options": "",
            "cv_constant": cv2.CAP_PROP_FOCUS
        },
        "0x009a090c": {
            "chinese_name": "连续自动对焦",
            "value": 1,
            "range": (0, 1),
            "options": "关闭；开启",
            "cv_constant": None
        }
    }

 # 摄像头控制器
class CameraController:
    def __init__(self, index, device_id):
        self.cap = None
        self.index = index
        self.device_id = device_id
        self.exit_event = Event()
        self.lock = Lock()
        self.last_frame_time = 0

    def initialize(self): # 初始化摄像头
        with self.lock:
            self.cap = cv2.VideoCapture(self.index) # 打开摄像头
            if not self.cap.isOpened(): # 检查是否打开成功
                return False
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            self._init_params()
            return True

    def _init_params(self): # 初始化参数
        try:
            with open(CONFIG_FILE, 'r') as f: # 读取配置文件
                saved_params = json.load(f).get(self.device_id, {})
        except FileNotFoundError:
            saved_params = {}

        for param_id, config in CameraConfig.PARAM_MAP.items(): # 遍历参数
            value = saved_params.get(param_id, config["value"]) # 获取参数值
            if config["cv_constant"] is not None:
                try:
                    ret = self.cap.set(config["cv_constant"], value)
                    if not ret:
                        print(f"{self.device_id} 参数 {config['chinese_name']} 初始化失败")
                except Exception as e:
                    print(f"{self.device_id} 参数 {config['chinese_name']} 初始化错误: {str(e)}")

    def run(self): # 运行摄像头
        while not self.exit_event.is_set(): # 循环读取摄像头
            with self.lock:
                if self.cap.isOpened():
                    if time.time() - self.last_frame_time < 1 / MAX_FPS: # 限制帧率
                        time.sleep(0.001)
                        continue
                    ret, frame = self.cap.read()
                    self.last_frame_time = time.time()
                    if ret and not frame_queue.full(): # 将帧放入队列
                        frame = cv2.resize(frame, (640, 480)) # 缩放
                        frame_queue.put((self.device_id, frame), block=False)
            time.sleep(0.001)

class CameraControlPro(tk.Toplevel): # 摄像头控制界面
    def __init__(self, master, camera_controller):
        super().__init__(master)
        self.camera_controller = camera_controller # 摄像头控制器
        self.title(camera_controller.device_id) # 设置标题
        self.protocol("WM_DELETE_WINDOW", self.exit_app) # 退出时关闭窗口
        self.row = 0
        self.main_frame = ttk.Frame(self, padding=20) # 主框架
        self.main_frame.pack(fill=tk.BOTH, expand=True) # 设置主框架
        self.create_controls() # 创建控件
        self.add_buttons() # 添加按钮
        self.bind('<KeyPress-r>', lambda e: self.reset_params()) # 重置参数
        self.bind('<KeyPress-s>', lambda e: self.save_params()) # 保存参数
        self.bind('<KeyPress-q>', lambda e: self.exit_app()) # 退出
        self.device_id = camera_controller.device_id # 设备ID

    def create_controls(self): # 创建控件
        param_list = list(CameraConfig.PARAM_MAP.items()) # 参数列表
        for i in range(0, len(param_list), 3):
            for col in range(3):
                if i + col < len(param_list):
                    param_id, config = param_list[i + col]
                    frame = ttk.LabelFrame(self.main_frame, text=config["chinese_name"])
                    frame.grid(row=self.row, column=col, padx=5, pady=5, sticky="nsew")
                    self._create_control_widget(frame, config, param_id)
            self.row += 1

    def _create_control_widget(self, frame, config, param_id): # 创建控件
        range_default = ttk.Label(frame, text=f"范围: {config['range'][0]} ~ {config['range'][1]} | 默认: {config['value']}")
        range_default.pack(fill=tk.X)

        control_frame = ttk.Frame(frame) # 控件框架
        control_frame.pack(fill=tk.X, pady=2) # 控件框架

        if config.get("options", ""):
            options = config["options"].split("；")
            var = tk.StringVar(value=options[config["value"]])
            cb = ttk.Combobox(control_frame, textvariable=var, values=options) # 下拉框
            cb.pack(side=tk.LEFT, fill=tk.X, expand=True)
            config["var"] = var # 保存变量
            cb.bind("<<ComboboxSelected>>", lambda e, c=config, pid=param_id: self.on_param_change(e, c, pid)) # 绑定下拉框事件
        else:
            var = tk.IntVar(value=config["value"]) # 滑块变量
            slider = ttk.Scale(control_frame, from_=config["range"][0], to=config["range"][1], variable=var, orient=tk.HORIZONTAL) # 滑块
            slider.pack(side=tk.LEFT, fill=tk.X, expand=True) 
            entry = ttk.Entry(control_frame, textvariable=var, width=8)
            entry.pack(side=tk.LEFT)
            config["var"] = var
            var.trace("w", lambda *args, c=config, pid=param_id: self.on_param_change(None, c, pid)) # 绑定滑块事件

        status_label = ttk.Label(frame, text="设置状态: 未设置", foreground="gray")
        status_label.pack(fill=tk.X)
        config["status_label"] = status_label

    def on_param_change(self, event, config, param_id): # 参数改变事件
        try:
            value = config["var"].get() # 获取值
            if config.get("options", ""): # 下拉框
                options = config["options"].split("；")
                value = options.index(value)
            else:
                value = int(value) # 转换为整数
                min_val, max_val = config["range"] # 获取范围
                if not (min_val <= value <= max_val):
                    raise ValueError(f"数值超出范围 {min_val}~{max_val}")

            old_value = config.get('old_value', None) # 保存旧值
            if old_value == value:
                return
            config['old_value'] = value

            # 处理白平衡时先检查自动白平衡状态
            if param_id == "0x0098091a":
                auto_wb_config = CameraConfig.PARAM_MAP["0x0098090c"]
                auto_wb_var = auto_wb_config["var"] # 自动白平衡变量
                auto_wb_value = auto_wb_var.get()
                if isinstance(auto_wb_value, str):
                    auto_wb_val = auto_wb_config["options"].split("；").index(auto_wb_value)
                else:
                    auto_wb_val = auto_wb_value
                if auto_wb_val == 1:  # 开启状态，先关闭
                    with self.camera_controller.lock:
                        ret_wb = self.camera_controller.cap.set(auto_wb_config["cv_constant"], 0)
                    if ret_wb:
                        auto_wb_var.set("关闭")
                        auto_wb_config['old_value'] = 0
                    else:
                        print(f"{self.device_id} 关闭自动白平衡失败，无法设置手动白平衡")
                        return

            if config["cv_constant"] is not None: # 设置参数
                with self.camera_controller.lock:
                    ret = self.camera_controller.cap.set(config["cv_constant"], value)
                    # 验证设置是否成功
                    current_value = self.camera_controller.cap.get(config["cv_constant"])
                    ret = ret and (current_value == value)

                color = "green" if ret else "red" # 设置状态颜色
                status_msg = f"{self.device_id} 修改 {config['chinese_name']} 为 {value}，状态: {'成功' if ret else '失败'}"
                print(f"\033[{32 if color == 'green' else 31}m{status_msg}\033[0m")
                config["status_label"].config(text=f"设置状态: {'成功' if ret else '失败'}", foreground=color)
                if ret:
                    with self.camera_controller.lock: # 验证设置是否成功
                        current_value = self.camera_controller.cap.get(config["cv_constant"])
                    if current_value != value:
                        print(f"{self.device_id} 参数 {config['chinese_name']} 设置后自动恢复，期望 {value}，实际 {current_value}")
        except ValueError as ve:
            status_msg = f"{self.device_id} 参数错误: {str(ve)}"
            print(f"\033[31m{status_msg}\033[0m")
            config["status_label"].config(text=f"错误: {str(ve)}", foreground="red")
        except Exception as e:
            status_msg = f"{self.device_id} 修改出错: {str(e)}"
            print(f"\033[31m{status_msg}\033[0m")
            config["status_label"].config(text="设置状态: 出错", foreground="red")

    def add_buttons(self): # 添加按钮
        button_frame = ttk.Frame(self.main_frame)
        button_frame.grid(row=self.row, column=0, columnspan=3, pady=10)
        ttk.Button(button_frame, text="重置(R)", command=self.reset_params).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="保存(S)", command=self.save_params).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="退出(Q)", command=self.exit_app).pack(side=tk.LEFT, padx=5)

    def reset_params(self): # 重置参数
        for param_id, config in CameraConfig.PARAM_MAP.items():
            if config["cv_constant"] is not None:
                try:
                    default_val = config["value"] # 默认值
                    if config.get("options", ""):
                        options = config["options"].split("；")
                        config["var"].set(options[default_val])
                    else:
                        config["var"].set(default_val) # 设置默认值
                    with self.camera_controller.lock:
                        ret = self.camera_controller.cap.set(config["cv_constant"], default_val) # 设置参数
                        current_value = self.camera_controller.cap.get(config["cv_constant"]) # 验证设置是否成功
                        ret = ret and (current_value == default_val)

                    color = "green" if ret else "red"
                    status_msg = f"{self.device_id} 重置 {config['chinese_name']} 成功"
                    print(f"\033[{32 if color == 'green' else 31}m{status_msg}\033[0m")
                    config["status_label"].config(text="设置状态: 成功", foreground=color)
                except Exception as e:
                    print(f"\033[31m{self.device_id} 重置出错: {str(e)}\033[0m")

    def save_params(self): # 保存参数
        params_to_save = {}
        try:
            with open(CONFIG_FILE, 'r') as f:
                all_params = json.load(f)
        except FileNotFoundError:
            all_params = {}

        for param_id, config in CameraConfig.PARAM_MAP.items():
            params_to_save[param_id] = config["var"].get()

        all_params[self.device_id] = params_to_save # 保存参数

        with open(CONFIG_FILE, 'w') as f:
            json.dump(all_params, f, indent=2)

        print(f"{self.device_id} 参数已保存至 {CONFIG_FILE}")

    def exit_app(self):
        self.camera_controller.exit_event.set()
        self.destroy()

def list_cameras():
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")] # 视频设备

    for device in video_devices: # 检测设备
        try:
            result = subprocess.run(
                ["v4l2-ctl", "-d", device, "--all"],
                capture_output=True,
                text=True,
                timeout=5
            )
            output = result.stdout

            if "Driver name      : uvcvideo" in output:
                cap = cv2.VideoCapture(device)
                if cap.isOpened():
                    index = int(device.split('video')[1])
                    try:
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
                    except:
                        available.append((index, "UNKNOWN"))
                    cap.release()
        except Exception as e:
            print(f"设备检测错误: {str(e)}")
    return available

def display_frames(): 
    windows = {}
    while True:
        try:
            device_id, frame = frame_queue.get(timeout=0.1) # 获取帧
            if device_id not in windows:
                cv2.namedWindow(device_id, cv2.WINDOW_NORMAL) # 创建窗口
                cv2.resizeWindow(device_id, 640, 480)
            cv2.imshow(device_id, frame)
            cv2.waitKey(1)
        except Empty:
            pass
        except Exception as e:
            print(f"显示异常: {str(e)}")

def main():
    camera_info = list_cameras()
    if not camera_info:
        print("未检测到摄像头设备")
        return
    root = tk.Tk() # 主窗口
    root.withdraw() # 隐藏主窗口
    display_thread = Thread(target=display_frames, daemon=True) # 显示线程
    display_thread.start() # 启动显示线程
    for index, device_id in camera_info:
        camera_controller = CameraController(index, device_id)
        if not camera_controller.initialize():
            print(f"{device_id} 相机初始化失败，未开启")
            continue
        app = CameraControlPro(root, camera_controller) # 创建窗口
        camera_thread = Thread(target=camera_controller.run, daemon=True) # 相机线程
        camera_thread.start()
    root.mainloop()
    display_thread.join()

if __name__ == "__main__":
    main()

EOF

############################################################################################
echo -e "\n\033[32m 多相机调试脚本 ${PYTHON_CAMERA_VITAI_DOUBLE} \033[0m"
cat << 'EOF' > "$WORK_DIR/${PYTHON_CAMERA_VITAI_DOUBLE}"
# 多相机调试脚本
import os
import cv2
import json
import time
import subprocess
import tkinter as tk
from tkinter import ttk
from queue import Queue, Empty
from threading import Thread, Event, Lock

# 全局配置
MAX_FPS = 30 # 最大帧率
CONFIG_FILE = "camera_params.json" # 配置文件

# 定义队列用于传递帧数据
frame_queue = Queue(maxsize=2)

class CameraConfig:
# 十六进制
# 中文名
# 默认值
# 值域
# 选项
# 类型
# opencv常量
    PARAM_MAP = {
        "0x00980900": {
            "chinese_name": "亮度",
            "value": -64,
            "range": (-64, 64),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_BRIGHTNESS
        },
        "0x00980901": {
            "chinese_name": "对比度",
            "value": 39,
            "range": (0, 100),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_CONTRAST
        },
        "0x00980902": {
            "chinese_name": "饱和度",
            "value": 72,
            "range": (0, 100),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_SATURATION
        },
        "0x00980903": {
            "chinese_name": "色调",
            "value": 0,
            "range": (-180, 180),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_HUE
        },
        "0x0098090c": {
            "chinese_name": "自动白平衡",
            "value": 0,
            "range": (0, 1),
            "options": "关闭；开启",
            "type": bool,
            "cv_constant": cv2.CAP_PROP_AUTO_WB
        },
        "0x00980910": {
            "chinese_name": "伽马值",
            "value": 300,
            "range": (100, 500),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_GAMMA
        },
        "0x00980913": {
            "chinese_name": "增益",
            "value": 64,
            "range": (1, 128),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_GAIN
        },
        "0x00980918": {
            "chinese_name": "电源频率",
            "value": 1,
            "range": (0, 2),
            "options": "禁用；50 Hz；60 Hz",
            "type": int,
            "cv_constant": None
        },
        "0x0098091a": {
            "chinese_name": "白平衡",
            "value": 6000,
            "range": (2800, 6500),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_WHITE_BALANCE_BLUE_U
        },
        "0x0098091b": {
            "chinese_name": "清晰度",
            "value": 75,
            "range": (0, 100),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_SHARPNESS
        },
        "0x0098091c": {
            "chinese_name": "背光补偿",
            "value": 0,
            "range": (0, 2),
            "options": "",
            "type": int,
            "cv_constant": None
        },
        "0x009a0901": {
            "chinese_name": "自动曝光",
            "value": 1,
            "range": (1, 3),
            "options": "手动；光圈优先",
            "type": int,
            "cv_constant": cv2.CAP_PROP_AUTO_EXPOSURE
        },
        "0x009a0902": {
            "chinese_name": "绝对曝光时间",
            "value": 20,
            "range": (0, 10000),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_EXPOSURE
        },
        "0x009a0903": {
            "chinese_name": "动态帧率曝光",
            "value": 0,
            "range": (0, 1),
            "options": "关闭；开启",
            "type": bool,
            "cv_constant": None
        },
        "0x009a090a": {
            "chinese_name": "绝对焦点",
            "value": 68,
            "range": (0, 1023),
            "options": "",
            "type": int,
            "cv_constant": cv2.CAP_PROP_FOCUS
        },
        "0x009a090c": {
            "chinese_name": "连续自动对焦",
            "value": 1,
            "range": (0, 1),
            "options": "关闭；开启",
            "type": bool,
            "cv_constant": None
        }
    }


class CameraController: # 相机控制器
    def __init__(self, index, device_id):
        self.cap = None
        self.index = index
        self.device_id = device_id
        self.exit_event = Event()
        self.lock = Lock()
        self.last_frame_time = 0

    def initialize(self): # 初始化相机
        with self.lock: 
            self.cap = cv2.VideoCapture(self.index) # 打开相机
            if not self.cap.isOpened(): # 检查相机是否打开
                return False
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1) # 设置缓冲区大小
            self._init_params()
            return True

    def _init_params(self): # 初始化参数
        try:
            with open(CONFIG_FILE, 'r') as f: # 读取配置文件
                saved_params = json.load(f).get(self.device_id, {}) # 读取保存的参数
        except FileNotFoundError:
            saved_params = {}

        for param_id, config in CameraConfig.PARAM_MAP.items(): # 初始化参数
            value = saved_params.get(param_id, config["value"])
            if config["cv_constant"] is not None:
                try:
                    ret = self.cap.set(config["cv_constant"], value) # 设置参数
                    if not ret:
                        print(f"{self.device_id} 参数 {config['chinese_name']} 初始化失败")
                except Exception as e:
                    print(f"{self.device_id} 参数 {config['chinese_name']} 初始化错误: {str(e)}")

    def run(self): # 运行相机
        while not self.exit_event.is_set(): # 循环读取帧
            with self.lock:
                if self.cap.isOpened():
                    if time.time() - self.last_frame_time < 1 / MAX_FPS: # 限制帧率
                        time.sleep(0.001)
                        continue
                    ret, frame = self.cap.read()
                    self.last_frame_time = time.time() # 记录帧时间
                    if ret and not frame_queue.full(): # 将帧放入队列
                        frame = cv2.resize(frame, (640, 480))
                        frame_queue.put((self.device_id, frame), block=False)
            time.sleep(0.001)


class CameraControlPro(tk.Toplevel): # 相机控制界面
    def __init__(self, master, camera_controller): # 初始化相机控制界面
        super().__init__(master)
        self.camera_controller = camera_controller # 相机控制器
        self.title(camera_controller.device_id) # 设置标题
        self.protocol("WM_DELETE_WINDOW", self.exit_app)
        self.row = 0
        self.main_frame = ttk.Frame(self, padding=20)
        self.main_frame.pack(fill=tk.BOTH, expand=True)
        self.create_controls()
        self.add_buttons()
        self.bind('<KeyPress-r>', lambda e: self.reset_params()) # 重置参数
        self.bind('<KeyPress-s>', lambda e: self.save_params()) # 保存参数
        self.bind('<KeyPress-q>', lambda e: self.exit_app()) # 退出程序
        self.device_id = camera_controller.device_id

    def create_controls(self):
        param_list = list(CameraConfig.PARAM_MAP.items()) # 参数列表
        for i in range(0, len(param_list), 3):
            for col in range(3):
                if i + col < len(param_list): # 添加控件
                    param_id, config = param_list[i + col]
                    frame = ttk.LabelFrame(self.main_frame, text=config["chinese_name"]) # 创建控件容器
                    frame.grid(row=self.row, column=col, padx=5, pady=5, sticky="nsew") # 添加控件容器
                    self._create_control_widget(frame, config, param_id)
            self.row += 1

    def _create_control_widget(self, frame, config, param_id): # 创建控件
        range_default = ttk.Label(frame, text=f"范围: {config['range'][0]} ~ {config['range'][1]} | 默认: {config['value']}")
        range_default.pack(fill=tk.X)

        control_frame = ttk.Frame(frame)
        control_frame.pack(fill=tk.X, pady=2)

        if config.get("options", ""): # 添加下拉框
            options = config["options"].split("；") # 选项列表
            var = tk.StringVar(value=options[config["value"]]) # 选项变量
            cb = ttk.Combobox(control_frame, textvariable=var, values=options) # 添加下拉框
            cb.pack(side=tk.LEFT, fill=tk.X, expand=True)
            config["var"] = var # 选项变量
            cb.bind("<<ComboboxSelected>>", lambda e, c=config, pid=param_id: self.on_param_change(e, c, pid)) # 绑定事件
        else:
            var = tk.IntVar(value=config["value"])
            slider = ttk.Scale(control_frame, from_=config["range"][0], to=config["range"][1], variable=var, orient=tk.HORIZONTAL) # 添加滑块
            slider.pack(side=tk.LEFT, fill=tk.X, expand=True)
            entry = ttk.Entry(control_frame, textvariable=var, width=8)
            entry.pack(side=tk.LEFT)
            config["var"] = var
            var.trace("w", lambda *args, c=config, pid=param_id: self.on_param_change(None, c, pid))

        status_label = ttk.Label(frame, text="设置状态: 未设置", foreground="gray") # 添加状态标签
        status_label.pack(fill=tk.X)
        config["status_label"] = status_label

    def on_param_change(self, event, config, param_id): # 参数改变事件
        try:
            value = config["var"].get() # 获取参数值
            if config.get("options", ""):
                options = config["options"].split("；")
                value = options.index(value) # 获取选项索引
            else:
                value = int(value) # 获取数值
                min_val, max_val = config["range"] # 获取参数范围
                if not (min_val <= value <= max_val):
                    raise ValueError(f"数值超出范围 {min_val}~{max_val}")

            old_value = config.get('old_value', None)
            if old_value == value: # 参数值未改变
                return
            config['old_value'] = value

            if param_id == "0x009a0902": # 自动曝光
                auto_exposure_config = CameraConfig.PARAM_MAP["0x009a0901"] # 自动曝光参数
                auto_exposure_val = auto_exposure_config["var"].get()
                if isinstance(auto_exposure_val, str): # 自动曝光选项
                    auto_exposure_val = auto_exposure_config["options"].split("；").index(auto_exposure_val)
                if auto_exposure_val != 1: # 自动曝光未开启
                    self.camera_controller.cap.set(auto_exposure_config["cv_constant"], 1)
                    auto_exposure_config["var"].set(1)
                    auto_exposure_config['old_value'] = 1

            if config["cv_constant"] is not None:
                with self.camera_controller.lock:
                    ret = self.camera_controller.cap.set(config["cv_constant"], value)
                    # 读取设置后的参数值，验证是否设置成功
                    current_value = self.camera_controller.cap.get(config["cv_constant"])
                    ret = ret and (current_value == value)

                color = "green" if ret else "red"
                status_msg = f"{self.device_id} 修改 {config['chinese_name']} 为 {value}，状态: {'成功' if ret else '失败'}"
                print(f"\033[{32 if color == 'green' else 31}m{status_msg}\033[0m")
                config["status_label"].config(text=f"设置状态: {'成功' if ret else '失败'}", foreground=color)
                if ret:
                    with self.camera_controller.lock:
                        current_value = self.camera_controller.cap.get(config["cv_constant"])
                    if current_value != value:
                        print(f"{self.device_id} 参数 {config['chinese_name']} 设置后自动恢复，期望 {value}，实际 {current_value}")
        except ValueError as ve:
            status_msg = f"{self.device_id} 参数错误: {str(ve)}"
            print(f"\033[31m{status_msg}\033[0m")
            config["status_label"].config(text=f"错误: {str(ve)}", foreground="red")
        except Exception as e:
            status_msg = f"{self.device_id} 修改出错: {str(e)}"
            print(f"\033[31m{status_msg}\033[0m")
            config["status_label"].config(text="设置状态: 出错", foreground="red")

    def add_buttons(self): # 添加按钮
        button_frame = ttk.Frame(self.main_frame)
        button_frame.grid(row=self.row, column=0, columnspan=3, pady=10)
        ttk.Button(button_frame, text="重置(R)", command=self.reset_params).pack(side=tk.LEFT, padx=5) # 重置按钮
        ttk.Button(button_frame, text="保存(S)", command=self.save_params).pack(side=tk.LEFT, padx=5) # 保存按钮
        ttk.Button(button_frame, text="退出(Q)", command=self.exit_app).pack(side=tk.LEFT, padx=5) # 退出按钮

    def reset_params(self):
        for param_id, config in CameraConfig.PARAM_MAP.items(): # 重置参数
            if config["cv_constant"] is not None:
                try:
                    default_val = config["value"]
                    if config.get("options", ""):
                        options = config["options"].split("；")
                        config["var"].set(options[default_val])
                    else:
                        config["var"].set(default_val)
                    with self.camera_controller.lock:
                        ret = self.camera_controller.cap.set(config["cv_constant"], default_val) # 设置参数
                        # 读取设置后的参数值，验证是否设置成功
                        current_value = self.camera_controller.cap.get(config["cv_constant"]) # 读取设置后的参数值
                        ret = ret and (current_value == default_val)

                    color = "green" if ret else "red" # 设置状态
                    status_msg = f"{self.device_id} 重置 {config['chinese_name']} 成功"
                    print(f"\033[{32 if color == 'green' else 31}m{status_msg}\033[0m")
                    config["status_label"].config(text="设置状态: 成功", foreground=color)
                except Exception as e:
                    print(f"\033[31m{self.device_id} 重置出错: {str(e)}\033[0m")

    def save_params(self): # 保存参数
        params_to_save = {}
        try:
            with open(CONFIG_FILE, 'r') as f: # 读取参数
                all_params = json.load(f)
        except FileNotFoundError:
            all_params = {}

        for param_id, config in CameraConfig.PARAM_MAP.items(): # 保存参数
            params_to_save[param_id] = config["var"].get()

        all_params[self.device_id] = params_to_save

        with open(CONFIG_FILE, 'w') as f:
            json.dump(all_params, f, indent=2)

        print(f"{self.device_id} 参数已保存至 {CONFIG_FILE}")

    def exit_app(self): # 退出程序
        self.camera_controller.exit_event.set() # 设置退出事件
        self.destroy() # 销毁窗口


def list_cameras(): # 检测摄像头设备
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")]

    for device in video_devices:
        try:
            result = subprocess.run(
                ["v4l2-ctl", "-d", device, "--all"],
                capture_output=True,
                text=True,
                timeout=5
            )
            output = result.stdout

            if "Driver name      : uvcvideo" in output:
                cap = cv2.VideoCapture(device)
                if cap.isOpened():
                    index = int(device.split('video')[1])
                    try:
                        cmd = ["udevadm", "info", "-q", "property", device] # 获取设备信息
                        result = subprocess.run(cmd, capture_output=True, text=True) # 获取设备信息
                        vid, pid = "N/A", "N/A"
                        for line in result.stdout.splitlines(): # 获取设备信息
                            if line.startswith("ID_VENDOR_ID="):
                                vid = line.split('=')[1].strip().upper()
                            elif line.startswith("ID_MODEL_ID="):
                                pid = line.split('=')[1].strip().upper()
                        device_id = f"{vid}-{pid}" if vid != "N/A" and pid != "N/A" else "UNKNOWN" # 获取设备信息
                        available.append((index, device_id))
                    except:
                        available.append((index, "UNKNOWN"))
                    cap.release()
        except Exception as e:
            print(f"设备检测错误: {str(e)}")
    return available


def display_frames(): 
    windows = {}
    while True:
        try:
            device_id, frame = frame_queue.get(timeout=0.1) # 获取帧
            if device_id not in windows:
                cv2.namedWindow(device_id, cv2.WINDOW_NORMAL) # 创建窗口
                cv2.resizeWindow(device_id, 640, 480)
            cv2.imshow(device_id, frame)
            cv2.waitKey(1)
        except Empty:
            pass
        except Exception as e:
            print(f"显示异常: {str(e)}")


def main():
    camera_info = list_cameras()
    if not camera_info:
        print("未检测到摄像头设备")
        return
    root = tk.Tk() # 创建主窗口
    root.withdraw() # 隐藏主窗口
    display_thread = Thread(target=display_frames, daemon=True)
    display_thread.start()
    for index, device_id in camera_info:
        camera_controller = CameraController(index, device_id)
        if not camera_controller.initialize():
            print(f"{device_id} 相机初始化失败，未开启")
            continue
        app = CameraControlPro(root, camera_controller)  # 实例化修正后的类
        camera_thread = Thread(target=camera_controller.run, daemon=True) # 创建相机线程
        camera_thread.start() # 启动相机线程
    root.mainloop() # 启动主窗口
    display_thread.join() # 等待显示线程结束


if __name__ == "__main__":
    main()
EOF

############################################################################################
echo -e "\n\033[32m 单相机调试桌面快捷方式 ${PYTHON_TO_DESKTOP} \033[0m"

PYTHON_TOT_DESKTOP="[Desktop Entry]
Version=1.0
Type=Application
Name=ViTai Camera Debug
Comment=Camera Debug Environment
Exec=bash -c \"source ${PYTHON_VENV} && python ${WORK_DIR}/${PYTHON_CAMERA_LIST} && python ${WORK_DIR}/${PYTHON_CAMERA_OPEN} && python ${WORK_DIR}/${PYTHON_CAMERA_VITAI}\"
Terminal=true
Categories=Development;Education; "

# 写入 .desktop 文件
echo "$PYTHON_TOT_DESKTOP" > "$PYTHON_TO_DESKTOP"

############################################################################################

# 输出完成信息
echo -e "\n\033[32m恢复阿里云镜像源文件\033[0m"

# 检查备份文件是否存在
if [ -f /etc/apt/sources.list.bak ]; then
    sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
else
    echo "备份文件 /etc/apt/sources.list.bak 不存在，无法恢复。"
fi
    
# 修复脚本权限
echo -e "\n\033[32m修复快捷方式\033[0m"
chown "$CURRENT_USER:$CURRENT_USER" "${PYTHON_TO_DESKTOP}"
chmod 755 "${PYTHON_TO_DESKTOP}"

# 修复工作目录权限
echo -e "\n\033[32m修复文件权限\033[0m"
chown -R "$CURRENT_USER:$CURRENT_USER" "$WORK_DIR"
find "$WORK_DIR" -type f -exec chmod 644 {} \;
find "$WORK_DIR" -type d -exec chmod 755 {} \;

# 内核与设备修复
echo -e "\n\033[32m执行系统级修复\033[0m"
modprobe -r uvcvideo && modprobe uvcvideo # 修复uvcvideo内核模块
echo 'SUBSYSTEM=="video4linux", MODE="0666", GROUP="video"' > "$UDEV_RULE_FILE" # 添加udev规则  
udevadm control --reload # 重新加载udev规则
udevadm trigger

#==================================================================================================================
# 运行结束
echo -e "\n\033[32m安装完成\033[0m"

# 自动运行脚本
echo -e "\n\033[1;31m激活虚拟环境 运行相机列表脚本 执行相机预览脚本\033[0m"
echo
source "${PYTHON_VENV}" && python "${WORK_DIR}/${PYTHON_CAMERA_LIST}" && python "${WORK_DIR}/${PYTHON_CAMERA_OPEN}"

exit
