#!/bin/bash
set -o nounset

#===============================================================================================================================================================

# 系统信息
OS_VERSION=$(lsb_release -ir 2>/dev/null) # 系统版本
OS_CODENAME=$(lsb_release -c) # 系统代号
OS_ARCH=$(uname -m) # 系统架构

# 用户信息
CURRENT_DATE=$(date +%m%d) # 当前日期【硬编码路径】
CURRENT_USER=$(logname) # 当前用户

# 用户目录
USER_HOME=$(getent passwd "$CURRENT_USER" | awk -F: '{print $6}')
USER_DESKTOP="${USER_HOME}/桌面"  #【硬编码路径】
USER_DOWNLOAD="${USER_HOME}/下载" #【硬编码路径】

#====================================================================================*===========================================================================
# 配置文件夹
CAMERA_NAME="Vitai" # 相机名称 【硬编码路径】
WORK_DIR="${USER_HOME}/${CAMERA_NAME}${CURRENT_DATE}" # 工作目录带日期
UDEV_RULE_FILE="/etc/udev/rules.d/99-${CAMERA_NAME}-camera.rules" # udev规则文件
GITHUB_SDK="https://github.com/ViTai-Tech/ViTai-SDK-Release/tree/main/wheel"  # SDK下载地址

#===============================================================================================================================================================
PYTHON_VERSIONS=("3.9" "3.12")  # 自编程环境3.9 厂商SDK3.12

# 激活虚拟环境
SOURCE_VENV39="${WORK_DIR}/venv39/bin/activate"   # 脚本激活虚拟环境路径【硬编码路径】
SOURCE_VENV312="${WORK_DIR}/venv312/bin/activate" # 脚本激活虚拟环境路径【硬编码路径】

MIRROR_URL="https://pypi.tuna.tsinghua.edu.cn/simple"  # 镜像地址

# python 3.9 配置的依赖包
declare -A VERSIONS=(
    [NUM_PY]="1.24.4"
    [OPENCV]="4.10.0.84"
    [PYUSB]="1.2.1"
    [PSUTIL]="5.9.5"
    [PRETTYTABLE]="3.16.0"
)

#===============================================================================================================================================================

# 设备序列号相关
DEVICE_SN="device_sn.py" # 设备序列号 【硬编码路径】
DEVICE_LIST="device_list.py" # 设备列表
DEVICE_SN_LIST="device_sn_list.py" # 带序列号的设备列表 【硬编码路径】

# 相机功能相关
CAMERA_PREVIEW="camera_preview.py" # 相机画面预览
CAMERA_PARAMETER="camera_parameter.py" # 相机参数信息

# 调试工具相关
OPENCV_DEBUG="opencv_debug.py" # OpenCV 调试工具
V4L2_DEBUG="v4l2_debug.py" # V4L2 单摄像头通过滑块调节
V4L2_QUICK="v4l2_quick.py" # V4L2 通过预定方案快速设置

# 多参数方案相关
V4L2_TEST_SLIDER="v4l2_test_slider.py" # V4L2 多摄像头画面调试工具，针对成品系列 白色9*9
V4L2_TEST_SCHEME="v4l2_test_scheme.py" # V4L2 多摄像头画面调试工具，针对测试系列 灰色9*9 纯白 纯灰
HD_WEBCAM_DEBUG="hd_webcam_debug.py" # HD WebCam 调试

# 脚本路径定义 【硬编码路径】
PATH_DEVICE_SN="${WORK_DIR}/venv312/${DEVICE_SN}" # 厂商SDK基于Python 3.12
PATH_DEVICE_LIST="${WORK_DIR}/venv39/${DEVICE_LIST}"
PATH_DEVICE_SN_LIST="${WORK_DIR}/venv39/${DEVICE_SN_LIST}"
PATH_CAMERA_PREVIEW="${WORK_DIR}/venv39/${CAMERA_PREVIEW}"
PATH_CAMERA_PARAMETER="${WORK_DIR}/venv39/${CAMERA_PARAMETER}"
PATH_OPENCV_DEBUG="${WORK_DIR}/venv39/${OPENCV_DEBUG}"
PATH_V4L2_DEBUG="${WORK_DIR}/venv39/${V4L2_DEBUG}"
PATH_V4L2_QUICK="${WORK_DIR}/venv39/${V4L2_QUICK}"
PATH_V4L2_TEST_SLIDER="${WORK_DIR}/venv39/${V4L2_TEST_SLIDER}"
PATH_V4L2_TEST_SCHEME="${WORK_DIR}/venv39/${V4L2_TEST_SCHEME}"
PATH_HD_WEBCAM_DEBUG="${WORK_DIR}/venv39/${HD_WEBCAM_DEBUG}"

# 脚本桌面快捷方式
DESKTOP_DEVICE_SN_PREVIEW="${USER_DESKTOP}/${CAMERA_NAME}序列号画面预览.desktop"
DESKTOP_V4L2_QUICK="${USER_DESKTOP}/${CAMERA_NAME}成品内参快速设置.desktop"
DESKTOP_V4L2_TEST_SLIDER="${USER_DESKTOP}/${CAMERA_NAME}成品系列调试.desktop"
DESKTOP_V4L2_TEST_SCHEME="${USER_DESKTOP}/${CAMERA_NAME}测试系列调试.desktop"
DESKTOP_HD_WEBCAM_DEBUG="${USER_DESKTOP}/HD WebCam 相机调试.desktop"

# 桌面快捷方式调用脚本
desktop_info=(
    "${DESKTOP_DEVICE_SN_PREVIEW}:source ${SOURCE_VENV39} && python ${PATH_DEVICE_SN_LIST} && python ${PATH_CAMERA_PREVIEW}"    
    "${DESKTOP_V4L2_QUICK}:source ${SOURCE_VENV39} && python ${PATH_V4L2_QUICK}"
    "${DESKTOP_V4L2_TEST_SLIDER}:source ${SOURCE_VENV39} && python ${PATH_V4L2_TEST_SLIDER}"
    "${DESKTOP_V4L2_TEST_SCHEME}:source ${SOURCE_VENV39} && python ${PATH_V4L2_TEST_SCHEME}"
    "${DESKTOP_HD_WEBCAM_DEBUG}:source ${SOURCE_VENV39} && python ${PATH_HD_WEBCAM_DEBUG}"
)

