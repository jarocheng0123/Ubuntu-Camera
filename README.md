# Ubuntu 相机调试

## 项目概述
本项目是一个基于 Python 的 Ubuntu 相机调试工具，旨在为用户提供便捷的相机调试解决方案。通过一系列脚本，可实现相机环境的自动配置、相机设备的检测、相机参数的调试以及实时预览等功能。该工具默认适用于 ViTai 品牌 USB 相机，但通过简单修改 VID/PID 可适配其他品牌相机。


## 功能特性
1. **环境自动配置**  
   - 自动设置系统源为阿里云镜像
   - 安装 Python 虚拟环境及依赖库（OpenCV、PyUSB 等）
   - 自动创建桌面快捷方式

2. **设备检测与信息展示**  
   - 自动发现所有可用相机设备
   - 显示设备详细信息（VID/PID、驱动版本、分辨率等）
   - 支持 USB 设备分类（目标设备与非目标设备）

3. **参数调试功能**  
   - 单相机参数调节（亮度/对比度/白平衡等 16 项参数）
   - 多相机实时预览（实验性功能）
   - 参数配置自动保存与重置
   - 支持 V4L2 标准参数控制

4. **实时预览**  
   - 支持多窗口同步预览
   - 可自定义分辨率和帧率
   - 支持快捷键退出（Q 键）


## 安装步骤
### 1. 下载脚本
```bash
将本项目的脚本文件camera.sh保存到用户主目录
```

### 2. 赋予执行权限
```bash
chmod +x camera.sh
```

### 3. 运行脚本
```bash
sudo ./camera.sh
```
- 脚本会自动处理以下操作：
  - 创建工作目录 `~/vitai`
  - 安装系统依赖和 Python 虚拟环境
  - 生成调试脚本和配置文件
  - 添加 udev 规则确保设备权限


## 使用方法
### 1. 激活虚拟环境
```bash
source ~/vitai/vitai_venv/bin/activate
```

### 2. 查看设备列表
```bash
python ~/vitai/camera_list.py
```

### 3. 实时预览
```bash
python ~/vitai/camera_open.py
```

### 4. 单相机调试
```bash
python ~/vitai/camera_vitai.py
```

### 5. 多相机调试（实验）
```bash
python ~/vitai/camera_vitai_double.py
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
   - 多相机参数同步功能尚未实现

3. **设备兼容性**  
   - 非 ViTai 相机需修改 VID/PID 识别逻辑（参考 `camera_list.py`）
   - 部分旧型号相机可能存在驱动兼容性问题


## 项目结构
```
vitai/
├── camera_list.py       # 设备扫描与信息展示
├── camera_open.py       # 实时画面预览
├── camera_vitai.py      # 单相机参数调试（GUI）
├── camera_vitai_double.py # 多相机调试（实验）
├── vitai_venv/          # Python 虚拟环境
└── camera_params.json   # 参数配置文件
```


## 常见问题解答
### Q1: 脚本运行失败怎么办？
- 检查执行权限：`ls -l camera.sh` 确保有 `x` 权限
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
1. 修改 `camera_list.py` 中的 VID/PID 识别逻辑
2. 更新 `v4l2-ctl` 参数映射表
3. 调整 `camera_vitai.py` 中的参数范围


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
