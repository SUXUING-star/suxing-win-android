import json
from base64 import b64encode
from cryptography.fernet import Fernet

# 固定密钥
KEY = b'12312dsf7841dgffd93741gdcxv27492'
fernet = Fernet(b64encode(KEY))

def encrypt_value(value):
    """加密单个值"""
    if value is None:
        return None
    return fernet.encrypt(str(value).encode()).decode()

def encrypt_config(data):
    """递归加密配置对象"""
    encrypted = {}
    for key, value in data.items():
        if isinstance(value, dict):
            encrypted[key] = encrypt_config(value)
        elif value is not None:
            encrypted[key] = encrypt_value(value)
    return encrypted

def json_to_dart(obj, indent=2):
    """将JSON对象转换为Dart Map格式的字符串"""
    if isinstance(obj, dict):
        items = []
        for k, v in obj.items():
            value = json_to_dart(v, indent + 2)
            items.append(f"{' ' * indent}'{k}': {value}")
        return "{\n" + ",\n".join(items) + "\n" + " " * (indent - 2) + "}"
    elif isinstance(obj, str):
        return f"'{obj}'"
    else:
        return str(obj)

def generate_dart_code(encrypted_config):
    """生成Dart类代码"""
    return f'''// 由工具自动生成,请勿手动修改
// lib/config/encrypted_config.dart

class EncryptedConfig {{
  static const Map<String, dynamic> values = {json_to_dart(encrypted_config)};
}}'''

def main():
    # 1. 读取原始配置
    print('读取配置文件...')
    with open('./tools/config.json', 'r', encoding='utf-8') as f:
        config = json.load(f)

    # 2. 加密配置
    print('加密配置...')
    encrypted_config = encrypt_config(config)

    # 3. 保存加密后的配置
    print('保存加密后的配置...')
    with open('./assets/encrypted_config.json', 'w', encoding='utf-8') as f:
        json.dump(encrypted_config, f, indent=2, ensure_ascii=False)

    # 4. 生成Dart代码
    print('生成Dart代码...')
    dart_code = generate_dart_code(encrypted_config)

    # 5. 保存Dart文件
    print('保存Dart文件...')
    with open('./lib/config/encrypted_config.dart', 'w', encoding='utf-8') as f:
        f.write(dart_code)

    print('完成！已生成加密配置和Dart代码文件')

if __name__ == '__main__':
    main()