# Ubuntu 相机调试工具
## 项目概述
本项目是一款基于 Python 的 Ubuntu 相机调试工具，致力于为开发者和测试人员提供**全流程、自动化、多设备兼容**的相机调试解决方案。通过集成环境配置、设备检测、参数调节及实时预览等核心功能，降低相机调试门槛，提升调试效率。工具默认适配 ViTai 品牌 USB 相机，通过简单修改 VID/PID 即可扩展支持其他品牌相机。

---
## 核心功能特性
### 1. 自动化环境配置
- **镜像加速**：自动切换系统源至阿里云镜像，大幅提升软件包下载速度；
- **环境隔离**：创建 Python 3.9（主功能）和 3.12（序列号功能）双虚拟环境，避免依赖冲突；
- **快捷入口**：自动生成桌面快捷方式，点击即可启动调试工具；
- **权限保障**：添加 udev 规则，确保相机设备无权限限制访问。

### 2. 智能设备管理
- **自动发现**：无需手动查找，一键扫描所有可用 USB 相机设备；
- **信息可视化**：展示设备 VID/PID、制造商、序列号、驱动版本及分辨率等核心信息；
- **分类过滤**：自动区分目标设备（如 ViTai）与其他 USB 设备（如鼠标、虚拟 Hub），避免干扰。

### 3. 灵活参数调试
- **单/多设备支持**：支持单相机精细调节（亮度、对比度等）或多相机同步预览；
- **参数闭环**：调节过程实时同步画面，参数修改自动保存，支持一键重置；
- **标准兼容**：基于 V4L2 标准开发，兼容大多数遵循该协议的相机设备；
- **场景适配**：提供“测试系列”（v4l2_test_scheme.py）和“成品系列”（v4l2_test_slider.py）两种调试模式，满足不同阶段需求。

### 4. 实时预览与控制
- **多窗口同步**：支持同时打开多个相机画面，画面无延迟同步；
- **自定义参数**：可手动设置分辨率（如 640x480/1920x1080）、帧率，适配不同画质需求；
- **快捷操作**：支持 Q 键一键退出预览，窗口大小可自定义（默认 640x480）。
---

## 安装与运行
### 步骤 1：下载项目脚本
从项目仓库下载核心脚本 `camera.sh` 保存到用户主目录

### 步骤 2：修改脚本
在脚本中，使用**硬编码路径**可能会导致运行问题，解决办法如下：
- 由于文件采用 `VitaiMMDD` 命名，所以需要全局替换`Vitai0506`
- 当前相机名称为 `Vitai`，所以在修改相机名称时需要全局替换`Vitai`
- 当前指定VID PID 为 `F225-0001`，需要全局替换
- 对于其他**硬编码路径**部分已标注`【硬编码路径】`在脚本运行前检测是否有问题

### 步骤 3：赋予执行权限
```bash
chmod +x camera.sh
```

### 步骤 4：运行自动安装脚本
```bash
sudo ./camera.sh
```

**脚本自动完成**：
- 创建工作目录（格式：`~/VitaiMMDD`，如 `~/Vitai0506`）
- 安装系统依赖（如 `v4l-utils`、Python 3.9/3.12）
- 初始化双虚拟环境（`venv39`/`venv312`）并安装 SDK（`pyvitaisdk-1.0.6.whl`）
- 生成调试脚本（`camera_preview.py`、`v4l2_test_slider.py` 等）及配置文件（`camera_params.json`）
---

## 关键数据参考
### 设备信息示例
通过 `v4l2-ctl -d /dev/video0 --list-ctrls` 可查询设备参数：

