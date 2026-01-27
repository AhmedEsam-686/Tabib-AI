import streamlit as st
import asyncio
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))

from src.core.config import app_config
from src.core.client import get_client
import src.ui.components as components

# ==========================================================================
# 1. إعداد الصفحة
# ==========================================================================
st.set_page_config(
    page_title=app_config.page_title,
    page_icon=app_config.page_icon,
    layout=app_config.layout,
    initial_sidebar_state=app_config.initial_sidebar_state
)

# ==========================================================================
# 2. إدارة الثيمات (Themes Management)
# ==========================================================================
def inject_theme():
    """حقن متغيرات CSS بناءً على اختيار المستخدم"""
    if "theme" not in st.session_state:
        st.session_state.theme = "dark" # الافتراضي داكن بناءً على طلب المستخدم

    # تعريف الألوان لكل وضع
    themes = {
        "light": """
            :root {
                --bg-main: #e2e8f0;         /* Slate 200 - رمادي فضي مريح (بدل الأبيض الساطع) */
                --bg-sidebar: #f8fafc;      /* Slate 50 - فاتح جداً */
                --text-primary: #1e293b;    /* Slate 800 - داكن للقراءة */
                --text-secondary: #475569;  /* Slate 600 */
                --card-bg: #ffffff;         /* أبيض نقي للبروز */
                --border-color: #cbd5e1;    /* Slate 300 */
                --primary-color: #0891b2;   /* Cyan 600 */
                --secondary-color: #0e7490; /* Cyan 700 */
                --msg-user-bg: #cffafe;     /* Cyan 100 */
                --msg-user-border: #a5f3fc; /* Cyan 200 */
                --msg-bot-bg: #ffffff;
            }
        """,
        "dark": """
            :root {
                --bg-main: #0f172a;        /* Slate 900 */
                --bg-sidebar: #1e293b;      /* Slate 800 */
                --text-primary: #f1f5f9;    /* Slate 100 */
                --text-secondary: #94a3b8;  /* Slate 400 */
                --card-bg: #1e293b;         /* Slate 800 */
                --border-color: #334155;    /* Slate 700 */
                --primary-color: #38bdf8;   /* Sky 400 */
                --secondary-color: #7dd3fc; /* Sky 300 */
                --msg-user-bg: #1e293b;     /* Slate 800 */
                --msg-user-border: #334155; /* Slate 700 */
                --msg-bot-bg: #0f172a;      /* Slate 900 */
            }
        """
    }

    # تحميل الستايل الأساسي
    css_path = os.path.join(os.path.dirname(__file__), "styles.css")
    with open(css_path, "r") as f:
        base_css = f.read()

    # دمج متغيرات الألوان مع الستايل الأساسي
    chosen_theme = themes[st.session_state.theme]
    full_css = f"<style>{chosen_theme}\n{base_css}</style>"
    st.markdown(full_css, unsafe_allow_html=True)

inject_theme()

# ==========================================================================
# 3. المنطق الرئيسي
# ==========================================================================
def main():
    # --- الشريط الجانبي ---
    with st.sidebar:
        st.header("⚙️ الإعدادات")
        
        # زر تبديل الثيم
        theme_label = "🌙 الوضع الليلي" if st.session_state.theme == "light" else "☀️ الوضع النهاري"
        if st.button(theme_label, use_container_width=True):
            st.session_state.theme = "dark" if st.session_state.theme == "light" else "light"
            st.rerun()
            
        st.divider()
        
        # زر محادثة جديدة
        if st.button("🗑️ محادثة جديدة", type="primary", use_container_width=True):
            st.session_state.messages = []
            st.rerun()

        st.divider()
        st.caption("v.2.1 | Medical AI Assistant")

    # --- الترويسة ---
    components.render_header()

    # --- تهيئة المحادثة ---
    if "messages" not in st.session_state:
        st.session_state.messages = [
            {"role": "assistant", "content": "أهلاً بك 🩺. أنا مساعدك الطبي الذكي. اسألني عن التشخيصات، الأدوية، أو الأعراض."}
        ]

    # --- عرض الرسائل ---
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])

    # --- الإدخال ---
    if prompt := st.chat_input("اكتب سؤالك الطبي هنا..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)

        with st.chat_message("assistant"):
            process_response(prompt)

def process_response(user_query: str):
    client = get_client()
    
    # 1. البحث
    with st.status("🔍 جاري تحليل المصادر الطبية...", expanded=False) as status:
        documents = client.retrieve_documents(user_query, n_results=4)
        if documents:
            status.update(label="✅ تم العثور على مراجع موثوقة", state="complete")
            st.write("---")
            for i, doc in enumerate(documents, 1):
                components.render_source_card(i, doc['question'], doc['answer'], doc.get('confidence', 0))
            context_str = "\n".join([f"- س: {d['question']}\n  ج: {d['answer']}" for d in documents])
        else:
            status.update(label="⚠️ يتم الإجابة بناءً على المعرفة العامة", state="complete")
            context_str = "لا توجد مصادر محددة."

    # 2. التجهيز
    # 2. التجهيز
    from src.core.prompts import MEDICAL_AGENT_SYSTEM_PROMPT, format_rag_prompt
    from src.core.config import generation_config
    
    rag_prompt = format_rag_prompt(user_query, context_str)
    
    current_messages = [
        {"role": "system", "content": MEDICAL_AGENT_SYSTEM_PROMPT},
        {"role": "user", "content": rag_prompt}
    ]

    # 3. البث
    run_stream_ui(client, current_messages)

def run_stream_ui(client, messages):
    thought_expander = st.status("🧠 التفكير السريري...", expanded=True)
    thought_placeholder = thought_expander.empty()
    answer_placeholder = st.empty()
    
    full_text = ""
    thinking_text = ""
    answer_text = ""
    is_thinking_mode = True
    
    async def stream():
        nonlocal full_text, thinking_text, answer_text, is_thinking_mode
        async for chunk in client.generate_response(messages):
            full_text += chunk
            if is_thinking_mode:
                if "</think>" in full_text:
                    is_thinking_mode = False
                    parts = full_text.split("</think>")
                    thinking_text = parts[0].replace("<think>", "").strip()
                    thought_placeholder.markdown(thinking_text)
                    thought_expander.update(label="✅ التشخيص والتحليل", state="complete", expanded=False)
                    answer_text = parts[-1]
                    answer_placeholder.markdown(answer_text + "▌")
                else:
                    display = full_text.replace("<think>", "")
                    thought_placeholder.markdown(display + "▌")
            else:
                parts = full_text.split("</think>")
                answer_text = parts[-1]
                answer_placeholder.markdown(answer_text + "▌")

    try:
        asyncio.run(stream())
        answer_placeholder.markdown(answer_text)
        if is_thinking_mode: 
             thought_expander.update(label="اكتمل", state="complete")
             answer_placeholder.markdown(full_text.replace("<think>", ""))
             answer_text = full_text
        st.session_state.messages.append({"role": "assistant", "content": answer_text})
    except Exception as e:
        st.error(f"خطأ: {e}")

if __name__ == "__main__":
    main()