#===============================================================================================================================================================
COLOR_RESET="\033[0m"    # 重置
COLOR_RED="\033[31m"     # 红色
COLOR_ERROR="\033[31m"   # 错误
COLOR_GREEN="\033[32m"   # 绿色
COLOR_PY="\033[1;32m"    # 标题
COLOR_SUCCESS="\033[32m" # 成功
COLOR_YELLOW="\033[33m"  # 黄色
COLOR_WARNING="\033[33m" # 警告
COLOR_BLUE="\033[34m"    # 蓝色
COLOR_PURPLE="\033[35m"  # 紫色
COLOR_CYAN="\033[36m"    # 青色
COLOR_INFO="\033[36m"    # 信息


# 紫色分隔线
print_separator() {
    local color=${1:-$COLOR_PURPLE} # 颜色（可选）
    local separator=$(printf "%$(tput cols)s" | tr ' ' '=')  
    echo -e "${color}${separator}${COLOR_RESET}"
    echo  # 输出空行
}

# 青色输出
print_info() {
    local description=$1   # 描述文本
    printf "  ${COLOR_INFO}%-30s${COLOR_RESET}" "${description}"
    echo  # 输出空行
}

#===============================================================================================================================================================
# 解析 GitHub（组织名、仓库名、分支、路径）
if [[ $GITHUB_SDK =~ ^https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.*)$ ]]; then
    GITHUB_OWNER=${BASH_REMATCH[1]}  # 组织名
    GITHUB_REPO=${BASH_REMATCH[2]}   # 仓库名
    GITHUB_BRANCH=${BASH_REMATCH[3]} # 分支
    GITHUB_PATH=${BASH_REMATCH[4]}   # 路径
fi

# RAW和API链接
GITHUB_RAW_BASE="https://raw.githubusercontent.com/${GITHUB_OWNER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${GITHUB_PATH}"
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/contents/${GITHUB_PATH}"

#===============================================================================================================================================================

# 包检查函数
check_package() {
    local package=$1
    local check_type=${2:-dpkg}  # 默认检查系统包，可选 'python'

    case $check_type in
        dpkg)
            local status_output=$(dpkg -s "$package" 2>/dev/null)
            local is_installed=$(echo "$status_output" | grep -q "Status: install ok installed")
            local version=$(echo "$status_output" | awk '/Version:/ {print $2}')

            if $is_installed; then
                echo -e "  ${COLOR_GREEN}✓ $package：已安装，版本 $version${COLOR_RESET}"
            else
                echo -e "  ${COLOR_RED}✗ $package：未安装${COLOR_RESET}"
            fi
            ;;

        python)
            local version=$(python -c "import $package; print($package.__version__)" 2>/dev/null)
            if [ -n "$version" ]; then
                echo -e "  ${COLOR_GREEN}✓ $package：已安装，版本 $version${COLOR_RESET}"
            else
                echo -e "  ${COLOR_RED}✗ $package：未安装或版本不匹配${COLOR_RESET}"
            fi
            ;;

        *)
            echo -e "${COLOR_RED}错误：不支持的检查类型 $check_type${COLOR_RESET}"
            ;;
    esac
}

#===============================================================================================================================================================
# 脚本执行声明

echo # 输出空行
echo -e "${COLOR_YELLOW}使用sudo权限运行脚本${COLOR_RESET}"
echo -e "${COLOR_RED}脚本会删除并重建 ${WORK_DIR} 文件夹，并安装Python ${PYTHON_VERSIONS[*]}${COLOR_RESET}"
echo -e "${COLOR_YELLOW}相机SDK仓库 ${GITHUB_SDK} ${COLOR_RESET}"
echo -e "${COLOR_RED}在Python脚本中路径${WORK_DIR}采用硬编码，请及时修改${COLOR_RESET}"

print_separator # 输出分隔线

# 检测系统信息
print_info "检测到系统信息"
echo -e "${COLOR_YELLOW}"
echo "$OS_VERSION" # 输出系统版本
echo "$OS_ARCH" # 输出系统架构
echo -e "${COLOR_RESET}"

# 检查桌面路径
if [ -d "$USER_DESKTOP" ]; then
    echo -e "${COLOR_GREEN}桌面路径有效 ${USER_DESKTOP} ${COLOR_RESET}"
else
    echo -e "${COLOR_RED}桌面路径无效 ${USER_DESKTOP} ，请检查变量 USER_DESKTOP 定义${COLOR_RESET}"
fi

# 检查下载路径
if [ -d "$USER_DOWNLOAD" ]; then
    echo -e "${COLOR_GREEN}下载路径有效 ${USER_DOWNLOAD} ${COLOR_RESET}"
else
    echo -e "${COLOR_RED}下载路径无效 ${USER_DOWNLOAD} ，请检查变量 USER_DOWNLOAD 定义\${COLOR_RESET}"
fi

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "当前系统Python环境检测"

for ver in $(compgen -c | grep -E '^python[0-9]+\.[0-9]+$' | sort -u); do
    if which "$ver" &> /dev/null; then
        echo -e "  ${COLOR_SUCCESS}$ver${COLOR_RESET}: $(which "$ver")"
    fi
done

#===============================================================================================================================================================
print_separator # 输出分隔线

# 询问是否继续
while true; do
    read -p $'\033[33m是否要继续执行脚本？(Y/y/N/n): \033[0m' answer

    case $answer in
        [Yy]*)
            echo -e "${COLOR_YELLOW}即将继续执行脚本${COLOR_RESET}"
            break
            ;;
        [Nn]*)
            echo -e "${COLOR_YELLOW}已取消脚本执行${COLOR_RESET}"
            exit 0
            ;;
        *)
            echo -e "${COLOR_RED}输入无效，请输入 Y/y 或 N/n ${COLOR_RESET}"
            ;;
    esac
done

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "检测工作目录"

