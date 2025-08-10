#!/usr/bin/env python3
"""
API测试脚本
"""
import requests
import json
import time

BASE_URL = "http://localhost:8000"

def test_health():
    """测试健康检查"""
    print("1. 测试健康检查API...")
    try:
        response = requests.get(f"{BASE_URL}/api/health")
        if response.status_code == 200:
            print("   ✅ 健康检查通过")
            print(f"   响应: {response.json()}")
        else:
            print(f"   ❌ 健康检查失败: {response.status_code}")
    except Exception as e:
        print(f"   ❌ 连接失败: {e}")
        return False
    return True

def test_variant_generation():
    """测试变体生成"""
    print("\n2. 测试变体生成API...")
    data = {
        "base_prompt": "一个男人和一个女人在吵架",
        "dimensions": ["场景", "光影", "情绪", "角度"],
        "count": 3
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/variants/generate",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print("   ✅ 变体生成成功")
            print(f"   生成了 {result['count']} 个变体:")
            for i, variant in enumerate(result['variants'], 1):
                print(f"   {i}. {variant[:50]}...")
            return result['variants']
        else:
            print(f"   ❌ 变体生成失败: {response.status_code}")
            print(f"   错误: {response.text}")
    except Exception as e:
        print(f"   ❌ 请求失败: {e}")
    return None

def test_image_generation(prompts=None):
    """测试图片生成"""
    print("\n3. 测试图片生成API...")
    
    if prompts is None:
        prompts = [
            "A beautiful sunset over mountains",
            "A cat sitting on a windowsill"
        ]
    
    data = {"prompts": prompts[:2]}  # 只测试前2个
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/images/generate",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print("   ✅ 图片生成API调用成功")
            print(f"   生成了 {result['count']} 张图片:")
            
            for image in result['images']:
                print(f"   - ID: {image['id']}")
                print(f"     URL: {image['url']}")
                print(f"     Prompt: {image['prompt'][:50]}...")
                
                # 测试图片URL是否可访问
                try:
                    img_response = requests.head(image['url'])
                    if img_response.status_code == 200:
                        print(f"     ✅ 图片URL可访问")
                    else:
                        print(f"     ⚠️ 图片URL返回状态码: {img_response.status_code}")
                except:
                    print(f"     ⚠️ 无法访问图片URL")
            
            return result
        else:
            print(f"   ❌ 图片生成失败: {response.status_code}")
            print(f"   错误: {response.text}")
    except Exception as e:
        print(f"   ❌ 请求失败: {e}")
    return None

def test_full_workflow():
    """测试完整工作流程"""
    print("\n" + "="*50)
    print("开始完整工作流程测试")
    print("="*50)
    
    # 1. 健康检查
    if not test_health():
        print("\n❌ 健康检查失败，请确保后端服务正在运行")
        return
    
    # 2. 生成变体
    variants = test_variant_generation()
    if not variants:
        print("\n❌ 变体生成失败")
        return
    
    # 3. 使用变体生成图片
    print("\n4. 使用生成的变体创建图片...")
    image_result = test_image_generation(variants)
    
    if image_result:
        print("\n" + "="*50)
        print("✅ 完整工作流程测试成功！")
        print("="*50)
        print("\n测试总结:")
        print(f"  - API健康状态: 正常")
        print(f"  - 生成变体数: {len(variants)}")
        print(f"  - 生成图片数: {image_result['count']}")
        
        print("\n诊断结果:")
        print("  ✅ 后端API正常工作")
        print("  ✅ 变体生成功能正常")
        print("  ✅ 图片生成API正常")
        print("  ℹ️ 如果前端显示有问题，可能是:")
        print("     1. 浏览器缓存问题 - 请刷新页面(Ctrl+F5)")
        print("     2. JavaScript错误 - 请打开浏览器控制台查看")
        print("     3. CORS问题 - 后端已配置允许所有来源")
    else:
        print("\n❌ 工作流程测试失败")

if __name__ == "__main__":
    test_full_workflow()
    
    print("\n" + "="*50)
    print("💡 建议:")
    print("1. 刷新浏览器页面重新测试")
    print("2. 打开浏览器开发者工具(F12)查看控制台错误")
    print("3. 使用测试页面: test_image_generation.html")
    print("="*50)