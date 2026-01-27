import streamlit as st

def load_css(file_path: str):
    """تحميل ملف CSS"""
    with open(file_path, "r") as f:
        st.markdown(f"<style>{f.read()}</style>", unsafe_allow_html=True)

def render_header():
    """عرض ترويسة الصفحة"""
    st.markdown("""
        <div style="text-align: center; margin-bottom: 2rem;">
            <h1 style="margin-bottom: 0;">🩺 المساعد الطبي الذكي</h1>
            <p style="color: #64748b; font-size: 1.1rem;">نظام ذكي للإجابة على الاستفسارات الطبية بدقة</p>
        </div>
    """, unsafe_allow_html=True)

def render_source_card(index: int, question: str, answer: str, confidence: int = 0):
    """عرض بطاقة مصدر مع مؤشر الثقة"""
    
    # تحديد اللون بناءً على الثقة
    if confidence >= 80:
        badge_color = "#10b981" # Green
        badge_text = "عالية"
    elif confidence >= 50:
        badge_color = "#f59e0b" # Orange
        badge_text = "متوسطة"
    else:
        badge_color = "#ef4444" # Red
        badge_text = "منخفضة"

    html = f"""
    <div class="source-card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;">
            <div class="source-title" style="margin-bottom: 0;">💡 معلومة داعمة #{index}</div>
            <span style="background-color: {badge_color}; color: white; padding: 2px 10px; border-radius: 999px; font-size: 0.75rem; font-weight: bold;">
                ثقة {badge_text} ({confidence}%)
            </span>
        </div>
        <div class="source-content">
            <div style="margin-bottom: 4px;"><strong>س:</strong> {question}</div>
            <div><strong>ج:</strong> {answer}</div>
        </div>
    </div>
    """
    st.markdown(html, unsafe_allow_html=True)

def render_chat_msg(role: str, content: str, avatar: str = None):
    """دالة مساعدة لعرض الرسائل (تستخدم الآن Streamlit native لكن يمكن تخصيصها مستقبلاً)"""
    with st.chat_message(role, avatar=avatar):
        st.markdown(content)

def render_thinking_process(placeholder, content: str, is_finished: bool):
    """عرض عملية التفكير"""
    # لا نقوم بشيء هنا لأننا نستخدم st.status في اللوجيك الرئيسي
    # لكن يمكن استخدام هذه الدالة لتنسيق النص الداخلي
    pass