if [ -d "$WORK_DIR" ]; then
    echo -e "${COLOR_RED}警告：检测到已有工作目录 $WORK_DIR${COLOR_RESET}"
    ls -l "$WORK_DIR"

    while true; do
        read -p $'\033[33m是否要清空并重建文件夹？(Y/y-清空重建, N/n-取消并退出, Q/q-跳过清空继续): \033[0m' answer
        case $answer in
            [Yy]*)
                print_info "修复文件权限"
                chown -R "$CURRENT_USER:$CURRENT_USER" "$WORK_DIR"
                find "$WORK_DIR" -type f -exec chmod 644 {} \;
                find "$WORK_DIR" -type d -exec chmod 755 {} \;
                echo -e "${COLOR_YELLOW}即将清空并重建文件夹...${COLOR_RESET}"
                rm -rf "$WORK_DIR"
                if ! mkdir -p "$WORK_DIR"; then
                    echo -e "${COLOR_RED}创建文件夹时出错，请检查权限。${COLOR_RESET}"
                    exit 1
                fi
                break
                ;;
            [Nn]*)
                echo -e "${COLOR_YELLOW}已取消对文件夹的操作。${COLOR_RESET}"
                exit 0
                ;;
            [Qq]*)
                echo -e "${COLOR_GREEN}已跳过清空操作，保留现有文件夹内容。${COLOR_RESET}"
                break
                ;;
            *)
                echo -e "${COLOR_RED}输入无效，请输入 Y/y（清空重建）、N/n（取消退出）或 Q/q（跳过继续）。${COLOR_RESET}"
                ;;    
        esac
    done
else
    echo -e "${COLOR_GREEN} ${WORK_DIR} 文件夹不存在，开始创建...${COLOR_RESET}"
    if ! mkdir -p "$WORK_DIR"; then
        echo -e "${COLOR_RED}创建文件夹时出错，请检查权限。${COLOR_RESET}"
        exit 1
    fi
fi

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "设置系统源为阿里云镜像"

# 备份原有源文件
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak

# 设置阿里云镜像源
ALIYUN_MIRROR_CONTENT=$(cat <<EOF
deb http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME} main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME} main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ ${OS_CODENAME}-backports main restricted universe multiverse
EOF
)

# 写入新的源文件内容
echo "$ALIYUN_MIRROR_CONTENT" | sudo tee /etc/apt/sources.list > /dev/null
print_info "更新软件源信息"
sudo apt update

#===============================================================================================================================================================
print_separator # 输出分隔线
echo -e "${COLOR_YELLOW}安装 curl 和 jq${COLOR_RESET}"
echo # 输出空行

sudo apt install -y curl jq  # 同时安装 curl 和 jq

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "正在查询仓库中的SDK文件"

# 尝试通过网络获取SDK文件名
get_sdk_filename_via_network() {
    local pattern=$1  # 架构匹配的文件名模式
    local -n sdk_name=$2  # SDK文件名引用

    local files=$(curl -sSL "$GITHUB_API_URL") # 获取仓库中的SDK文件列表
    if [ $? -ne 0 ]; then  # 网络连接失败
        echo -e "${COLOR_YELLOW}警告：网络连接失败，无法查询GitHub仓库文件列表${COLOR_RESET}"
        return 1  # 返回失败状态
    fi

    # 匹配文件名
    sdk_name=$(echo "$files" | jq -r --arg pattern "$pattern" '.[] | .name | select(test($pattern))' | head -n 1)
    if [ -z "$sdk_name" ]; then
        echo -e "${COLOR_YELLOW}警告：网络查询未找到匹配 ${OS_ARCH} 架构的SDK文件${COLOR_RESET}"
        return 1  # 返回失败状态
    fi
    return 0  # 成功
}

# 根据架构定义匹配.whl文件名
case $OS_ARCH in
    "x86_64")
        WHL_PATTERN="pyvitaisdk-.*-linux_x86_64\.whl"
        ;;
    "aarch64"|"arm64")
        WHL_PATTERN="pyvitaisdk-.*-linux_aarch64\.whl"
        ;;
    *)
        echo "错误：不支持的架构 $OS_ARCH"
        exit 1
        ;;
esac

SDK_WHL_FILENAME=""  # 初始化空值

