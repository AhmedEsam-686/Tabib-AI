import asyncio
import logging
import os
import sys
import time
from typing import AsyncGenerator

# إضافة المجلد الرئيسي للمشروع إلى المسار لاستيراد ملفات البروتو
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

import grpc
import rag_pb2 as pb2
import rag_pb2_grpc as pb2_grpc

# إعداد السجلات
logging.basicConfig(level=logging.INFO, format='%(asctime)s [MOCK SERVER] %(message)s')
logger = logging.getLogger(__name__)

# الإعدادات
PORT = 50052

class MockMedicalChatHandler(pb2_grpc.MedicalChatServiceServicer):
    """
    محاكي لخدمة الشات الطبي.
    """
    async def GenerateStream(self, request, context):
        """
        يستقبل الطلب ويرد بنص ثابت ومحاكي للتدفق (Streaming).
        """
        request_id = request.session_id if request.session_id else "unknown_session"
        user_message = request.messages[-1].content if request.messages else ""
        
        logger.info(f"📩 استلام طلب وهمي [{request_id}] - الرسالة: {user_message[:30]}...")

        # نص الرد الوهم