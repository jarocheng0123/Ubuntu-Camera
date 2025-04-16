# Ubuntu 相机调试

## 项目概述
本项目是一个基于 Python 的 Ubuntu 相机调试工具，旨在为用户提供便捷的相机调试解决方案。通过一系列脚本，可实现相机环境的自动配置、相机设备的检测、相机参数的调试以及实时预览等功能。该工具默认适用于 ViTai 品牌 USB 相机，但通过简单修改 VID/PID 可适配其他品牌相机。


## 功能特性
1. **环境自动配置**  
   - 自动设置系统源为阿里云镜像，加快软件包下载速度
   - 安装 Python 虚拟环境及依赖库，包括 OpenCV、PyUSB 等，确保运行环境的一致性
   - 自动创建桌面快捷方式，方便用户快速启动相机调试相关程序

2. **设备检测与信息展示**  
   - 自动发现所有可用相机设备，无需用户手动查找
   - 显示设备详细信息（VID/PID、驱动版本、分辨率等）
   - 支持 USB 设备分类，区分目标设备与非目标设备

3. **参数调试功能**  
   - 单相机参数调节，涵盖亮度、对比度、白平衡等 16 项参数，满足多样化的调试需求
   - 多相机实时预览，可同时观察多个相机的画面
   - 参数配置自动保存与重置，方便用户恢复默认设置或继续之前的调试
   - 支持 V4L2 标准参数控制，确保与大多数相机设备的兼容性。

4. **实时预览**  
   - 支持多窗口同步预览，可同时查看多个相机的实时画面
   - 可自定义分辨率和帧率，根据实际需求调整画面质量
   - 支持快捷键退出（Q 键），方便用户操作


## 安装步骤
### 1. 下载脚本
```bash
将本项目的脚本文件 camera_v4.sh 保存到用户主目录
```

### 2. 赋予执行权限
```bash
chmod +x camera_v4.sh
```

### 3. 运行脚本
```bash
sudo ./camera_v4.sh
```
- 脚本会自动处理以下操作：
  - 创建工作目录 `~/VitaiMMDD`（MMDD 为当前月日）
  - 安装系统依赖和 Python 虚拟环境
  - 生成调试脚本和配置文件
  - 添加 udev 规则确保设备权限


## 使用方法
### 1. 激活虚拟环境
```bash
source ~/VitaiMMDD/Vitai_venv/bin/activate
```

### 2. 查看设备列表
```bash
python ~/VitaiMMDD/camera_device.py
```

### 3. 实时预览
```bash
python ~/VitaiMMDD/camera_preview.py
```

### 4. 单相机调试
```bash
python ~/VitaiMMDD/bug_v4l2.py
```

### 5. 多相机调试
```bash
python ~/VitaiMMDD/v4l2_debug.py
```

### 6. 相机参数定义查看
```bash
python ~/VitaiMMDD/camera_params.py
```

### 7. OpenCV 相机调试
```bash
python ~/VitaiMMDD/bug_opencv.py
```

### 8. V4L2 相机快速设置
```bash
python ~/VitaiMMDD/v4l2_quick.py
```

## 注意事项
1. **权限设置**  
   - 首次使用需添加用户到 video 组：
     ```bash
     sudo usermod -aG video $USER
     ```
   - 需重启系统生效

2. **参数设置限制**  
   - 自动曝光（0x009a0901）与手动曝光存在互斥
   - 白平衡（0x0098091a）需先关闭自动白平衡（0x0098090c）

3. **设备兼容性**  
   - 非 ViTai 相机需修改 VID/PID 识别逻辑（参考 `camera_device.py`）
   - 部分旧型号相机可能存在驱动兼容性问题


## 属性列表
```bash
v4l2-ctl -d /dev/video0 --list-ctrls
```

