# 🔑 Gemini API 替换指南

## API Key 位置

如果您需要替换 Gemini API Key，需要修改以下文件：

### 1. 主要配置文件

#### 📍 `/backend/main.py` (第25行)
```python
# 当前配置
GEMINI_API_KEY = "AIzaSyB-ZYo5kMjtpqnOyjEELzy8PD8VnMTuvkw"

# 替换为您的API Key
GEMINI_API_KEY = "您的新API_KEY"
```

这是**最重要的配置位置**，控制着：
- 提示词变体生成（Gemini 2.0 Flash Exp）
- 图片生成（Imagen 4.0）

### 2. 测试脚本（可选修改）

#### 📍 `/backend/imagen_api.py` (第11行)
```python
GEMINI_API_KEY = "您的新API_KEY"
```
用于：独立测试Imagen API

#### 📍 `/backend/test_gemini_models.py` (第6行)
```python
API_KEY = "您的新API_KEY"
```
用于：测试可用的Gemini模型列表

### 3. 文档文件（仅供参考，不影响功能）

以下文件中的API Key仅作为文档记录，不需要修改：
- `/CLAUDE.md` (第33行)
- `/README_STARTUP.md` (第86行)
- `/backend/README.md` (第18行)

## 替换步骤

### 方法一：直接编辑（推荐）

1. 编辑主配置文件：
```bash
# 使用任意文本编辑器
nano backend/main.py
# 或
vim backend/main.py
```

2. 找到第25行，替换API Key：
```python
GEMINI_API_KEY = "您的新API_KEY"
```

3. 保存文件并重启后端服务：
```bash
# 停止服务
pkill -f "python main.py"

# 重新启动
cd backend
python main.py
```

### 方法二：使用环境变量（更安全）

1. 修改 `backend/main.py`，添加环境变量支持：
```python
import os

# 优先使用环境变量，否则使用默认值
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "默认API_KEY")
```

2. 设置环境变量：
```bash
# 临时设置（当前会话）
export GEMINI_API_KEY="您的新API_KEY"

# 永久设置（添加到 ~/.bashrc 或 ~/.zshrc）
echo 'export GEMINI_API_KEY="您的新API_KEY"' >> ~/.bashrc
source ~/.bashrc
```

3. 启动服务：
```bash
cd backend
python main.py
```

### 方法三：创建配置文件（最佳实践）

1. 创建 `.env` 文件：
```bash
# 在backend目录创建.env文件
cd backend
echo 'GEMINI_API_KEY=您的新API_KEY' > .env
```

2. 修改 `backend/main.py` 使用 python-dotenv：
```python
from dotenv import load_dotenv
import os

# 加载环境变量
load_dotenv()

# 从环境变量读取
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
```

3. 安装 python-dotenv（如果未安装）：
```bash
pip install python-dotenv
```

## 验证替换

替换API Key后，运行以下命令验证：

```bash
# 测试API健康状态
curl http://localhost:8000/api/health

# 测试提示词生成
curl -X POST http://localhost:8000/api/variants/generate \
  -H "Content-Type: application/json" \
  -d '{
    "base_prompt": "test",
    "dimensions": ["场景"],
    "count": 1
  }'
```

## 注意事项

1. **API Key 安全**：
   - 不要将真实的API Key提交到Git
   - 使用环境变量或.env文件
   - 确保.env在.gitignore中

2. **API 限制**：
   - 免费API Key有调用次数限制
   - 建议申请付费API以获得更高配额

3. **同一个Key**：
   - 当前项目中，Gemini和Imagen使用同一个API Key
   - 这是Google AI Studio的统一认证方式

## 获取新的API Key

1. 访问 [Google AI Studio](https://aistudio.google.com/)
2. 登录Google账号
3. 点击 "Get API Key"
4. 创建新项目或选择现有项目
5. 复制生成的API Key

---
更新时间：2025年8月10日