# 尝试通过网络获取SDK文件名
if ! get_sdk_filename_via_network "$WHL_PATTERN" SDK_WHL_FILENAME; then
    # 网络失败或未找到时，直接本地搜索匹配架构的文件
    echo -e "${COLOR_YELLOW}正在本地下载目录 ${USER_DOWNLOAD} 中搜索匹配 ${WHL_PATTERN} 的文件...${COLOR_RESET}"
    IFS=$'\n'
    LOCAL_CANDIDATES=($(find "$USER_DOWNLOAD" -maxdepth 1 -name "$WHL_PATTERN" -type f | xargs -n1 basename)) # 以文件名为数组元素
    unset IFS

    if [ ${#LOCAL_CANDIDATES[@]} -eq 0 ]; then
        echo -e "${COLOR_RED}错误：网络未找到文件，且本地目录 ${USER_DOWNLOAD} 中未找到匹配 ${WHL_PATTERN} 的文件${COLOR_RESET}"
        print_info "请手动下载SDK文件到：${USER_DOWNLOAD}"
        exit 1
    else
        SDK_WHL_FILENAME=${LOCAL_CANDIDATES[0]}
        echo -e "${COLOR_GREEN}本地找到匹配文件：${SDK_WHL_FILENAME}${COLOR_RESET}"
    fi
fi

print_info "仓库地址：${GITHUB_SDK}"
print_info "下载链接：${GITHUB_RAW_BASE}/${SDK_WHL_FILENAME}"
echo -e "\033[1m${COLOR_YELLOW}  匹配的SDK文件：${SDK_WHL_FILENAME}${COLOR_RESET}"
print_info "请确认文件已保存到: ${USER_DOWNLOAD} 文件夹"

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "添加PPA源(支持旧版Python)"

if ! sudo add-apt-repository -y ppa:deadsnakes/ppa; then
    echo -e "${COLOR_ERROR}错误：PPA源添加失败，请手动执行：${COLOR_RESET}"
    echo "  sudo add-apt-repository ppa:deadsnakes/ppa"
    exit 1
fi
sudo apt update -y >/dev/null
echo -e "${COLOR_SUCCESS}PPA源添加并更新完成${COLOR_RESET}"

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "安装系统级依赖"

# 系统级依赖包列表
SYSTEM_PACKAGES=(
    libv4l-dev v4l-utils libusb-1.0-0-dev \
    python3-opencv libatlas3-base \
    libopenjp2-7 \
    qtbase5-dev libqt5x11extras5-dev \
    cython3 ffmpeg libcap-dev git g++ make build-essential libcamera-dev
)

# 安装系统级依赖
if ! apt install -y --no-install-recommends "${SYSTEM_PACKAGES[@]}"; then
    echo -e "\n${COLOR_RED}安装系统级依赖失败，脚本退出${COLOR_RESET}"
    exit 1
fi

print_separator # 输出分隔线
print_info "系统级依赖安装检测"

# 循环系统包列表
for pkg in "${SYSTEM_PACKAGES[@]}"; do
    check_package "$pkg" dpkg
done

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "即将安装的Python系统包列表"

declare -a PYTHON_PACKAGES=()
for ver in "${PYTHON_VERSIONS[@]}"; do
    PYTHON_PACKAGES+=("python$ver" "python$ver-dev" "python$ver-venv" "python$ver-tk")
done

# 打印待安装的Python系统包列表
printf "  ${COLOR_YELLOW}%s${COLOR_RESET}\n" "${PYTHON_PACKAGES[@]}"

if ! sudo apt install -y "${PYTHON_PACKAGES[@]}"; then
    echo -e "\n${COLOR_ERROR}错误：部分系统包安装失败，具体状态如下：${COLOR_RESET}"
else
    echo -e "\n${COLOR_SUCCESS}系统包安装完成，最终状态如下：${COLOR_RESET}"
fi

for pkg in "${PYTHON_PACKAGES[@]}"; do
    check_package "$pkg" dpkg
done

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "创建并验证虚拟环境"

create_and_display_venv() {
    local py_ver=$1
    local venv_name="venv${py_ver//.}"
    local venv_path="${WORK_DIR}/${venv_name}"

    # 前置检查
    if ! command -v "python$py_ver" &> /dev/null; then
        echo -e "${COLOR_ERROR}× Python $py_ver 解释器未找到，跳过创建${COLOR_RESET}"
        return
    fi
    if ! dpkg -s "python$py_ver-venv" &> /dev/null; then
        echo -e "${COLOR_ERROR}× python$py_ver-venv 包未安装，跳过创建${COLOR_RESET}"
        return
    fi

    # 创建虚拟环境
    echo -e "${COLOR_INFO}正在为Python $py_ver 创建虚拟环境...${COLOR_RESET}"
    if python"$py_ver" -m venv "$venv_path"; then
        echo -e "${COLOR_SUCCESS}创建成功: $venv_path${COLOR_RESET}"
        echo -e "终端激活: ${COLOR_WARNING}source ${venv_path}/bin/activate${COLOR_RESET}\n"
    else
        echo -e "${COLOR_ERROR}× 虚拟环境创建失败${COLOR_RESET}\n"
        return
    fi
}

# 逐个创建并显示虚拟环境信息
for ver in "${PYTHON_VERSIONS[@]}"; do
    create_and_display_venv "$ver"
done

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "激活 $SOURCE_VENV39 虚拟环境并安装Python依赖"

if ! source "$SOURCE_VENV39"; then
    echo -e "${COLOR_RED}错误：虚拟环境激活失败，请检查路径${COLOR_RESET}"
    exit 1
fi

print_info "设置pip镜像源"
pip config set global.index-url "$MIRROR_URL"

print_separator # 输出分隔线
print_info "安装虚拟环境依赖"

pip install --upgrade pip setuptools wheel PyQt5

for _ in {1..3}; do
    if pip install --no-cache-dir --force-reinstall --timeout=600 --retries=5 \
        "numpy==${VERSIONS[NUM_PY]}" \
        "pyusb==${VERSIONS[PYUSB]}" \
        "psutil==${VERSIONS[PSUTIL]}" \
        "opencv-python==${VERSIONS[OPENCV]}" \
        "prettytable==${VERSIONS[PRETTYTABLE]}"; then
        break
    fi
done

print_separator # 输出分隔线
print_info "虚拟环境依赖安装检测"

# Python包列表
PYTHON_DEPENDENCIES=("cv2" "usb" "numpy" "psutil")

# 检查所有Python包
for pkg in "${PYTHON_DEPENDENCIES[@]}"; do
    check_package "$pkg" python
done

#===============================================================================================================================================================
print_separator # 输出分隔线

# 查找下载目录中的目标文件 
print_info "查找 $SDK_WHL_FILENAME "

IFS=$'\n'  # 设置内部字段分隔符为换行符
FOUND_FILES=($(find "$USER_DOWNLOAD" -maxdepth 1 -name "$SDK_WHL_FILENAME" -type f))
unset IFS  # 恢复默认的内部字段分隔符

# 检查是否找到文件
if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo -e "${COLOR_RED}错误：在下载目录 ${USER_DOWNLOAD} 中未找到匹配 ${SDK_WHL_FILENAME} 的文件${COLOR_RESET}"
    exit 1  # 错误退出，使用非零状态码
fi

echo -e "${COLOR_GREEN}找到 ${#FOUND_FILES[@]} 个 ${SDK_WHL_FILENAME} 文件，正在复制到 ${WORK_DIR}...${COLOR_RESET}"

move_failed=0  # 标记复制失败状态
for file in "${FOUND_FILES[@]}"; do
    if [ -f "$file" ]; then  # 防止文件被提前删除
        cp -v "$file" "$WORK_DIR/" || move_failed=1  # 复制失败时标记错误
    else
        echo -e "${COLOR_YELLOW}警告：文件已被移除，跳过复制：${file}${COLOR_RESET}"
        move_failed=1
    fi
done

# 检查复制是否失败
if [ $move_failed -eq 1 ]; then
    echo -e "${COLOR_RED}错误：部分文件复制失败，请检查权限或路径${COLOR_RESET}"
    exit 1
fi

# 验证复制结果（精简版）
echo -e "\n${COLOR_YELLOW}验证$SDK_WHL_FILENAME复制结果...${COLOR_RESET}"
ls -l "$WORK_DIR" | grep "$SDK_WHL_FILENAME" || {
    echo -e "${COLOR_RED}错误：目标目录未找到 ${SDK_WHL_FILENAME} 文件${COLOR_RESET}"
    exit 1
}

# 最终成功提示
echo -e "${COLOR_GREEN}√ 所有 ${SDK_WHL_FILENAME} 文件已成功复制到 ${WORK_DIR}${COLOR_RESET}"

#===============================================================================================================================================================
print_separator # 输出分隔线

print_info "激活 $SOURCE_VENV312 虚拟环境并安装Python依赖"

if ! source "$SOURCE_VENV312"; then
    echo -e "${COLOR_RED}错误：虚拟环境激活失败，请检查路径${COLOR_RESET}"
    exit 1
fi

echo -e "${COLOR_YELLOW}正在安装SDK文件：${SDK_WHL_FILENAME}${COLOR_RESET}"
pip install "${WORK_DIR}/$SDK_WHL_FILENAME"

print_info "升级setuptools"
pip install --upgrade setuptools

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "创建python脚本"
echo # 输出空行
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${DEVICE_SN} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 程序是通过调用厂商的SDK文件获取设备SN码 ${COLOR_RESET}" # 程序声明
echo -e "${COLOR_WARNING} 在程序中使用硬编码路径读取，在实际使用时需要检查路径问题 ${COLOR_RESET}" # 警告声明
echo -e "/home/ur/Vitai0506/vevn312/lib/python3.12/site-packages" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_DEVICE_SN}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【程序是通过调用厂商的SDK文件获取设备SN码】\033[0m")
print("\033[91m【在程序中使用硬编码路径读取，在实际使用时需要检查路径问题】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
venv_site_packages = '/home/ur/Vitai0506/vevn312/lib/python3.12/site-packages'
# 调用路径，本程序运行环境是由厂商SDK决定，在使用时，需要手动修改路径

import sys
sys.path.insert(0, venv_site_packages)

from pyvitaisdk import VTSDeviceFinder

if __name__ == "__main__":
    try:
        finder = VTSDeviceFinder()
        sns = finder.get_sns()
        for sn in sns:
            print(sn)
    except Exception as e:
        print(f"发生错误: {e}")
# ----------------------------------------------------------------------------------------------------------------------
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${DEVICE_LIST} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 检测系统中所有可用摄像头，获取设备索引、节点路径及 USB 设备详细信息 ${COLOR_RESET}" # 程序声明
echo -e "${COLOR_WARNING} 目标设备：ViTai F225-0001 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_DEVICE_LIST}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【检测系统中所有可用摄像头，获取设备索引、节点路径及 USB 设备详细信息】\033[0m")
print("\033[31m\033[1m【目标设备：ViTai F225-0001】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
import cv2  # OpenCV
import subprocess  # 执行系统命令

# 目标设备关键词
TARGET_DEVICE_NAME = "ViTai"
# 目标 VID - PID 组合
TARGET_VID_PID_COMBINATIONS = ["F225-0001"]

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
# ----------------------------------------------------------------------------------------------------------------------
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${DEVICE_SN_LIST} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 在程序${DEVICE_LIST}的基础上，补充了SN码 ${COLOR_RESET}" # 程序声明
echo -e "${COLOR_WARNING} 由于添加了SN码的读取，所以在使用的时候，注意硬编码路径问题 ${COLOR_RESET}" # 警告声明
echo -e "/home/ur/Vitai0506/venv312/bin/python" # 警告声明
echo -e "/home/ur/Vitai0506/venv312/device_sn.py" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_DEVICE_SN_LIST}" # 程序路径
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
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${CAMERA_PREVIEW} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 实时预览摄像头画面，显示驱动信息和参数表格 ${COLOR_RESET}" # 程序声明
# echo -e "${COLOR_WARNING} 警告声明 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_CAMERA_PREVIEW}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【相机预览与参数查看程序：实时预览摄像头画面，显示驱动信息和参数表格】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
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
# ----------------------------------------------------------------------------------------------------------------------
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${CAMERA_PARAMETER} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 相机参数定义与示例程序：定义相机支持的参数列表，展示参数详情 ${COLOR_RESET}" # 程序声明
# echo -e "${COLOR_WARNING} 警告声明 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_CAMERA_PARAMETER}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【相机参数定义与示例程序：定义相机支持的参数列表，展示参数详情】\033[0m\n")
# ----------------------------------------------------------------------------------------------------------------------
from prettytable import PrettyTable

def print_formatted_result(): # 打印表格
    table_data = [
        ("亮度", "brightness", "0x00980900", "int", -64, 64, 1, -39, -39, "", -64),
        ("对比度", "contrast", "0x00980901", "int", 0, 100, 1, 39, 39, "", 39),
        ("饱和度", "saturation", "0x00980902", "int", 0, 100, 1, 72, 72, "", 72),
        ("色调", "hue", "0x00980903", "int", -180, 180, 1, 0, 0, "", 0),
        ("自动白平衡", "white_balance_automatic", "0x0098090c", "bool", None, None, None, 1, 0, "0 表示关闭；1 表示开启", 0),
        ("伽马值", "gamma", "0x00980910", "int", 100, 500, 1, 300, 300, "", 300),
        ("增益", "gain", "0x00980913", "int", 1, 128, 1, 64, 64, "", 64),
        ("电源频率", "power_line_frequency", "0x00980918", "menu", 0, 2, None, 1, 1, "0 表示禁用；1 表示 50Hz；2 表示 60Hz", 1),
        ("白平衡温度", "white_balance_temperature", "0x0098091a", "int", 2800, 6500, 10, 6500, 6500, "", 6000),
        ("清晰度", "sharpness", "0x0098091b", "int", 0, 100, 1, 75, 75, "", 75),
        ("背光补偿", "backlight_compensation", "0x0098091c", "int", 0, 2, 1, 0, 0, "", 0),
        ("自动曝光", "auto_exposure", "0x009a0901", "menu", 0, 3, None, 3, 1, "1 表示手动模式；3 表示光圈优先模式", 1),
        ("绝对曝光时间", "exposure_time_absolute", "0x009a0902", "int", 0, 10000, 1, 20, 20, "", 20),
        ("动态帧率曝光", "exposure_dynamic_framerate", "0x009a0903", "bool", None, None, None, 0, 0, "0 表示关闭；1 表示开启", 1),
        ("绝对对焦", "focus_absolute", "0x009a090a", "int", 0, 1023, 1, 68, 68, "", 68),
        ("连续自动对焦", "focus_automatic_continuous", "0x009a090c", "bool", None, None, None, 1, 1, "0 表示关闭；1 表示开启", 1)
    ]

    # 打印表格
    table = PrettyTable()
    table.field_names = ["变量名", "名称", "十六进制", "数据类型", "最小值", "最大值", "步长", "默认值", "厂商值", "选项", "用户值"]
    for item in table_data: # 遍历表格数据
        chinese_name, v4l2_param, hex_numbers_str, data_type, min_val, max_val, step, default_val, current_val, options, set_val = item
        table.add_row([chinese_name, v4l2_param, hex_numbers_str, data_type, min_val, max_val, step, default_val, current_val, options, set_val])
    print(table)

    print("=" * 50)
    green_start = "\033[92m"
    green_end = "\033[0m"
    print(f"{green_start}BASE_CAMERA_PARAMS = [{green_end}")
    for index, item in enumerate(table_data):
        chinese_name, v4l2_param, hex_numbers_str, data_type, min_val, max_val, step, default_val, current_val, options, set_val = item
        output = f"""    {{
        "chinese_name": "{chinese_name}",
        "v4l2_param": "{v4l2_param}",
        "hex_numbers": "{hex_numbers_str}",
        "type": "{data_type}",
        "min": {min_val},
        "max": {max_val},
        "step": {step},
        "default": {default_val},
        "value": {current_val},
        "options": "{options}",
        "setvalue": {set_val}
    }}"""
        if index < len(table_data) - 1:
            output += ","
        print(f"{green_start}{output}{green_end}")
    print(f"{green_start}]{green_end}")
    print("=" * 50)

remark = """
本代码会自动生成调试函数，方便在其他函数调用
"""

if __name__ == "__main__":
    print_formatted_result() # 打印表格
    print(f"\n\033[93m{remark}\033[0m\n")  # 打印备注信息
# ----------------------------------------------------------------------------------------------------------------------
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${OPENCV_DEBUG} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 借助OpenCV调节摄像头参数，支持保存与重置，可实时预览 ${COLOR_RESET}" # 程序声明
echo -e "${COLOR_WARNING} 在采用OpenCV调试的过程中，存在部分参数无法设置，已放弃 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_OPENCV_DEBUG}" # 程序路径
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
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${V4L2_DEBUG} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 单相机控制调试工具：针对单摄像头的图形化调试工具，支持参数重置和实时显示 ${COLOR_RESET}" # 程序声明
echo -e "${COLOR_WARNING} 程序目前只支持单个相机调试，多相机调试参看 ${V4L2_TEST_SLIDER} ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_V4L2_DEBUG}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【单相机控制调试工具：针对单摄像头的图形化调试工具，支持参数重置和实时显示】\033[0m\n")
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

# 定义队列用于传递帧数据
frame_queue = Queue(maxsize=2)

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

# 摄像头控制器
class CameraController:
    def __init__(self, index, device_id):
        self.cap = None
        self.index = index
        self.device_id = device_id
        self.exit_event = Event()
        self.lock = Lock()
        self.last_frame_time = 0

    def initialize(self):  # 初始化摄像头
        with self.lock:
            self.cap = cv2.VideoCapture(self.index)  # 打开摄像头
            if not self.cap.isOpened():  # 检查是否打开成功
                return False
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
            self._init_params()
            return True

    def _init_params(self):  # 初始化参数
        for param in BASE_CAMERA_PARAMS:
            value = param["value"]
            self._set_v4l2_param(param, value)

    def _set_v4l2_param(self, param, value):
        device = f"/dev/video{self.index}"
        cmd = f"v4l2-ctl -d {device} --set-ctrl={param['v4l2_param']}={value}"
        print(f"执行命令: {cmd}")
        result = subprocess.run(cmd, shell=True, check=False, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"命令执行失败，错误信息: {result.stderr}")

    def run(self):  # 运行摄像头
        while not self.exit_event.is_set():  # 循环读取摄像头
            with self.lock:
                if self.cap.isOpened():
                    if time.time() - self.last_frame_time < 1 / MAX_FPS:  # 限制帧率
                        time.sleep(0.001)
                        continue
                    ret, frame = self.cap.read()
                    self.last_frame_time = time.time()
                    if ret and not frame_queue.full():  # 将帧放入队列
                        frame = cv2.resize(frame, (640, 480))  # 缩放
                        frame_queue.put((self.device_id, frame), block=False)
            time.sleep(0.001)
        with self.lock:
            if self.cap.isOpened():
                self.cap.release()


class CameraControlPro(tk.Toplevel):  # 摄像头控制界面
    def __init__(self, master, camera_controller):
        super().__init__(master)
        self.camera_controller = camera_controller  # 摄像头控制器
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
        param_list = BASE_CAMERA_PARAMS # 参数列表
        for i in range(0, len(param_list), 3):
            for col in range(3):
                if i + col < len(param_list):
                    param = param_list[i + col]
                    frame = ttk.LabelFrame(self.main_frame, text=param["chinese_name"]) # 参数框架
                    frame.grid(row=self.row, column=col, padx=5, pady=5, sticky="nsew") # 设置参数框架
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
            slider.pack(side=tk.LEFT, fill=tk.X, expand=True)
            entry = ttk.Entry(control_frame, textvariable=var, width=8)
            entry.pack(side=tk.LEFT)
            param["var"] = var
            var.trace("w", lambda *args: self.on_param_change(param))
        elif param["type"] == "menu": # 下拉菜单
            options = param["options"].split("；")
            if 0 <= param["value"] < len(options):
                var = tk.StringVar(value=options[param["value"]])
            else:
                var = tk.StringVar(value=options[0])
                print(f"警告: 参数 {param['chinese_name']} 的值 {param['value']} 超出选项索引范围，使用第一个选项。")
            cb = ttk.Combobox(control_frame, textvariable=var, values=options)
            cb.pack(fill=tk.X, expand=True)
            param["var"] = var
            cb.bind("<<ComboboxSelected>>", lambda event: self.on_param_change(param))
        elif param["type"] == "bool": # 布尔值
            var = tk.IntVar(value=param["value"])
            cb = ttk.Checkbutton(control_frame, variable=var)
            cb.pack(side=tk.LEFT)
            param["var"] = var
            var.trace("w", lambda *args: self.on_param_change(param))

        status_label = ttk.Label(frame, text="设置状态: 未设置", foreground="gray")
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
            result = subprocess.run(cmd, shell=True, check=False, capture_output=True, text=True)
            if result.returncode == 0:
                param["status_label"].config(text="设置状态: 成功", foreground="green")
            else:
                param["status_label"].config(text="设置状态: 失败", foreground="red")
                print(f"\033[31m错误：{param['chinese_name']} 设置失败\033[0m")  # 终端红色输出错误提示
        except ValueError as ve:
            param["status_label"].config(text="设置状态: 数值超出范围", foreground="red")
            print(f"\033[31m错误：{param['chinese_name']} 数值超出范围\033[0m")
        except Exception:
            param["status_label"].config(text="设置状态: 出错", foreground="red")
            print(f"\033[31m错误：{param['chinese_name']} 设置出错\033[0m")

    def add_buttons(self):  # 添加按钮
        button_frame = ttk.Frame(self.main_frame)
        button_frame.grid(row=self.row, column=0, columnspan=3, pady=10)
        ttk.Button(button_frame, text="默认值", command=lambda: self.reset_params("default")).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="厂商值", command=lambda: self.reset_params("value")).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="用户值", command=lambda: self.reset_params("setvalue")).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="退出(Q)", command=self.exit_app).pack(side=tk.LEFT, padx=5)

    def reset_params(self, mode): # 重置参数
        for param in BASE_CAMERA_PARAMS:
            if mode == "default": # 默认值
                val = param["default"]
            elif mode == "value": # 厂商值
                val = param["value"]
            elif mode == "setvalue": # 用户值
                val = param["setvalue"]
            else:
                continue
            if param["type"] == "int":
                param["var"].set(val)
            elif param["type"] == "menu":
                options = param["options"].split("；")
                if val < len(options):
                    param["var"].set(options[val])
            elif param["type"] == "bool":
                param["var"].set(val)
            self.on_param_change(param)

    def exit_app(self):   # 退出
        self.camera_controller.exit_event.set()
        cv2.destroyAllWindows()
        self.destroy()


