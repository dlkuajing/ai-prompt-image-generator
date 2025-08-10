# 🎨 AI提示词变体与图片批量生成工具

基于 **Gemini 2.0 Flash Exp** 和 **Imagen 4** API 的智能图片生成工具。

## ✨ 功能特点

- 🔄 **智能提示词变体生成** - 基于18个维度自动生成提示词变体
- 🖼️ **批量图片生成** - 使用Imagen 4 API生成高质量图片  
- 📐 **多种比例支持** - 支持5种图片比例（1:1、9:16、16:9、3:4、4:3）
- 📥 **批量下载** - 一键打包下载所有生成的图片
- 🌐 **局域网共享** - 支持多用户同时使用

## 🚀 快速开始

### 1. 启动后端服务
```bash
cd backend
source venv/bin/activate  # macOS/Linux
python main.py
```

### 2. 打开前端界面
在浏览器中打开 `index.html` 文件

## 📖 文档

- [技术文档](CLAUDE.md) - 详细的项目技术说明
- [启动指南](启动指南.md) - 快速启动步骤
- [局域网访问指南](局域网访问指南.md) - 多用户使用说明

## 🛠️ 技术栈

- **后端**: FastAPI + Python 3.x
- **API**: Google Gemini 2.0 + Imagen 4
- **前端**: HTML5 + CSS3 + JavaScript

## 📝 许可证

本项目仅供学习和个人使用。

---

🤖 使用 [Claude](https://claude.ai) 协助开发