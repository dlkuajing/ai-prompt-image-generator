"""
测试可用的Gemini模型
"""
import requests

API_KEY = "AIzaSyB-ZYo5kMjtpqnOyjEELzy8PD8VnMTuvkw"

def list_available_models():
    """列出所有可用的模型"""
    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={API_KEY}"
    
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            print("可用的模型列表：")
            print("="*50)
            
            for model in data.get('models', []):
                name = model.get('name', '')
                display_name = model.get('displayName', '')
                supported_methods = model.get('supportedGenerationMethods', [])
                
                # 只显示支持图片生成的模型
                if 'generateImage' in supported_methods or 'imagen' in name.lower():
                    print(f"\n模型名称: {name}")
                    print(f"显示名称: {display_name}")
                    print(f"支持的方法: {', '.join(supported_methods)}")
                    print(f"描述: {model.get('description', 'N/A')[:100]}...")
            
            # 也显示所有文本生成模型
            print("\n\n文本生成模型：")
            print("="*50)
            for model in data.get('models', []):
                name = model.get('name', '')
                display_name = model.get('displayName', '')
                supported_methods = model.get('supportedGenerationMethods', [])
                
                if 'generateContent' in supported_methods:
                    print(f"\n模型名称: {name}")
                    print(f"显示名称: {display_name}")
                    
        else:
            print(f"请求失败: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"错误: {e}")

if __name__ == "__main__":
    list_available_models()