def list_cameras():
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")]  # 视频设备

    for device in video_devices:  # 检测设备
        try:
            index = int(device.split('video')[1])
            cmd = ["udevadm", "info", "-q", "property", device]
            result = subprocess.run(cmd, capture_output=True, text=True)
            vid, pid = "N/A", "N/A"
            for line in result.stdout.splitlines(): # 获取设备信息
                if line.startswith("ID_VENDOR_ID="):
                    vid = line.split('=')[1].strip().upper() # 获取厂商ID
                elif line.startswith("ID_MODEL_ID="):
                    pid = line.split('=')[1].strip().upper() # 获取产品ID
            device_id = f"{vid}-{pid}" if vid != "N/A" and pid != "N/A" else "UNKNOWN"
            available.append((index, device_id)) # 添加设备信息
        except Exception as e:
            print(f"设备检测错误: {str(e)}")
    return available


def display_frames():  # 显示帧
    windows = {} # 窗口字典
    while True:
        try:
            device_id, frame = frame_queue.get(timeout=0.1)  # 获取帧
            if device_id not in windows:
                cv2.namedWindow(device_id, cv2.WINDOW_NORMAL)  # 创建窗口
                cv2.resizeWindow(device_id, 640, 480)
            cv2.imshow(device_id, frame)
            if cv2.waitKey(1) & 0xFF == ord('q'): # 按下q键退出
                break
        except Empty:
            pass
        except Exception as e:
            print(f"显示异常: {str(e)}")
    cv2.destroyAllWindows() # 关闭窗口


