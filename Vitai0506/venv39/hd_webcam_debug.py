# ====================================================== 程序声明 ======================================================
print("\n\033[93m【带UI界面的 HD_WebCam 相机专用调试工具】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
import os
import cv2
import time
import subprocess
import tkinter as tk
from tkinter import ttk
from queue import Queue, Empty
from threading import Thread, Event, Lock

# 全局配置
MAX_FPS = 30  # 最大帧率

# 选择方案初始化参数
INITIAL_SCHEME_NAME = "默认值"

# "方案"：[亮度,对比度,饱和度,色调,自动白平衡,伽马值,电源频率,白平衡,温度,清晰度,背光补偿,自动曝光,绝对曝光时间,隐私模式]
# 下面提供3组方案仅参考，用户可以自行添加方案，也可以修改当前方案的数值
SCHEMES = {
    "默认值": [128, 34, 58, 0, 1, 120, 1, 4000, 2, 0, 3, 156, 0],
    "方案1":  [128, 34, 58, 0, 0, 120, 1, 6000, 2, 0, 3, 156, 0],
    "方案2":  [128, 34, 58, 0, 0, 120, 1, 5000, 2, 0, 3, 156, 0],
}

# 参数定义结构
BASE_CAMERA_PARAMS = [
    {
        "chinese_name": "亮度",
        "v4l2_param": "brightness",
        "hex_numbers": "0x00980900",
        "type": "int",
        "min": 0,
        "max": 255,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "对比度",
        "v4l2_param": "contrast",
        "hex_numbers": "0x00980901",
        "type": "int",
        "min": 0,
        "max": 255,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "饱和度",
        "v4l2_param": "saturation",
        "hex_numbers": "0x00980902",
        "type": "int",
        "min": 0,
        "max": 100,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "色调",
        "v4l2_param": "hue",
        "hex_numbers": "0x00980903",
        "type": "int",
        "min": -180,
        "max": 180,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "自动白平衡",
        "v4l2_param": "white_balance_automatic",
        "hex_numbers": "0x0098090c",
        "type": "bool",
        "min": None,
        "max": None,
        "step": None,
        "options": "0 表示关闭；1 表示开启",
    },
    {
        "chinese_name": "伽马值",
        "v4l2_param": "gamma",
        "hex_numbers": "0x00980910",
        "type": "int",
        "min": 90,
        "max": 150,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "电源频率",
        "v4l2_param": "power_line_frequency",
        "hex_numbers": "0x00980918",
        "type": "menu",
        "min": 0,
        "max": 2,
        "step": None,
        "options": "0 表示禁用；1 表示 50Hz；2 表示 60Hz",
    },
    {
        "chinese_name": "白平衡温度",
        "v4l2_param": "white_balance_temperature",
        "hex_numbers": "0x0098091a",
        "type": "int",
        "min": 2800,
        "max": 6500,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "清晰度",
        "v4l2_param": "sharpness",
        "hex_numbers": "0x0098091b",
        "type": "int",
        "min": 0,
        "max": 7,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "背光补偿",
        "v4l2_param": "backlight_compensation",
        "hex_numbers": "0x0098091c",
        "type": "int",
        "min": 0,
        "max": 2,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "自动曝光",
        "v4l2_param": "auto_exposure",
        "hex_numbers": "0x009a0901",
        "type": "menu",
        "min": 0,
        "max": 3,
        "step": None,
        "options": "1 表示手动模式；3 表示光圈优先模式",
    },
    {
        "chinese_name": "绝对曝光时间",
        "v4l2_param": "exposure_time_absolute",
        "hex_numbers": "0x009a0902",
        "type": "int",
        "min": 10,
        "max": 2500,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "隐私模式",
        "v4l2_param": "privacy",
        "hex_numbers": "0x009a0910",
        "type": "bool",
        "min": None,
        "max": None,
        "step": None,
        "options": "0 表示关闭；1 表示开启",
    }
]


# 根据方案初始化参数
def initialize_params_with_scheme(scheme):
    for i, param in enumerate(BASE_CAMERA_PARAMS): # 初始化参数
        param["default"] = scheme[i]
        param["value"] = scheme[i]
        param["setvalue"] = scheme[i]
    return BASE_CAMERA_PARAMS

# 初始化参数
BASE_CAMERA_PARAMS = initialize_params_with_scheme(SCHEMES[INITIAL_SCHEME_NAME])

# 摄像头控制器
class CameraController: # 摄像头控制器
    def __init__(self, index, device_id):
        self.cap = None
        self.index = index
        self.device_id = device_id
        self.exit_event = Event()
        self.lock = Lock()
        self.last_frame_time = 0
        self.camera_params = [param.copy() for param in BASE_CAMERA_PARAMS] # 摄像头参数

    def initialize(self):  # 初始化摄像头
        with self.lock:
            self.cap = cv2.VideoCapture(self.index)  # 打开摄像头
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)  #由于相机 HD WebCam 的分辨率是 1920x1080，所以特此修改
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)  #由于相机 HD WebCam 的分辨率是 1920x1080，所以特此修改
            if not self.cap.isOpened():  # 检查是否打开成功
                return False # 打开失败
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            self._init_params()
            return True

    def _init_params(self):  # 初始化参数
        for param in self.camera_params:
            value = param["value"]
            self._set_v4l2_param(param, value)

    def _set_v4l2_param(self, param, value): # 设置摄像头参数
        device = f"/dev/video{self.index}"
        cmd = f"v4l2-ctl -d {device} --set-ctrl={param['v4l2_param']}={value}" # 设置摄像头参数
        print(f"执行命令: {cmd}")
        result = subprocess.run(cmd, shell=True, check=False, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"命令执行失败，错误信息: {result.stderr}")

    def run(self):  # 运行摄像头
        while not self.exit_event.is_set():  # 循环读取摄像头
            with self.lock:  # 加锁
                if self.cap.isOpened():  # 检查摄像头是否打开
                    if time.time() - self.last_frame_time < 1 / MAX_FPS:  # 限制帧率
                        time.sleep(0.001)
                        continue
                    ret, frame = self.cap.read() # 读取摄像头
                    self.last_frame_time = time.time()
                    if ret and not frame_queue.full():  # 将帧放入队列
                        #frame = cv2.resize(frame, (640, 480))  # 缩放  #由于相机 HD WebCam 的分辨率是 1920x1080，所以特此修改
                        frame_queue.put((self.device_id, frame), block=False)
            time.sleep(0.001)
        with self.lock:
            if self.cap.isOpened():
                self.cap.release()