```
User Controls

                     brightness 0x00980900 (int)    : min=-64 max=64 step=1 default=-39 value=-64
                       contrast 0x00980901 (int)    : min=0 max=100 step=1 default=39 value=39
                     saturation 0x00980902 (int)    : min=0 max=100 step=1 default=72 value=72
                            hue 0x00980903 (int)    : min=-180 max=180 step=1 default=0 value=0
        white_balance_automatic 0x0098090c (bool)   : default=1 value=0
                          gamma 0x00980910 (int)    : min=100 max=500 step=1 default=300 value=300
                           gain 0x00980913 (int)    : min=1 max=128 step=1 default=64 value=64
           power_line_frequency 0x00980918 (menu)   : min=0 max=2 default=1 value=1 (50 Hz)
      white_balance_temperature 0x0098091a (int)    : min=2800 max=6500 step=10 default=6500 value=6000
                      sharpness 0x0098091b (int)    : min=0 max=100 step=1 default=75 value=75
         backlight_compensation 0x0098091c (int)    : min=0 max=2 step=1 default=0 value=0

Camera Controls

                  auto_exposure 0x009a0901 (menu)   : min=0 max=3 default=3 value=1 (Manual Mode)
         exposure_time_absolute 0x009a0902 (int)    : min=0 max=10000 step=1 default=20 value=20
     exposure_dynamic_framerate 0x009a0903 (bool)   : default=0 value=1
                 focus_absolute 0x009a090a (int)    : min=0 max=1023 step=1 default=68 value=68 flags=inactive
     focus_automatic_continuous 0x009a090c (bool)   : default=1 value=1
```

```
序号   | 设备名称                        | VID        | PID    | 制造商                 | SN
----------------------------------------------------------------------------------------------------
1     | Linux Foundation 1.1 root hub  | 1D6B       | 0001   | Linux Foundation     | 
2     | VMware, Inc. Virtual USB Hub   | 0E0F       | 0002   | VMware, Inc.         | 
3     | Linux Foundation 2.0 root hub  | 1D6B       | 0002   | Linux Foundation     | 
4     | Linux Foundation 2.0 root hub  | 1D6B       | 0002   | Linux Foundation     | 
5     | VMware, Inc. Virtual Mouse     | 0E0F       | 0003   | VMware, Inc.         | 
6     | VMware, Inc. Virtual USB Hub   | 0E0F       | 0002   | VMware, Inc.         | 
7     | VMware, Inc. Virtual USB Hub   | 0E0F       | 0002   | VMware, Inc.         | 
8     | Linux Foundation 3.0 root hub  | 1D6B       | 0003   | Linux Foundation     | 
----------------------------------------------------------------------------------------------------
1     | Generic ViTai                  | FFFF       | 9002   | ViTai                | GF2259002D363
----------------------------------------------------------------------------------------------------
```

```
+--------------+----------------------------+------------+------+--------+--------+------+--------+--------+-----------------------------------------+
|   中文名称   |          英文名称          |  参数 ID   | 类型 | 最小值 | 最大值 | 步长 | 默认值 | 当前值 |                   备注                  |
+--------------+----------------------------+------------+------+--------+--------+------+--------+--------+-----------------------------------------+
|     亮度     |         brightness         | 0x00980900 | int  |  -64   |   64   |  1   |  -39   |  -64   |                    /                    |
|    对比度    |          contrast          | 0x00980901 | int  |   0    |  100   |  1   |   39   |   39   |                    /                    |
|    饱和度    |         saturation         | 0x00980902 | int  |   0    |  100   |  1   |   72   |   72   |                    /                    |
|     色调     |            hue             | 0x00980903 | int  |  -180  |  180   |  1   |   0    |   0    |                    /                    |
|  自动白平衡  |  white_balance_automatic   | 0x0098090c | bool |   /    |   /    |  /   |   1    |   0    |              0 关闭，1 开启             |
|    伽马值    |           gamma            | 0x00980910 | int  |  100   |  500   |  1   |  300   |  300   |                    /                    |
|     增益     |            gain            | 0x00980913 | int  |   1    |  128   |  1   |   64   |   64   |                    /                    |
|   电源频率   |    power_line_frequency    | 0x00980918 | menu |   /    |   /    |  /   |   1    |   1    | 0: 表示禁用；1: 表示 50Hz；2: 表示 60Hz |
|    白平衡    | white_balance_temperature  | 0x0098091a | int  |  2800  |  6500  |  10  |  6500  |  6000  |                    /                    |
|    清晰度    |         sharpness          | 0x0098091b | int  |   0    |  100   |  1   |   75   |   75   |                    /                    |
|   背光补偿   |   backlight_compensation   | 0x0098091c | int  |   0    |   2    |  1   |   0    |   0    |                    /                    |
|   自动曝光   |       auto_exposure        | 0x009a0901 | menu |   /    |   /    |  /   |   3    |   1    |   1: 表示手动模式；3: 表示光圈优先模式  |
| 绝对曝光时间 |   exposure_time_absolute   | 0x009a0902 | int  |   0    | 10000  |  1   |   20   |   20   |                    /                    |
| 动态帧率曝光 | exposure_dynamic_framerate | 0x009a0903 | bool |   /    |   /    |  /   |   0    |   1    |              0 关闭，1 开启             |
|   绝对焦点   |       focus_absolute       | 0x009a090a | int  |   0    |  1023  |  1   |   68   |   68   |                  非激活                 |
| 连续自动对焦 | focus_automatic_continuous | 0x009a090c | bool |   /    |   /    |  /   |   1    |   1    |              0 关闭，1 开启             |
+--------------+----------------------------+------------+------+--------+--------+------+--------+--------+-----------------------------------------+
```