def main():
    camera_info = list_cameras() # 摄像头信息
    if not camera_info:
        print("未检测到摄像头设备")
        return
    root = tk.Tk()  # 主窗口
    root.withdraw()  # 隐藏主窗口
    display_thread = Thread(target=display_frames, daemon=True)  # 显示线程
    display_thread.start()  # 启动显示线程

    for index, device_id in camera_info:
        camera_controller = CameraController(index, device_id)
        if not camera_controller.initialize():
            print(f"{device_id} 相机初始化失败，未开启")
            continue
        app = CameraControlPro(root, camera_controller)  # 创建窗口
        camera_thread = Thread(target=camera_controller.run, daemon=True)  # 相机线程
        camera_thread.start()  # 启动相机线程

    root.mainloop() # 等待退出
    cv2.destroyAllWindows() # 关闭窗口

if __name__ == "__main__":
    main()
# ----------------------------------------------------------------------------------------------------------------------
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${V4L2_QUICK} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 在不打开相机画面的情况下为多个相机设置参数，当前调用setvalue数据 ${COLOR_RESET}" # 程序声明
# echo -e "${COLOR_WARNING} 警告声明 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_V4L2_QUICK}" # 程序路径
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
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${V4L2_TEST_SLIDER} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 多相机UI画面调试工具：针对成品系列参数设置 ${COLOR_RESET}" # 程序声明
# echo -e "${COLOR_WARNING} 警告声明 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_V4L2_TEST_SLIDER}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【多相机UI画面调试工具：针对成品系列参数设置】\033[0m\n")
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

