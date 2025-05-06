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
