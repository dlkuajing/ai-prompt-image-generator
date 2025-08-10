# 🎨 AI提示词变体与图片批量生成工具

## 项目概述

这是一个基于 **Gemini 2.0 Flash Exp** 和 **Imagen 4** API 的智能图片生成工具。用户只需输入一个简单的基础提示词，系统就能自动生成多个变体提示词，并批量生成高质量的AI图片。

### 核心功能
- 🔄 **智能提示词变体生成** - 基于18个维度自动生成提示词变体
- 🖼️ **批量图片生成** - 使用Imagen 4 API生成高质量图片
- 📐 **多种比例支持** - 支持5种图片比例（1:1、9:16、16:9、3:4、4:3）
- 📥 **批量下载** - 一键打包下载所有生成的图片
- 🌐 **Web界面** - 友好的交互界面，支持局域网访问

## 技术架构

### 后端技术栈
- **框架**: FastAPI (Python 3.x)
- **异步处理**: asyncio + aiohttp
- **API集成**: 
  - Gemini 2.0 Flash Exp (文本生成)
  - Imagen 4.0 Preview (图片生成)
- **缓存**: Redis (可选)
- **文件处理**: Pillow, zipfile

### 前端技术栈
- **纯HTML/CSS/JavaScript** (无需构建工具)
- **响应式设计**
- **实时进度显示**
- **拖拽、复制等交互功能**

### API密钥
```
GEMINI_API_KEY=AIzaSyB-ZYo5kMjtpqnOyjEELzy8PD8VnMTuvkw
```
此密钥同时支持 Gemini 和 Imagen API 调用。

## 项目结构

```
跨海帆-闪图/
├── backend/
│   ├── main.py                 # FastAPI主应用
│   ├── imagen_api.py           # Imagen API集成模块
│   ├── test_api.py            # API测试脚本
│   ├── test_gemini_models.py  # 模型列表测试
│   ├── requirements.txt       # Python依赖
│   ├── storage/
│   │   ├── images/            # 生成的图片存储
│   │   └── temp/              # 临时文件
│   └── venv/                  # Python虚拟环境
├── index.html                  # 主界面
├── demo_new_features.html     # 新功能演示页面
├── view_images.html           # 图片查看页面
└── CLAUDE.md                  # 项目文档（本文件）
```

## 核心功能详解

### 1. 提示词变体生成

系统支持18个变化维度：
- **视觉维度**: 场景、光影、色调、角度、构图
- **内容维度**: 动作、穿着、站位、情绪、细节
- **环境维度**: 时间、天气、背景、氛围
- **技术维度**: 风格、特效、材质、纹理

**工作流程**:
1. 用户输入基础提示词（如："一个男人和一个女人在吵架"）
2. 选择变化维度（可多选）
3. 设置生成数量（1-20个）
4. 调用 Gemini API 生成变体
5. 返回结构化的英文提示词

### 2. 图片生成功能

**使用 Imagen 4 API**:
- 模型: `imagen-4.0-generate-preview-06-06`
- 端点: `:predict` 方法
- 返回: Base64编码的PNG图片

**支持的比例**:
- **1:1** (1024×1024) - 正方形，适合头像
- **9:16** (768×1408) - 竖屏，适合手机壁纸
- **16:9** (1408×768) - 横屏，适合桌面壁纸
- **3:4** - 竖版，适合人像照片
- **4:3** - 横版，适合传统摄影

### 3. 批量处理能力

- 支持批量选择提示词变体
- 异步并发生成图片
- 实时进度显示
- 批量下载（ZIP打包）

## 快速开始

### 1. 安装依赖

```bash
# 进入backend目录
cd backend

# 创建虚拟环境
python3 -m venv venv

# 激活虚拟环境
source venv/bin/activate  # macOS/Linux
# 或
venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt
```

### 2. 启动后端服务

```bash
# 在backend目录下
python main.py
```

服务将在 `http://localhost:8000` 启动

### 3. 打开前端界面

直接在浏览器中打开 `index.html` 文件，或通过HTTP服务器访问。

## API接口文档

### 健康检查
```
GET /api/health
```

### 生成提示词变体
```
POST /api/variants/generate
{
    "base_prompt": "基础提示词",
    "dimensions": ["场景", "光影", ...],
    "count": 8
}
```

### 批量生成图片
```
POST /api/images/generate
{
    "prompts": ["prompt1", "prompt2", ...],
    "aspect_ratio": "1:1"  // 可选: 1:1, 9:16, 16:9, 3:4, 4:3
}
```

### 获取单张图片
```
GET /api/images/{image_id}
```

### 批量下载图片
```
POST /api/images/download
["image_id1", "image_id2", ...]
```
返回ZIP文件流

## 使用示例

### 基础使用流程

1. **输入提示词**: "一个男人和一个女人在吵架"
2. **选择维度**: 场景、动作、光影、情绪等
3. **生成变体**: 获得8个不同的变体提示词
4. **选择变体**: 勾选想要生成图片的变体
5. **选择比例**: 选择合适的图片比例
6. **生成图片**: 批量生成AI图片
7. **下载图片**: 一键下载所有图片

### 测试脚本

```bash
# 测试完整工作流程
python test_api.py

# 测试可用模型
python test_gemini_models.py

# 测试Imagen API
python imagen_api.py
```

## 性能优化

### 当前优化
- 异步并发处理请求
- Base64图片本地缓存
- 内存中创建ZIP文件
- 前端懒加载图片

### 建议优化
- 添加Redis缓存常用提示词
- 实现WebSocket实时通信
- 添加图片CDN支持
- 实现队列系统处理大批量请求

## 已知限制

1. **API限制**:
   - Gemini API有请求频率限制
   - Imagen 4 每次请求生成1张图片
   - 图片生成时间约8-10秒/张

2. **图片尺寸**:
   - 最大分辨率取决于选择的比例
   - 文件大小通常为1-2MB/张

3. **并发限制**:
   - 建议同时生成不超过10张图片
   - 大批量请求建议分批处理

## 故障排除

### 常见问题

1. **Redis未安装**
```bash
# macOS
brew install redis
brew services start redis

# Ubuntu/Debian
sudo apt-get install redis-server
sudo systemctl start redis
```

2. **图片生成失败**
- 检查API密钥是否有效
- 确认网络连接正常
- 查看`backend/server.log`日志

3. **前端无法访问后端**
- 确认后端服务运行在8000端口
- 检查CORS配置
- 使用`http://localhost:8000`而非`file://`协议

## 开发路线图

### 已完成功能 ✅
- [x] 基础提示词变体生成
- [x] Imagen 4 API集成
- [x] 多比例图片支持
- [x] 批量下载功能
- [x] Web界面

### 计划功能 📋
- [ ] 用户认证系统
- [ ] 历史记录保存
- [ ] 提示词模板库
- [ ] 图片编辑功能
- [ ] API使用统计
- [ ] Docker容器化部署
- [ ] 多语言支持

## 贡献指南

欢迎提交Issue和Pull Request！

### 代码规范
- Python: 遵循PEP 8
- JavaScript: 使用ES6+语法
- 提交信息: 使用语义化提交

### 测试要求
- 新功能需要添加测试
- 确保所有测试通过
- 更新相关文档

## 许可证

本项目仅供学习和个人使用。使用Google Gemini和Imagen API需遵守其服务条款。

## 联系方式

如有问题或建议，请提交Issue或联系项目维护者。

---

*最后更新: 2025年8月10日*
*版本: 2.0.0*