# 定义队列用于传递帧数据
frame_queue = Queue(maxsize=2)

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
            if not self.cap.isOpened():  # 检查是否打开成功
                return False
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


class CameraControlPro(tk.Toplevel):  # 摄像头控制界面
    def __init__(self, master, camera_controller):
        super().__init__(master)
        self.camera_controller = camera_controller  # 摄像头控制器
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
        ttk.Button(button_frame, text="默认值", command=lambda: self.reset_params("default")).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="厂商值", command=lambda: self.reset_params("value")).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="用户值", command=lambda: self.reset_params("setvalue")).pack(side=tk.LEFT, padx=5)
        ttk.Button(button_frame, text="退出(Q)", command=self.exit_app).pack(side=tk.LEFT, padx=5)

    def reset_params(self, mode): # 重置参数
        for param in self.camera_controller.camera_params:
            if mode == "default":
                val = param["default"]
            elif mode == "value":
                val = param["value"]
            elif mode == "setvalue":
                val = param["setvalue"]
            else:
                continue
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
        cv2.destroyWindow(self.camera_controller.device_id) # 关闭窗口
        self.destroy()


def list_cameras():
    available = []
    video_devices = [f"/dev/{d}" for d in os.listdir("/dev") if d.startswith("video")]  # 视频设备

    for device in video_devices:  # 检测设备
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