class CameraControlPro(tk.Toplevel):  # 摄像头控制界面
    def __init__(self, master, camera_controller):
        super().__init__(master)
        self.camera_controller = camera_controller  # 摄像头控制器
        self.scheme_values = SCHEMES
        self.title(camera_controller.device_id)  # 设置标题
        self.protocol("WM_DELETE_WINDOW", self.exit_app)  # 退出时关闭窗口
        self.row = 0
        self.main_frame = ttk.Frame(self, padding=20)  # 主框架
        self.main_frame.pack(fill=tk.BOTH, expand=True)  # 设置主框架
        self.create_controls()  # 创建控件
        self.add_buttons()  # 添加按钮
        self.bind('<KeyPress-q>', lambda e: self.exit_app())  # 退出
        self.device_id = camera_controller.device_id  # 设备ID

    def create_controls(self):  # 创建控件
        param_list = self.camera_controller.camera_params # 摄像头参数
        for i in range(0, len(param_list), 3):
            for col in range(3): # 3列
                if i + col < len(param_list):
                    param = param_list[i + col]
                    frame = ttk.LabelFrame(self.main_frame, text=param["chinese_name"])
                    frame.grid(row=self.row, column=col, padx=5, pady=5, sticky="nsew")
                    self._create_control_widget(frame, param)
            self.row += 1

    def _create_control_widget(self, frame, param): # 创建控件
        control_frame = ttk.Frame(frame)
        control_frame.pack(fill=tk.X, pady=2)

        # 显示值范围
        range_label = ttk.Label(frame, text=f"范围: {param['min']} ~ {param['max']}")
        range_label.pack(fill=tk.X)
        # 显示用户值
        user_value_label = ttk.Label(frame, text=f"用户值: {param['setvalue']}")
        user_value_label.pack(fill=tk.X)

        if param["type"] == "int": # 整数
            var = tk.IntVar(value=param["value"]) # 整数变量
            slider = ttk.Scale(
                control_frame,
                from_=param["min"],
                to=param["max"],
                variable=var,
                orient=tk.HORIZONTAL
            )
            slider.pack(side=tk.LEFT, fill=tk.X, expand=True) # 设置滑块
            entry = ttk.Entry(control_frame, textvariable=var, width=8)
            entry.pack(side=tk.LEFT)
            param["var"] = var
            var.trace("w", lambda *args: self.on_param_change(param)) # 监听变量变化
        elif param["type"] == "menu":
            options = param["options"].split("；")
            if 0 <= param["value"] < len(options):
                var = tk.StringVar(value=options[param["value"]]) # 字符串变量
            else:
                var = tk.StringVar(value=options[0])
                print(f"警告: 参数 {param['chinese_name']} 的值 {param['value']} 超出选项索引范围，使用第一个选项。") # 终端红色输出警告
            cb = ttk.Combobox(control_frame, textvariable=var, values=options)
            cb.pack(fill=tk.X, expand=True)
            param["var"] = var
            cb.bind("<<ComboboxSelected>>", lambda event: self.on_param_change(param)) # 监听变量变化
        elif param["type"] == "bool":
            var = tk.IntVar(value=param["value"])
            cb = ttk.Checkbutton(control_frame, variable=var)
            cb.pack(side=tk.LEFT)
            param["var"] = var
            var.trace("w", lambda *args: self.on_param_change(param))

        status_label = ttk.Label(frame, text="设置状态: 未设置", foreground="gray") # 设置状态
        status_label.pack(fill=tk.X)
        param["status_label"] = status_label

    def on_param_change(self, param): # 设置参数
        try:
            value = None
            if param["type"] == "int":
                value = param["var"].get()
                if not (param["min"] <= value <= param["max"]):
                    raise ValueError(f"数值超出范围 {param['min']}~{param['max']}")
            elif param["type"] == "menu":
                options = param["options"].split("；")
                value = options.index(param["var"].get())
            elif param["type"] == "bool":
                value = param["var"].get()

            device = f"/dev/video{self.camera_controller.index}" # 摄像头设备
            cmd = f"v4l2-ctl -d {device} --set-ctrl={param['v4l2_param']}={value}"
            result = subprocess.run(cmd, shell=True, check=False, capture_output=True, text=True) # 设置摄像头参数
            if result.returncode == 0:
                param["status_label"].config(text="设置状态: 成功", foreground="green")
            else:
                param["status_label"].config(text="设置状态: 失败", foreground="red")
                print(f"\033[31m错误：{self.camera_controller.device_id} 的 {param['chinese_name']} 设置失败\033[0m")  # 终端红色输出错误提示
        except ValueError as ve:
            param["status_label"].config(text="设置状态: 数值超出范围", foreground="red")
            print(f"\033[31m错误：{self.camera_controller.device_id} 的 {param['chinese_name']} 数值超出范围\033[0m")
        except Exception:
            param["status_label"].config(text="设置状态: 出错", foreground="red")
            print(f"\033[31m错误：{self.camera_controller.device_id} 的 {param['chinese_name']} 设置出错\033[0m")

    def add_buttons(self):  # 添加按钮
        button_frame = ttk.Frame(self.main_frame)
        button_frame.grid(row=self.row, column=0, columnspan=3, pady=10)
        for name in self.scheme_values.keys():
            ttk.Button(button_frame, text=name, command=lambda name=name: self.reset_params(name)).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="退出(Q)", command=self.exit_app).pack(side=tk.LEFT, padx=5)

    def reset_params(self, scheme_name):  # 修改参数重置逻辑
        scheme = self.scheme_values[scheme_name]
        for param_idx, param in enumerate(self.camera_controller.camera_params):
            val = scheme[param_idx]
            if param["type"] == "int":
                param["var"].set(val)
            elif param["type"] == "menu":
                options = param["options"].split("；")
                if val < len(options):
                    param["var"].set(options[val])
            elif param["type"] == "bool":
                param["var"].set(val)
            self.on_param_change(param)

    def exit_app(self):  # 退出
        self.camera_controller.exit_event.set()
        with self.camera_controller.lock:
            if self.camera_controller.cap.isOpened():
                self.camera_controller.cap.release()
        cv2.destroyWindow(self.camera_controller.device_id)  # 关闭窗口
        self.destroy()