## 项目目录结构
```
Vitai0506/
├── pyvitaisdk-1.0.6-cp312-cp312-linux_x86_64.whl  # ViTai 官方 SDK
├── venv39/                                        # Python 3.9 虚拟环境（主功能环境）
│   ├── bin/                                       # 虚拟环境二进制文件
│   ├── include/                                   # 头文件目录
│   ├── lib/                                       # 库文件目录
│   ├── lib64 -> lib                               # lib64 软链接
│   ├── pyvenv.cfg                                 # 虚拟环境配置文件
│   ├── camera_params.json                         # 相机参数配置文件
│   ├── device_list.py                             # 设备列表
│   ├── device_sn_list.py                          # 带序列号的设备列表
│   ├── camera_preview.py                          # 相机画面预览
│   ├── camera_parameter.py                        # 相机参数信息
│   ├── opencv_debug.py                            # OpenCV 调试工具（由于不支持部分参数调节现已放弃）
│   ├── v4l2_debug.py                              # V4L2 单摄像头滑块调节工具（由于不支持多设备同步调试现已放弃）
│   ├── v4l2_quick.py                              # V4L2 预定方案快速设置工具
│   ├── v4l2_test_slider.py                        # V4L2 多摄像头调试工具（用于成品系列）
│   ├── v4l2_test_scheme.py                        # V4L2 多摄像头调试工具（用于测试系列）
│   └── hd_webcam_debug.py                         # HD WebCam 调试工具
└── venv312/                                       # Python 3.12 虚拟环境（序列号相关功能）
    ├── bin/                                       # 虚拟环境二进制文件
    ├── include/                                   # 头文件目录
    ├── lib/                                       # 库文件目录
    ├── lib64 -> lib                               # lib64 软链接
    ├── pyvenv.cfg                                 # 虚拟环境配置文件
    └── device_sn.py                               # 设备序列号工具
```

---
## 常见问题与解决
### Q1：脚本运行到“安装依赖”时卡住？
- 原因：阿里云镜像源连接超时；
- 解决：手动切换为清华源（修改 `/etc/apt/sources.list`）或等待网络恢复。

### Q2: 相机无法打开？
- 检查物理连接
- 运行 `v4l2-ctl --list-devices` 确认设备存在
- 检查用户权限：`groups $USER | grep video`

### Q3：相机预览画面模糊？
- 检查自动对焦状态（`连续自动对焦`参数是否为 1）；
- 确认分辨率设置：ViTai 建议 640x480，HD WebCam 建议 1920x1080；
- 手动调节 `绝对焦点` 参数（范围 0~1023）。

