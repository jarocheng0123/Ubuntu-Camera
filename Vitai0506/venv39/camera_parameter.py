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