```
| 中文名称     | 英文参数名                   | 十六进制 ID| 类型     | 最小值 | 最大值  | 步进值 | 默认值  | 当前值 | 选项描述                            |
|-------------|-----------------------------|-----------|----------|--------|--------|--------|--------|--------|------------------------------------
| 亮度         | brightness                 | 0x00980900 | int     | -64    | 64     | 1      | -39    | -64    |
| 对比度       | contrast                   | 0x00980901 | int     | 0      | 100    | 1      | 39     | 39     |
| 色调         | hue                        | 0x00980903 | int     | -180   | 180    | 1      | 0      | 0      |
| 饱和度       | saturation                 | 0x00980902 | int     | 0      | 100    | 1      | 72     | 72     |
| 清晰度       | sharpness                  | 0x0098091b | int     | 0      | 100    | 1      | 75     | 75     |
| 伽马         | gamma                      | 0x00980910 | int     | 100    | 500    | 1      | 300    | 300    |
| 白平衡温度   | white_balance_temperature  | 0x0098091a | int     | 2800   | 6500   | 10     | 6500   | 6000   |
| 自动白平衡   | white_balance_automatic    | 0x0098090c | bool    | -      | -      | -      | 1      | 0      | 0 表示关闭；1 表示开启
| 背光补偿     | backlight_compensation     | 0x0098091c | int     | 0      | 2      | 1      | 0      | 0      |
| 增益         | gain                       | 0x00980913 | int     | 1      | 128    | 1      | 64     | 64     |
| 电源频率     | power_line_frequency       | 0x00980918 | menu    | 0      | 2      | -      | 1      | 1      | 0 表示禁用；1 表示 50Hz；2 表示 60Hz
| 绝对对焦     | focus_absolute             | 0x009a090a | int     | 0      | 1023   | 1      | 68     | 68     |
| 连续自动对焦 | focus_automatic_continuous | 0x009a090c | bool    | -      | -      | -      | 1      | 1      | 0 表示关闭；1 表示开启
| 绝对曝光时间 | exposure_time_absolute     | 0x009a0902 | int     | 0      | 10000  | 1      | 20     | 20     |
| 自动曝光     | auto_exposure              | 0x009a0901 | menu    | 0      | 3      | -      | 3      | 1      | 1 表示手动模式；3 表示光圈优先模式
| 动态帧率曝光 | exposure_dynamic_framerate | 0x009a0903 | bool    | -      | -      | -      | 0      | 1      | 0 表示关闭；1 表示开启
```
## 项目结构
```
VitaiMMDD/
├── Vitai_venv/            # Python 虚拟环境
├── camera_device.py       # 相机设备检测，检测系统中所有可用摄像头，获取设备索引、节点路径及 USB 设备详细信息
├── camera_preview.py      # 相机预览和信息，实时预览摄像头画面，显示驱动信息和参数表格
├── camera_params.py       # 相机参数定义，定义相机支持的参数列表，展示参数详情
├── bug_opencv.py          # OpenCV 相机调试，借助 Tkinter 界面调节摄像头参数，支持保存与重置，可实时预览
├── v4l2_quick.py          # V4L2 相机快速设置，利用 V4L2 命令批量设置摄像头参数，提供多种模式
├── bug_v4l2.py            # V4L2 单摄像头控制器，针对单摄像头的图形化调试工具，支持参数重置和实时显示
├── v4l2_debug.py          # V4L2 多摄像头调试，可同时调试多个摄像头，采用多线程处理
└── scheme_test.py         #V4L2 多摄像头多方案测试，提供多种预设参数方案，通过图形界面切换方案或手动调整参数，实时预览画面并反馈设置结果
```


## 常见问题解答
### Q1: 脚本运行失败怎么办？
- 检查执行权限：`ls -l camera_v4.sh` 确保有 `x` 权限
- 确认网络连接：脚本依赖阿里云镜像源
- 手动安装依赖：尝试运行 `sudo apt update && sudo apt upgrade`

### Q2: 相机无法打开？
- 检查物理连接
- 运行 `v4l2-ctl --list-devices` 确认设备存在
- 检查用户权限：`groups $USER | grep video`

### Q3: 参数设置无效？
- 部分参数需重启设备生效
- 检查自动参数状态（如自动曝光/白平衡）
- 参考设备文档调整参数范围

### Q4: 如何适配其他品牌相机？
1. 修改 `camera_device.py` 中的 VID/PID 识别逻辑
2. 更新 `v4l2-ctl` 参数映射表
3. 调整 `camera_params.py` 中的参数范围


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