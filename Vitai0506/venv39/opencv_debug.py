# ====================================================== 程序声明 ======================================================
print("\n\033[93m【借助OpenCV调节摄像头参数，支持保存与重置，可实时预览】\033[0m")
print("\033[91m【在采用OpenCV调试的过程中，存在部分参数无法设置，已放弃】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
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
CONFIG_FILE = "camera_params.json" # 配置文件路径，由于OpenCV支持有问题所以放弃，对此只是保留但是没有实际作用

# 定义队列用于传递帧数据
frame_queue = Queue(maxsize=2)

# 相机配置类
class CameraConfig:
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
            "value": 6500,
            "range": (2800, 6500),
            "options": "",
            "cv_constant": None  # 因为不使用 OpenCV 设置，设为 None
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
            if config["cv_constant"] is not None: # 使用 OpenCV 设置参数
                try:
                    ret = self.cap.set(config["cv_constant"], value) # 设置参数
                    if not ret:
                        print(f"{self.device_id} 参数 {config['chinese_name']} 初始化失败")
                except Exception as e:
                    print(f"{self.device_id} 参数 {config['chinese_name']} 初始化错误: {str(e)}")
            elif param_id == "0x0098091a":  # 白平衡温度
                try:
                    device = f"/dev/video{self.index}"
                    command = f"v4l2-ctl -d {device} --set-ctrl=white_balance_temperature={value}"
                    subprocess.run(command, shell=True, check=True)
                except subprocess.CalledProcessError as e:
                    print(f"{self.device_id} 参数 {config['chinese_name']} 初始化错误: {e}")

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
        range_default = ttk.Label(frame, text=f"范围: {config['range'][0]} ~ {config['range'][1]} | 默认: {config['value']}") # 范围
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

        status_label = ttk.Label(frame, text="设置状态: 未设置", foreground="gray") # 设置状态
        status_label.pack(fill=tk.X)
        config["status_label"] = status_label

    def on_param_change(self, event, config, param_id): # 参数改变事件
        try:
            value = config["var"].get() # 获取参数值
            if config.get("options", ""):
                options = config["options"].split("；")
                value = options.index(value)
            else:
                value = int(value)
                min_val, max_val = config["range"]
                if not (min_val <= value <= max_val):
                    raise ValueError(f"数值超出范围 {min_val}~{max_val}")

            old_value = config.get('old_value', None) # 保存旧值
            if old_value == value:
                return
            config['old_value'] = value

            if param_id == "0x009a090a":  # 绝对焦点
                auto_focus_config = CameraConfig.PARAM_MAP["0x009a090c"]  # 连续自动对焦参数
                auto_focus_value = auto_focus_config["var"].get()
                if isinstance(auto_focus_value, str):
                    auto_focus_val = auto_focus_config["options"].split("；").index(auto_focus_value)
                else:
                    auto_focus_val = auto_focus_value
                if auto_focus_val == 1:  # 若连续自动对焦开启
                    device = f"/dev/video{self.camera_controller.index}"
                    try:
                        command = f"v4l2-ctl -d {device} --set-ctrl=focus_automatic_continuous=0"
                        subprocess.run(command, shell=True, check=True)
                        auto_focus_config["var"].set("关闭")
                        print(f"{self.device_id} 已关闭连续自动对焦")
                    except subprocess.CalledProcessError as e:
                        print(f"{self.device_id} 关闭连续自动对焦失败，无法设置手动焦点")
                        return

            color = None  # 初始化 color 变量
            if param_id == "0x0098091a":  # 白平衡温度
                try:
                    device = f"/dev/video{self.camera_controller.index}"
                    command = f"v4l2-ctl -d {device} --set-ctrl=white_balance_temperature={value}"
                    subprocess.run(command, shell=True, check=True)
                    color = "green"
                    status_msg = f"{self.device_id} 修改 {config['chinese_name']} 为 {value}，状态: 成功"
                except subprocess.CalledProcessError as e:
                    color = "red"
                    status_msg = f"{self.device_id} 修改 {config['chinese_name']} 为 {value}，状态: 失败，错误信息: {e}"
            elif config["cv_constant"] is not None:
                with self.camera_controller.lock:
                    ret = self.camera_controller.cap.set(config["cv_constant"], value)
                    current_value = self.camera_controller.cap.get(config["cv_constant"])
                    ret = ret and (current_value == value)

                color = "green" if ret else "red"
                status_msg = f"{self.device_id} 修改 {config['chinese_name']} 为 {value}，状态: {'成功' if ret else '失败'}"
            else:
                color = "red"
                status_msg = f"{self.device_id} 修改 {config['chinese_name']} 为 {value}，状态: 失败，不支持该参数设置"

            print(f"\033[{32 if color == 'green' else 31}m{status_msg}\033[0m")
            config["status_label"].config(text=f"设置状态: {'成功' if color == 'green' else '失败'}", foreground=color)
            if color == "green":
                if param_id != "0x0098091a":
                    with self.camera_controller.lock:
                        current_value = self.camera_controller.cap.get(config["cv_constant"])
                    if current_value != value:
                        print(
                            f"{self.device_id} 参数 {config['chinese_name']} 设置后自动恢复，期望 {value}，实际 {current_value}")
        except ValueError as ve:
            color = "red"
            status_msg = f"{self.device_id} 参数错误: {str(ve)}"
            print(f"\033[31m{status_msg}\033[0m")
            config["status_label"].config(text=f"错误: {str(ve)}", foreground=color)
        except Exception as e:
            color = "red"
            status_msg = f"{self.device_id} 修改出错: {str(e)}"
            print(f"\033[31m{status_msg}\033[0m")
            config["status_label"].config(text="设置状态: 出错", foreground=color)

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
            elif param_id == "0x0098091a":  # 白平衡温度
                try:
                    device = f"/dev/video{self.camera_controller.index}"
                    default_val = config["value"]
                    command = f"v4l2-ctl -d {device} --set-ctrl=white_balance_temperature={default_val}"
                    subprocess.run(command, shell=True, check=True)
                    color = "green"
                    status_msg = f"{self.device_id} 重置 {config['chinese_name']} 成功"
                except subprocess.CalledProcessError as e:
                    color = "red"
                    status_msg = f"{self.device_id} 重置 {config['chinese_name']} 失败，错误信息: {e}"
                print(f"\033[{32 if color == 'green' else 31}m{status_msg}\033[0m")
                config["status_label"].config(text=f"设置状态: {'成功' if color == 'green' else '失败'}", foreground=color)

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

def list_cameras(): # 检测摄像头
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
            output = result.stdout # 获取输出

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

def display_frames():  # 显示帧
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
# ----------------------------------------------------------------------------------------------------------------------
