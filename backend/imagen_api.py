"""
Imagen 3 API 集成模块
"""
import aiohttp
import asyncio
import json
import base64
from typing import Optional, Dict, Any
import os

GEMINI_API_KEY = "AIzaSyB-ZYo5kMjtpqnOyjEELzy8PD8VnMTuvkw"

async def generate_image_with_imagen(prompt: str) -> Optional[Dict[str, Any]]:
    """
    使用Imagen 3 API生成图片
    
    Args:
        prompt: 图片生成提示词
    
    Returns:
        包含图片信息的字典，或None（如果失败）
    """
    
    # Imagen 4 API端点 (使用最新的预览版) - 使用predict方法
    url = "https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-preview-06-06:predict"
    
    headers = {
        "Content-Type": "application/json"
    }
    
    # 更新为正确的请求格式
    # 添加API key到URL参数
    url_with_key = f"{url}?key={GEMINI_API_KEY}"
    
    # 请求体 - 根据新API格式
    payload = {
        "prompt": prompt,
        "instances": 1,  # 生成1张图片
        "parameters": {
            "aspectRatio": "1:1",
            "negativePrompt": "blurry, low quality, distorted",
            "safetyFilterLevel": "block_some",
            "personGeneration": "allow_adult"
        }
    }
    
    try:
        async with aiohttp.ClientSession() as session:
            async with session.post(
                url_with_key,
                headers=headers,
                json=payload,
                timeout=aiohttp.ClientTimeout(total=30)
            ) as response:
                
                if response.status == 200:
                    result = await response.json()
                    print(f"Imagen API响应成功: {json.dumps(result, indent=2)[:500]}...")
                    
                    # 解析响应
                    if "predictions" in result and len(result["predictions"]) > 0:
                        prediction = result["predictions"][0]
                        
                        # 检查是否有base64编码的图片
                        if "bytesBase64Encoded" in prediction:
                            return {
                                "success": True,
                                "image_data": prediction["bytesBase64Encoded"],
                                "format": "base64"
                            }
                        # 检查是否有图片URL
                        elif "imageUrl" in prediction:
                            return {
                                "success": True,
                                "image_url": prediction["imageUrl"],
                                "format": "url"
                            }
                    
                    print(f"Imagen API响应格式不符合预期: {result}")
                    return None
                    
                else:
                    error_text = await response.text()
                    print(f"Imagen API错误 ({response.status}): {error_text}")
                    
                    # 如果是429（限流）错误，等待后重试
                    if response.status == 429:
                        print("API限流，等待5秒后重试...")
                        await asyncio.sleep(5)
                    
                    return None
                    
    except asyncio.TimeoutError:
        print(f"Imagen API请求超时")
        return None
    except Exception as e:
        print(f"调用Imagen API失败: {e}")
        return None


async def test_imagen_api():
    """测试Imagen API"""
    print("测试Imagen 3 API...")
    
    test_prompts = [
        "A beautiful sunset over mountains, photorealistic, high quality",
        "A cute cat sitting on a windowsill, soft lighting",
        "Modern minimalist living room, interior design photography"
    ]
    
    for prompt in test_prompts:
        print(f"\n测试提示词: {prompt}")
        result = await generate_image_with_imagen(prompt)
        
        if result:
            if result["format"] == "base64":
                # 保存base64图片
                image_data = base64.b64decode(result["image_data"])
                filename = f"test_image_{prompt[:20].replace(' ', '_')}.png"
                with open(f"storage/images/{filename}", "wb") as f:
                    f.write(image_data)
                print(f"✅ 图片已保存: {filename}")
            elif result["format"] == "url":
                print(f"✅ 获得图片URL: {result['image_url']}")
        else:
            print("❌ 图片生成失败")
        
        # 避免频繁调用
        await asyncio.sleep(2)


if __name__ == "__main__":
    # 创建存储目录
    os.makedirs("storage/images", exist_ok=True)
    
    # 运行测试
    asyncio.run(test_imagen_api())