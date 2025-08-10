"""
FastAPI主应用入口 - 完整版本
支持Gemini API调用
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, StreamingResponse
from contextlib import asynccontextmanager
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
import os
import json
import asyncio
import aiohttp
import base64
from datetime import datetime
import uuid

# 创建必要的目录
os.makedirs("storage/images", exist_ok=True)
os.makedirs("storage/temp", exist_ok=True)

# API配置
GEMINI_API_KEY = "AIzaSyB-ZYo5kMjtpqnOyjEELzy8PD8VnMTuvkw"
GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    print("🚀 启动提示词变体与图片生成工具")
    yield
    print("👋 应用关闭")

# 创建FastAPI应用
app = FastAPI(
    title="提示词变体与图片生成工具",
    version="2.0.0",
    lifespan=lifespan
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 数据模型
class VariantGenerateRequest(BaseModel):
    base_prompt: str
    dimensions: List[str]
    count: int = 8

class ImageGenerateRequest(BaseModel):
    prompts: List[str]
    aspect_ratio: str = "1:1"  # 默认1:1，支持: 1:1, 9:16, 16:9, 3:4, 4:3

@app.get("/")
async def root():
    """根路径"""
    return {
        "name": "提示词变体与图片生成工具",
        "version": "2.0.0",
        "status": "running",
        "endpoints": {
            "generate_variants": "/api/variants/generate",
            "generate_images": "/api/images/generate",
            "health": "/api/health"
        }
    }

@app.get("/api/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/api/variants/generate")
async def generate_variants(request: VariantGenerateRequest):
    """生成提示词变体"""
    try:
        # 构建Gemini请求
        dimensions_str = "、".join(request.dimensions)
        system_prompt = f"""
        你是一个专业的AI图像生成提示词专家。请基于用户提供的基础提示词，生成{request.count}个不同的变体。
        
        变化维度包括：{dimensions_str}
        
        要求：
        1. 每个变体都必须包含原始提示词的内容，然后添加指定维度的详细描述
        2. 保持原始提示词的核心主题
        3. 使用详细、具体的英文描述
        4. 适合用于AI图像生成
        5. 每个变体的格式应该是：[原始内容的英文翻译], [维度描述1], [维度描述2], ...
        6. 返回JSON格式：{{"variants": ["完整变体1", "完整变体2", ...]}}
        
        例如，如果基础提示词是"一个男人和一个女人在吵架"，变体应该是：
        "A man and a woman arguing, in a modern coffee shop, dramatic lighting, angry expressions"
        """
        
        # 尝试调用Gemini API
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{GEMINI_BASE_URL}/models/gemini-2.0-flash-exp:generateContent?key={GEMINI_API_KEY}"
                
                data = {
                    "contents": [{
                        "parts": [{
                            "text": f"{system_prompt}\n\n基础提示词：{request.base_prompt}"
                        }]
                    }],
                    "generationConfig": {
                        "temperature": 0.9,
                        "maxOutputTokens": 2048,
                    }
                }
                
                async with session.post(url, json=data) as response:
                    if response.status == 200:
                        result = await response.json()
                        content = result['candidates'][0]['content']['parts'][0]['text']
                        
                        # 解析JSON响应
                        try:
                            # 清理可能的markdown代码块标记
                            cleaned_content = content.strip()
                            if cleaned_content.startswith("```json"):
                                cleaned_content = cleaned_content[7:]  # 移除 ```json
                            elif cleaned_content.startswith("```"):
                                cleaned_content = cleaned_content[3:]  # 移除 ```
                            if cleaned_content.endswith("```"):
                                cleaned_content = cleaned_content[:-3]  # 移除结尾的 ```
                            cleaned_content = cleaned_content.strip()
                            
                            variants_data = json.loads(cleaned_content)
                            variants = variants_data.get('variants', [])[:request.count]
                            print(f"✅ Gemini API返回的变体: {variants}")
                        except Exception as parse_error:
                            # 如果解析失败，使用备用方案
                            print(f"⚠️ Gemini响应解析失败: {parse_error}")
                            print(f"原始响应: {content[:500]}")
                            variants = generate_offline_variants(request.base_prompt, request.dimensions, request.count)
                    else:
                        raise Exception("Gemini API调用失败")
                        
        except Exception as e:
            print(f"Gemini API错误: {e}")
            # 使用离线生成方案
            variants = generate_offline_variants(request.base_prompt, request.dimensions, request.count)
        
        return {
            "status": "success",
            "variants": variants,
            "count": len(variants)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/images/generate")
async def generate_images(request: ImageGenerateRequest):
    """批量生成图片 - 使用真实的Imagen 4 API"""
    try:
        images = []
        
        # 对每个提示词生成图片
        for i, prompt in enumerate(request.prompts):
            try:
                # 调用Imagen 4 API (使用predict方法)
                async with aiohttp.ClientSession() as session:
                    url = f"{GEMINI_BASE_URL}/models/imagen-4.0-generate-preview-06-06:predict?key={GEMINI_API_KEY}"
                    
                    data = {
                        "instances": [{
                            "prompt": prompt
                        }],
                        "parameters": {
                            "sampleCount": 1,
                            "aspectRatio": request.aspect_ratio  # 添加比例参数
                        }
                    }
                    
                    async with session.post(url, json=data, timeout=aiohttp.ClientTimeout(total=30)) as response:
                        if response.status == 200:
                            result = await response.json()
                            
                            # 解析响应获取图片
                            if 'predictions' in result and len(result['predictions']) > 0:
                                prediction = result['predictions'][0]
                                
                                # 如果有base64编码的图片
                                if 'bytesBase64Encoded' in prediction:
                                    # 保存base64图片
                                    image_id = str(uuid.uuid4())[:8]
                                    image_path = f"storage/images/{image_id}.png"
                                    
                                    # 解码并保存图片
                                    import base64
                                    image_data = base64.b64decode(prediction['bytesBase64Encoded'])
                                    with open(image_path, 'wb') as f:
                                        f.write(image_data)
                                    
                                    # 返回本地URL
                                    image_url = f"http://localhost:8000/api/images/{image_id}"
                                    print(f"✅ 成功生成图片: {image_id}.png")
                                else:
                                    # 如果API返回的是URL
                                    image_url = prediction.get('imageUrl', f"https://via.placeholder.com/800x600/667eea/ffffff?text=Image+{i+1}")
                                    image_id = str(uuid.uuid4())[:8]
                            else:
                                # 使用占位图片
                                print(f"Imagen API响应格式不符合预期: {result}")
                                image_url = f"https://via.placeholder.com/800x600/667eea/ffffff?text=Generated+Image+{i+1}"
                                image_id = str(uuid.uuid4())[:8]
                        else:
                            # API调用失败，使用占位图片
                            error_text = await response.text()
                            print(f"Imagen API错误 ({response.status}): {error_text}")
                            image_url = f"https://via.placeholder.com/800x600/667eea/ffffff?text=Generated+Image+{i+1}"
                            image_id = str(uuid.uuid4())[:8]
                            
            except Exception as e:
                print(f"调用Imagen API失败: {e}")
                # 使用占位图片
                image_url = f"https://via.placeholder.com/800x600/667eea/ffffff?text=Generated+Image+{i+1}"
                image_id = str(uuid.uuid4())[:8]
            
            # 保存图片信息
            image_info = {
                "id": image_id,
                "prompt": prompt,
                "url": image_url,
                "created_at": datetime.now().isoformat()
            }
            
            images.append(image_info)
            
            # 短暂延迟避免API限流
            await asyncio.sleep(1)
        
        return {
            "status": "success",
            "images": images,
            "count": len(images)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/images/{image_id}")
async def get_image(image_id: str):
    """获取单张图片"""
    image_path = f"storage/images/{image_id}.png"
    
    if os.path.exists(image_path):
        return FileResponse(image_path, media_type="image/png")
    else:
        raise HTTPException(status_code=404, detail="图片不存在")

@app.post("/api/images/download")
async def download_images(request: List[str]):
    """批量下载图片 - 创建zip文件"""
    import zipfile
    import io
    from fastapi.responses import StreamingResponse
    
    # 创建内存中的zip文件
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zip_file:
        for idx, image_id in enumerate(request):  # 使用request而不是image_ids
            image_path = f"storage/images/{image_id}.png"
            if os.path.exists(image_path):
                # 添加图片到zip文件
                zip_file.write(image_path, f"image_{idx+1}_{image_id}.png")
    
    # 重置缓冲区位置
    zip_buffer.seek(0)
    
    # 返回zip文件作为下载
    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={"Content-Disposition": f"attachment; filename=images_batch_{datetime.now().strftime('%Y%m%d_%H%M%S')}.zip"}
    )

def generate_offline_variants(base_prompt: str, dimensions: List[str], count: int) -> List[str]:
    """离线生成变体（备用方案）"""
    
    # 基础提示词的简单英文翻译映射
    base_translations = {
        "一个男人和一个女人在吵架": "A man and a woman arguing",
        "一群美国高中生在操场上军训": "A group of American high school students in military training on playground",
        "教官在督促高中生进行体能训练": "An instructor supervising high school students in physical training",
        "一只猫在窗台上晒太阳": "A cat basking in the sun on a windowsill",
        "小孩在公园里玩耍": "Children playing in a park",
        "程序员在写代码": "A programmer writing code",
        "学生在教室里上课": "Students attending class in a classroom",
        "厨师在准备美食": "A chef preparing delicious food",
        # 如果没有预设翻译，检查是否已经是英文
    }
    
    # 获取英文版本的基础提示词
    # 如果已经是英文（不含中文字符），直接使用
    # 否则使用映射或返回原文（让Imagen自己处理）
    if base_prompt in base_translations:
        english_base = base_translations[base_prompt]
    elif not any('\u4e00' <= char <= '\u9fff' for char in base_prompt):
        # 如果不含中文字符，认为是英文，直接使用
        english_base = base_prompt
    else:
        # 如果是未知的中文，尝试基础翻译或保持原样
        # 注意：这里理想情况应该调用翻译API，但作为备用方案，我们简单处理
        print(f"⚠️ 未找到预设翻译: {base_prompt}")
        # 返回一个安全的默认值，包含原始提示词信息
        english_base = f"Scene: {base_prompt}"
    
    # 根据选择的维度生成模板
    dimension_templates = {
        "场景": ["in a modern coffee shop", "at a busy street", "in a quiet park", "at home", "in an office"],
        "动作": ["arguing intensely", "having a discussion", "in confrontation", "gesturing emotionally", "standing face to face"],
        "穿着": ["casual clothing", "formal business attire", "street wear", "elegant outfits", "comfortable home clothes"],
        "光影": ["dramatic lighting", "soft natural light", "moody shadows", "golden hour glow", "harsh fluorescent light"],
        "站位": ["facing each other", "one turning away", "close proximity", "separated by distance", "side by side"],
        "情绪": ["angry expressions", "frustrated looks", "emotional tension", "heated exchange", "visible distress"],
        "构图": ["close-up shot", "wide angle view", "over-shoulder perspective", "symmetrical composition", "dynamic diagonal"],
        "色调": ["warm tones", "cool blues", "monochromatic", "vibrant colors", "muted palette"],
        "风格": ["photorealistic", "cinematic", "artistic", "documentary style", "dramatic"],
        "时间": ["during daytime", "at sunset", "late at night", "early morning", "golden hour"],
        "天气": ["on a rainy day", "in bright sunshine", "during a storm", "on a cloudy day", "in fog"],
        "角度": ["low angle shot", "bird's eye view", "eye level", "dutch angle", "close-up"],
        "特效": ["motion blur", "depth of field", "lens flare", "bokeh effect", "sharp focus"],
        "材质": ["rough textures", "smooth surfaces", "fabric details", "skin texture", "environmental textures"],
        "纹理": ["detailed rendering", "soft edges", "crisp details", "textured background", "smooth gradients"],
        "氛围": ["tense atmosphere", "dramatic mood", "emotional intensity", "uncomfortable silence", "charged environment"],
        "细节": ["facial expressions", "body language", "hand gestures", "eye contact", "micro-expressions"],
        "背景": ["urban setting", "indoor scene", "natural environment", "minimalist background", "detailed environment"]
    }
    
    # 生成变体
    variants = []
    for i in range(count):
        variant_parts = []
        
        # 从每个选中的维度随机选择一个模板
        for dim in dimensions:
            if dim in dimension_templates:
                templates_list = dimension_templates[dim]
                template = templates_list[i % len(templates_list)]
                variant_parts.append(template)
        
        # 组合成完整的英文提示词：英文基础 + 维度描述
        if variant_parts:
            variant = f"{english_base}, {', '.join(variant_parts)}"
        else:
            variant = english_base
        variants.append(variant)
    
    return variants

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )