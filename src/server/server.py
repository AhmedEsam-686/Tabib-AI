import asyncio
import logging
import os
import uuid
import sys
from typing import AsyncGenerator, List, Dict

# التأكد من رؤية الباكيجات في الروت
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

import grpc
from vllm import AsyncLLMEngine, AsyncEngineArgs, SamplingParams

import rag_pb2 as pb2
import rag_pb2_grpc as pb2_grpc
from src.core.config import model_config, server_config, PROJECT_ROOT

# ==============================================================================
# إعدادات السيرفر والنموذج
# ==============================================================================
# نستخدم المسار الكامل من الكونفق لضمان عدم وجود مشاكل في المسارات النسبية للـ vllm
MODEL_PATH = str(PROJECT_ROOT / model_config.model_path)
GRPC_PORT = server_config.port

# إعداد السجلات (Logging)
logging.basicConfig(level=logging.INFO, format='%(asctime)s [SERVER] %(message)s')
logger = logging.getLogger(__name__)

# ==============================================================================
# 1. المحرك الذكي (The Brain: vLLM Engine)
# ==============================================================================
class IntelligentEngine:
    """
    محرك vLLM مدمج ومحسن لنماذج Qwen مع خاصية التفكير.
    (تم الحفاظ على الكود كما هو بناءً على طلبك)
    """
    def __init__(self, model_path: str):
        self.model_path = model_path
        self.engine = None
        self.tokenizer = None
        self.think_start_token = "<think>"
        self.think_end_token = "</think>"

    async def initialize(self):
        logger.info(f"🚀 جاري تحميل النموذج: {self.model_path}")
        logger.info("⚙️  يتم استخدام تسريع vLLM مع FP8...")
        
        engine_args = AsyncEngineArgs(
            model=self.model_path,
            quantization="fp8",
            max_model_len=8192,
            gpu_memory_utilization=0.90,
            tensor_parallel_size=1,
            enforce_eager=False,
            trust_remote_code=True,
            disable_log_stats=True
        )

        try:
            self.engine = AsyncLLMEngine.from_engine_args(engine_args)
            from transformers import AutoTokenizer
            self.tokenizer = AutoTokenizer.from_pretrained(self.model_path, trust_remote_code=True)
            logger.info("✅ تم تحميل المحرك بنجاح وجاهز للعمل.")
        except Exception as e:
            logger.critical(f"🔥 فشل تحميل النموذج: {e}")
            raise

    async def generate_stream(self, messages: List[Dict[str, str]], request_id: str, **kwargs) -> AsyncGenerator[str, None]:
        sampling_params = SamplingParams(
            temperature=kwargs.get("temperature", 0.7),
            max_tokens=kwargs.get("max_tokens", 4096),
            top_p=kwargs.get("top_p", 0.8),
            # repetition_penalty=1.1, 
        )

        prompt = self.tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        results_generator = self.engine.generate(prompt, sampling_params, request_id)

        previous_text = ""
        async for request_output in results_generator:
            output = request_output.outputs[0]
            current_text = output.text
            new_chunk = current_text[len(previous_text):]
            previous_text = current_text
            if new_chunk:
                yield new_chunk

# ==============================================================================
# 2. معالج الطلبات (The Handler: gRPC Logic)
# ==============================================================================
class MedicalChatHandler(pb2_grpc.MedicalChatServiceServicer):
    def __init__(self, engine: IntelligentEngine):
        self.engine = engine

    async def GenerateStream(self, request, context):
        request_id = request.session_id if request.session_id else str(uuid.uuid4())
        chat_history = [{"role": msg.role, "content": msg.content} for msg in request.messages]
            
        # استيراد الإعدادات الافتراضية
        from src.core.config import generation_config
        
        gen_kwargs = {
            "max_tokens": request.config.max_tokens if request.config.max_tokens > 0 else generation_config.max_tokens,
            "temperature": request.config.temperature if request.config.temperature > 0 else generation_config.temperature,
            "top_p": request.config.top_p if request.config.top_p > 0 else generation_config.top_p,
        }

        logger.info(f"📩 طلب جديد [{request_id}] - {len(chat_history)} رسالة")

        try:
            async for token in self.engine.generate_stream(chat_history, request_id, **gen_kwargs):
                yield pb2.ChatResponse(token=token, is_finished=False)
            yield pb2.ChatResponse(is_finished=True)

        except Exception as e:
            logger.error(f"❌ خطأ: {e}")
            await context.abort(grpc.StatusCode.INTERNAL, str(e))

# ==============================================================================
# 3. تشغيل السيرفر
# ==============================================================================
async def serve():
    logger.info("--- بدء تشغيل سيرفر RAG الطبي (Refactored) ---")
    engine = IntelligentEngine(model_path=MODEL_PATH)
    await engine.initialize()

    server = grpc.aio.server()
    pb2_grpc.add_MedicalChatServiceServicer_to_server(MedicalChatHandler(engine), server)
    
    listen_addr = f'[::]:{GRPC_PORT}'
    server.add_insecure_port(listen_addr)
    
    logger.info(f"🎧 السيرفر يستمع الآن على المنفذ: {listen_addr}")
    await server.start()
    await server.wait_for_termination()

if __name__ == "__main__":
    try:
        asyncio.run(serve())
    except KeyboardInterrupt:
        logger.info("🛑 تم إيقاف السيرفر.")
