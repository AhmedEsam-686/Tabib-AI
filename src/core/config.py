import os
from pathlib import Path
from dataclasses import dataclass

# تحديد المسار الجذري للمشروع (المجلد الذي يحتوي على src)
PROJECT_ROOT = Path(__file__).parent.parent.parent.absolute()

@dataclass
class AppConfig:
    page_title: str = "المساعد الطبي الذكي"
    page_icon: str = "🩺"
    layout: str = "wide"
    initial_sidebar_state: str = "expanded"

@dataclass
class ModelConfig:
    # المسار النسبي للنموذج من جذر المشروع
    model_path: str = "Qwen3-4B-Thinking-2507-FP8"
    # استخدام المسار المحلي المباشر لضمان العمل بدون إنترنت
    embedding_model: str = "/home/ahmed/.cache/huggingface/hub/models--sentence-transformers--paraphrase-multilingual-MiniLM-L12-v2/snapshots/86741b4e3f5cb7765a600d3a3d55a0f6a6cb443d"
    device: str = "cpu"  # للاستنتاج البسيط في الكلاينت

@dataclass
class ServerConfig:
    host: str = "localhost"
    port: str = "50052"
    
    @property
    def address(self) -> str:
        return f"{self.host}:{self.port}"

@dataclass
class DatabaseConfig:
    # المسار النسبي لقاعدة البيانات
    db_relative_path: str = "chroma_db_storage"
    collection_name: str = "medical_knowledge_base"
    
    @property
    def db_path(self) -> str:
        return str(PROJECT_ROOT / self.db_relative_path)

@dataclass
class GenerationConfigDefaults:
    """إعدادات التوليد الافتراضية للنموذج"""
    max_tokens: int = 8192
    temperature: float = 0.7
    top_p: float = 0.8

# تهيئة الإعدادات
app_config = AppConfig()
model_config = ModelConfig()
server_config = ServerConfig()
db_config = DatabaseConfig()
generation_config = GenerationConfigDefaults()

# التأكد من صحة المسارات
def validate_paths():
    if not os.path.exists(db_config.db_path):
        print(f"Warning: Database path does not exist at {db_config.db_path}")
    
    model_full_path = PROJECT_ROOT / model_config.model_path
    if not os.path.exists(model_full_path):
        print(f"Warning: Model path does not exist at {model_full_path}")