### Q4: 参数设置无效？
- 部分参数需重启设备生效
- 检查自动参数状态（如自动曝光/白平衡）
- 参考设备文档调整参数范围

### Q5：无法识别非 ViTai 相机？
- 修改 `device_list.py` 中 `TARGET_VID` 和 `TARGET_PID` 为目标相机的 VID/PID；
- 运行 `v4l2-ctl -d /dev/videoX --list-ctrls` 确认参数支持情况，更新 `camera_params.json` 中的参数范围。
---

## 参数说明
### 参数映射来源
- 基于 V4L2 标准定义
- 通过 `v4l2-ctl --all` 命令获取
- 结合相机驱动文档验证

### 设备差异说明
- 通用参数（亮度/对比度）通常兼容
- 特殊参数（如电源频率）可能不同
- 参数范围可能因设备型号而异
- 建议使用 `v4l2-ctl -d /dev/videoX --list-ctrls` 查询具体参数
- 存在相机分辨率不同的情况，会导致相机画面显示不正常

### 相机分辨率说明
- Vitai (640X480)
- HD WebCam (1920x1080)

### 修改显示分辨率

- 在脚本`hd_webcam_debug.py` 中，修改 HD WebCam 相机分辨率

```bash
# 摄像头控制器
class CameraController: # 摄像头控制器

    def initialize(self):  # 初始化摄像头
        with self.lock:
            self.cap = cv2.VideoCapture(self.index)  # 打开摄像头
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)
            if not self.cap.isOpened():  # 检查是否打开成功
                return False # 打开失败
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            self._init_params()
            return True
```

- 在脚本`v4l2_test_slider.py` 中，统一 Vitai 相机分辨率 

```bash
# 摄像头控制器
class CameraController: # 摄像头控制器

    def run(self):  # 运行摄像头
        while not self.exit_event.is_set():  # 循环读取摄像头
            with self.lock:
                if self.cap.isOpened():  # 检查摄像头是否打开
                    if time.time() - self.last_frame_time < 1 / MAX_FPS:  # 限制帧率
                        time.sleep(0.001)
                        continue
                    ret, frame = self.cap.read() # 读取摄像头
                    self.last_frame_time = time.time()
                    if ret and not frame_queue.full():  # 将帧放入队列
                        frame = cv2.resize(frame, (640, 480))  # 缩放
                        frame_queue.put((self.device_id, frame), block=False)
            time.sleep(0.001)
        with self.lock:
            if self.cap.isOpened():
                self.cap.release()
```

### 修改显示窗口大小

- 在脚本`v4l2_test_slider.py`中，修改显示窗口大小

```bash
def display_frames():
    windows = {}
    while True:
        try:
            device_id, frame = frame_queue.get(timeout=0.1)  # 获取帧
            if device_id not in windows:
                cv2.namedWindow(device_id, cv2.WINDOW_NORMAL)  # 创建窗口
                cv2.resizeWindow(device_id, 640, 480)
            cv2.imshow(device_id, frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        except Empty:
            pass
        except Exception as e:
            print(f"显示异常: {str(e)}")
    cv2.destroyAllWindows()
```

## 扩展与适配（其他品牌相机）

---
1. **设备识别**：在 `device_list.py` 中添加新相机的 VID/PID；
2. **参数映射**：通过 `v4l2-ctl --all` 获取新相机参数，更新 `camera_params.json` 中的参数 ID、范围及类型；
3. **测试验证**：运行 `v4l2_test_scheme.py` 测试参数调节是否生效，调整 `CameraController` 中的分辨率适配逻辑（`cv2.resize` 或 `cap.set`）。
---
**提示**：调试前建议通过 `v4l2-ctl --list-devices` 确认相机已正确识别（设备路径如 `/dev/video0`），并通过 `groups $USER` 检查是否属于 `video` 用户组（无权限需 `sudo usermod -aG video $USER`）