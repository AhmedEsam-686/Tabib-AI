import 'dart:developer' as developer;
import 'package:grpc/grpc.dart';

/// [GrpcConnection]
/// كلاس بتصميم Singleton لإدارة قناة الاتصال ببروتوكول gRPC.
/// يضمن هذا الكلاس وجود قناة اتصال واحدة فقط مفتوحة طوال حياة التطبيق.
class GrpcConnection {
  // 1. Singleton Pattern
  static final GrpcConnection _instance = GrpcConnection._internal();

  factory GrpcConnection() => _instance;

  GrpcConnection._internal();

  // 2. المتغيرات
  ClientChannel? _channel;

  /// للتحقق مما إذا كان الاتصال مهيأً أم لا
  bool get isInitialized => _channel != null;

  /// الوصول للقناة الحالية لاستخدامها في الـ Services
  /// يرمي خطأ إذا تم استدعاؤه قبل التهيئة
  ClientChannel get channel {
    if (_channel == null) {
      throw Exception(
          'gRPC Channel is not initialized. Call initConnection() first.');
    }
    return _channel!;
  }

  /// 3. دالة التهيئة (Initialization)
  /// [host]: عنوان السيرفر (مثلاً 0.tcp.ngrok.io)
  /// [port]: رقم المنفذ (مثلاً 12345)
  void initConnection({required String host, required int port}) {
    // إذا كانت القناة مفتوحة مسبقاً، لا تقم بإعادة الفتح إلا إذا أردت إغلاق القديمة
    if (_channel != null) return;

    developer.log('🔄 Connecting to gRPC Server: $host:$port', name: 'GrpcConnection');

    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        // بما أننا نستخدم نفق Ngrok TCP، نستخدم اتصال غير مشفر (Insecure)
        // لأن التشفير يتم عبر النفق نفسه، ولا نملك شهادة SSL مباشرة للرابط المؤقت
        credentials: ChannelCredentials.insecure(),

        // إعدادات KeepAlive مهمة جداً للهواتف لضمان عدم قطع الاتصال
        // إذا كان التطبيق في الخلفية لفترة قصيرة
        keepAlive: ClientKeepAliveOptions(
          pingInterval: Duration(seconds: 30), // إرسال نبضة كل 30 ثانية
          timeout: Duration(seconds: 10),      // انتظار الرد لمدة 10 ثواني
          permitWithoutCalls: true,            // السماح بالنبض حتى لو لم تكن هناك رسائل
        ),
      ),
    );
  }

  /// 4. إغلاق الاتصال (Cleanup)
  /// يفضل استدعاؤها عند إغلاق التطبيق تماماً (نادراً ما يحدث في الهواتف)
  Future<void> shutdown() async {
    if (_channel != null) {
      developer.log('🛑 Shutting down gRPC Channel', name: 'GrpcConnection');
      await _channel!.shutdown();
      _channel = null;
    }
  }
}