def list_cameras(): # 检测摄像头
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")]  # 视频设备

    for device in video_devices:  # 检测设备
        try:
            index = int(device.split('video')[1])
            cmd = ["udevadm", "info", "-q", "property", device] # 获取设备信息
            result = subprocess.run(cmd, capture_output=True, text=True)
            vid, pid = "N/A", "N/A"
            for line in result.stdout.splitlines():   # 解析设备信息
                if line.startswith("ID_VENDOR_ID="):
                    vid = line.split('=')[1].strip().upper()
                elif line.startswith("ID_MODEL_ID="):
                    pid = line.split('=')[1].strip().upper()
            device_id = f"{vid}-{pid}" if vid != "N/A" and pid != "N/A" else "UNKNOWN" # 设备ID
            available.append((index, device_id)) # 添加设备信息
        except Exception as e:
            print(f"设备检测错误: {str(e)}")
    return available


def display_frames():  # 显示帧
    windows = {}
    while True:
        try:
            device_id, frame = frame_queue.get(timeout=0.1)  # 获取帧
            if device_id not in windows:
                cv2.namedWindow(device_id, cv2.WINDOW_NORMAL)  # 创建窗口
                cv2.resizeWindow(device_id, 640, 480)
            cv2.imshow(device_id, frame) # 显示帧
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        except Empty:
            pass
        except Exception as e:
            print(f"显示异常: {str(e)}")
    cv2.destroyAllWindows()


def main():
    global frame_queue # 帧队列
    frame_queue = Queue(maxsize=2) # 帧队列
    camera_info = list_cameras() # 摄像头信息
    if not camera_info:
        print("未检测到摄像头设备")
        return
    root = tk.Tk()  # 主窗口
    root.withdraw()  # 隐藏主窗口
    display_thread = Thread(target=display_frames, daemon=True)  # 显示线程
    display_thread.start()  # 启动显示线程

    controllers = [] # 相机控制器
    apps = []
    for index, device_id in camera_info: # 创建相机控制器
        camera_controller = CameraController(index, device_id)
        if not camera_controller.initialize(): # 初始化相机
            print(f"{device_id} 相机初始化失败，未开启")
            continue
        app = CameraControlPro(root, camera_controller)  # 创建窗口
        camera_thread = Thread(target=camera_controller.run, daemon=True)  # 相机线程
        camera_thread.start()  # 启动相机线程
        controllers.append(camera_controller) # 添加相机控制器
        apps.append(app)

    root.mainloop()
    for controller in controllers: # 关闭相机
        controller.exit_event.set()
    cv2.destroyAllWindows()  # 关闭窗口


if __name__ == "__main__":
    main()
# ----------------------------------------------------------------------------------------------------------------------