def main():
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
    for index, device_id in camera_info:
        camera_controller = CameraController(index, device_id)
        if not camera_controller.initialize():
            print(f"{device_id} 相机初始化失败，未开启")
            continue
        app = CameraControlPro(root, camera_controller)  # 创建窗口
        camera_thread = Thread(target=camera_controller.run, daemon=True)  # 相机线程
        camera_thread.start()
        controllers.append(camera_controller) # 添加相机控制器
        apps.append(app)

    root.mainloop()
    for controller in controllers: # 关闭相机
        controller.exit_event.set()
    cv2.destroyAllWindows() # 关闭窗口

if __name__ == "__main__":
    main()
# ----------------------------------------------------------------------------------------------------------------------
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${V4L2_TEST_SCHEME} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 带画面的多方案适应多种类软体的相机调试工具 ${COLOR_RESET}" # 程序声明
# echo -e "${COLOR_WARNING} 警告声明 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_V4L2_TEST_SCHEME}" # 程序路径
# ====================================================== 程序声明 ======================================================
print("\n\033[93m【带画面的多方案适应多种类软体的相机调试工具】\033[0m")
print("\033[91m【可以设定多种方案，当前初始化参数设定为 默认值 方案】\033[0m\n")
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

# "方案"：[亮度,对比度,饱和度,色调,自动白平衡,伽马值,增益,电源频率,白平衡,清晰度,背光补偿,自动曝光,绝对曝光时间,动态帧率曝光,绝对对焦,连续自动对焦]
# 下面提供4组方案仅参考，用户可以自行添加方案，也可以修改当前方案的数值
SCHEMES = {
    "默认值": [-39, 39, 72, 0, 1, 300, 64, 1, 6500, 75, 0, 3, 20, 0, 68, 1],
    "厂商值": [-39, 39, 72, 0, 1, 300, 64, 1, 6500, 75, 0, 1, 20, 0, 68, 1],
    "产品1": [-64, 39, 72, 0, 0, 300, 64, 1, 6000, 75, 0, 1, 20, 1, 68, 1],
    "产品2": [0, 39, 72, 0, 0, 300, 64, 1, 6000, 75, 0, 1, 20, 1, 68, 1],
}

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
        "options": "",
    },
    {
        "chinese_name": "对比度",
        "v4l2_param": "contrast",
        "hex_numbers": "0x00980901",
        "type": "int",
        "min": 0,
        "max": 100,
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
        "min": 100,
        "max": 500,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "增益",
        "v4l2_param": "gain",
        "hex_numbers": "0x00980913",
        "type": "int",
        "min": 1,
        "max": 128,
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
        "step": 10,
        "options": "",
    },
    {
        "chinese_name": "清晰度",
        "v4l2_param": "sharpness",
        "hex_numbers": "0x0098091b",
        "type": "int",
        "min": 0,
        "max": 100,
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
        "min": 0,
        "max": 10000,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "动态帧率曝光",
        "v4l2_param": "exposure_dynamic_framerate",
        "hex_numbers": "0x009a0903",
        "type": "bool",
        "min": None,
        "max": None,
        "step": None,
        "options": "0 表示关闭；1 表示开启",
    },
    {
        "chinese_name": "绝对对焦",
        "v4l2_param": "focus_absolute",
        "hex_numbers": "0x009a090a",
        "type": "int",
        "min": 0,
        "max": 1023,
        "step": 1,
        "options": "",
    },
    {
        "chinese_name": "连续自动对焦",
        "v4l2_param": "focus_automatic_continuous",
        "hex_numbers": "0x009a090c",
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
                        frame = cv2.resize(frame, (640, 480))  # 缩放
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
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
echo -e "${COLOR_PY} ${HD_WEBCAM_DEBUG} ${COLOR_RESET}" # 程序名称
echo -e "${COLOR_PY} 带UI界面的 HD_WebCam 相机专用调试工具 ${COLOR_RESET}" # 程序声明
echo -e "${COLOR_WARNING} 可以设定多种方案，当前初始化参数设定为"默认值"方案 ${COLOR_RESET}" # 警告声明
echo # 输出空行
cat << 'EOF' > "${PATH_HD_WEBCAM_DEBUG}" # 程序路径
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
EOF
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
# ██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "创建桌面快捷方式"
echo # 输出空行

# 生成 .desktop 文件函数
generate_desktop_file() {
    local file="$1" # .desktop 文件路径
    local exec_cmd="$2" # 执行命令
    local name="${file##*/}" # 文件名
    name="${name%.*}" 
    cat << EOF > "$file"
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Comment=Camera Debug
Exec=bash -c "$exec_cmd"
Terminal=true
Categories=Development;Education;
EOF
    chown "$CURRENT_USER:$CURRENT_USER" "$file"
    chmod 755 "$file"
    print_info "$name $file"
}

# 循环处理并生成 .desktop 文件
for info in "${desktop_info[@]}"; do
    IFS=':' read -r file_path exec_cmd <<< "$info"
    generate_desktop_file "$file_path" "$exec_cmd"
done

#===============================================================================================================================================================
print_separator # 输出分隔线

# 修复阿里云镜像源文件
echo # 输出空行
print_info "恢复阿里云镜像源文件"
if [ -f /etc/apt/sources.list.bak ]; then
    sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
else
    echo "备份文件 /etc/apt/sources.list.bak 不存在，无法恢复。"
fi

# 修复工作目录权限
echo # 输出空行
print_info "修复工作目录权限"
chown -R "$CURRENT_USER:$CURRENT_USER" "$WORK_DIR"
find "$WORK_DIR" -type f -exec chmod 644 {} \;
find "$WORK_DIR" -type d -exec chmod 755 {} \;

# 内核与设备修复
echo # 输出空行
print_info "执行系统级修复"
modprobe -r uvcvideo && modprobe uvcvideo # 修复uvcvideo内核模块
echo 'SUBSYSTEM=="video4linux", MODE="0666", GROUP="video"' > "$UDEV_RULE_FILE" # 添加udev规则  
udevadm control --reload # 重新加载udev规则
udevadm trigger # 触发udev规则

#===============================================================================================================================================================
print_separator # 输出分隔线
print_info "安装完成"
exit