import sys
import os

# ==========================================================================
# تعيين الوضع المحلي لمنع محاولة الاتصال بالإنترنت عند تحميل النماذج
# هذا يضمن أن النظام يعمل بشكل كامل دون اتصال بالإنترنت
# ==========================================================================
os.environ['HF_HUB_OFFLINE'] = '1'
os.environ['TRANSFORMERS_OFFLINE'] = '1'

import grpc
import chromadb
from sentence_transformers import SentenceTransformer
import streamlit as st
import asyncio
from typing import List, Dict, Generator, Optional

# إضافة المسار الجذري للوصول لملفات البروتو في الروت
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

import rag_pb2 as pb2
import rag_pb2_grpc as pb2_grpc
from src.core.config import db_config, model_config, server_config, generation_config

class MedicalClient:
    def __init__(self):
        self.collection = None
        self.embed_model = None
        self._load_resources()

    def _load_resources(self):
        """تحميل الموارد (قاعدة البيانات + نموذج التضمين)"""
        try:
            # 1. الاتصال بقاعدة بيانات ChromaDB
            chroma_client = chromadb.PersistentClient(path=db_config.db_path)
            self.collection = chroma_client.get_collection(name=db_config.collection_name)
            
            # 2. تحميل نموذج التضمين (صغير وسريع على CPU)
            self.embed_model = SentenceTransformer(model_config.embedding_model, device=model_config.device)
            
        except Exception as e:
            st.error(f"فشل في تحميل الموارد المحلية: {e}")

    def retrieve_documents(self, query: str, n_results: int = 4) -> List[Dict[str, str]]:
        """البحث الدلالي عن المعلومات"""
        if not self.collection or not self.embed_model:
            return []
        
        try:
            query_vec = self.embed_model.encode([query]).tolist()
            results = self.collection.query(
                query_embeddings=query_vec,
                n_results=n_results
            )
            
            documents = []
            if results['documents']:
                for i, doc in enumerate(results['documents'][0]):
                    meta = results['metadatas'][0][i]
                    # Calculate simple confidence from distance (smaller is better, usually range 0-2 for cosine/l2)
                    # This is a heuristic approximation
                    distance = results['distances'][0][i] if 'distances' in results and results['distances'] else 0.5
                    confidence = max(0, min(100, int((1 - distance) * 100))) if distance < 1.0 else int(100/(distance+1))
                    
                    documents.append({
                        "question": meta.get('original_question', 'سؤال غير معروف'),
                        "answer": meta.get('answer', doc),
                        "confidence": confidence
                    })
            return documents
        except Exception as e:
            st.warning(f"خطأ أثناء البحث: {e}")
            return []

    async def generate_response(self, messages: List[Dict[str, str]]) -> Generator[str, None, None]:
        """الاتصال بالسيرفر للمحادثة"""
        try:
            async with grpc.aio.insecure_channel(server_config.address) as channel:
                stub = pb2_grpc.MedicalChatServiceStub(channel)
                
                # إعداد الرسائل
                proto_messages = [
                    pb2.Message(role=m['role'], content=m['content']) 
                    for m in messages
                ]
                
                request = pb2.ChatRequest(
                    session_id="ui-client",
                    messages=proto_messages,
                    config=pb2.GenerationConfig(
                        max_tokens=generation_config.max_tokens,
                        temperature=generation_config.temperature,
                        top_p=generation_config.top_p
                    )
                )
                
                async for response in stub.GenerateStream(request):
                    yield response.token
                    
        except grpc.RpcError as e:
            yield f"\n[خطأ اتصال]: {e.details()}"
        except Exception as e:
            yield f"\n[خطأ]: {e}"

# Singleton instance
# نستخدم تكنيك التخزين المؤقت لعدم إعادة التحميل مع كل تحديث للصفحة
@st.cache_resource
def get_client() -> MedicalClient:
    return MedicalClient()
