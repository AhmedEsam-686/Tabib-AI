import os
import sys
import subprocess

def main():
    """
    سكريبت بسيط لتشغيل واجهة المستخدم الجديدة.
    """
    print("🚀 جاري تشغيل المساعد الطبي الذكي (النسخة المحسنة)...")
    
    # مسار الملف الرئيسي الجديد
    app_path = "src/ui/main.py"
    
    if not os.path.exists(app_path):
        print(f"❌ خطأ: لم يتم العثور على الملف {app_path}")
        return

    # تشغيل Streamlit
    try:
        subprocess.run(["streamlit", "run", app_path], check=True)
    except KeyboardInterrupt:
        print("\n👋 وداعاً!")

if __name__ == "__main__":
    main()
