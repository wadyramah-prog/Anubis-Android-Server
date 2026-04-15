# 👁️ عين أنوبيس — Android NVR Server
## تحويل أي هاتف Android إلى سيرفر NVR كامل

---

## 🎯 الفكرة

هاتف Android قديم = **سيرفر NVR متنقل**:
- في السيارة 🚗
- في الخيمة ⛺
- في أي مكان متنقل 🌍

---

## 📋 المتطلبات

### الهاتف
| المواصفة | الحد الأدنى | الموصى به |
|---|---|---|
| Android | 8.0+ | 10+ |
| RAM | 2GB | 4GB+ |
| Storage | 16GB | 64GB+ |
| CPU | Snapdragon 625+ | 845+ |
| الكاميرات | 1-2 | 2-4 |

### للبناء (Build Machine)
- Android Studio Hedgehog 2023.1.1+
- JDK 17+
- Android NDK 26.1
- اتصال إنترنت (تحميل dependencies)

---

## 🔨 كيفية بناء الـ APK

### الطريقة 1 — Android Studio (الأسهل)

```bash
# 1. افتح Android Studio
# 2. File → Open → اختر مجلد anubis-android
# 3. انتظر Gradle sync (5-10 دقائق)
# 4. Build → Generate Signed Bundle/APK
# 5. اختر APK
# 6. Create new keystore (للتوقيع)
# 7. Build → انتظر → APK جاهز
```

### الطريقة 2 — Command Line

```bash
# التثبيت المطلوب
sudo apt install openjdk-17-jdk -y

# إعداد Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Build debug APK (للتطوير)
cd anubis-android
./gradlew assembleDebug

# APK: app/build/outputs/apk/debug/app-debug.apk

# Build release APK (للإنتاج)
./gradlew assembleRelease

# APK: app/build/outputs/apk/release/app-release-unsigned.apk
```

### الطريقة 3 — GitHub Actions (تلقائي)

```yaml
# .github/workflows/build.yml
name: Build Anubis Android APK
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '17', distribution: 'temurin' }
      - name: Build APK
        run: cd anubis-android && ./gradlew assembleRelease
      - uses: actions/upload-artifact@v4
        with:
          name: AnubisNVR-APK
          path: anubis-android/app/build/outputs/apk/release/*.apk
```

---

## 📱 تثبيت الـ APK

```bash
# 1. فعّل Developer Options على الهاتف
#    Settings → About Phone → اضغط Build Number 7 مرات

# 2. فعّل USB Debugging

# 3. ثبّت via ADB
adb install app-debug.apk

# أو: انقل الـ APK للهاتف وثبّته مباشرة
# (يحتاج تفعيل "Install from unknown sources")
```

---

## 🚀 أول تشغيل

1. افتح التطبيق "عين أنوبيس NVR"
2. اضغط **▶ Start Server**
3. اقبل جميع الصلاحيات
4. ستظهر رسالة: `🌐 http://192.168.1.x:8080`
5. افتح هذا الرابط من أي متصفح على نفس الشبكة

---

## 📷 إضافة كاميرات

### من داخل التطبيق:
```
اضغط "كاميرات" → "+" → أدخل بيانات الكاميرا
```

### أو من Web UI:
```
http://192.168.1.x:8080
→ Cameras → Add Camera
→ RTSP URL: rtsp://192.168.1.100/stream1
```

### استخدام كاميرا الهاتف نفسه:
```
Source: Phone Camera (Front/Back)
← يحوّل كاميرا الهاتف لكاميرا NVR مباشرة!
```

---

## 💾 خيارات التخزين

| الخيار | الكمية | الكيفية |
|---|---|---|
| Internal | بحسب storage الهاتف | تلقائي |
| SD Card | بحسب البطاقة | تلقائي |
| USB OTG | أي حجم | اختر المجلد |
| Google Drive | 15GB مجاني | TODO: الجلسة القادمة |

### اختيار مجلد التخزين:
```
Settings → Storage → Choose Folder
← يفتح Android folder picker
← اختر أي مجلد على SD/USB/Google Drive
```

---

## 🌐 الـ Web UI على المتصفح

```
الرابط: http://هاتف-IP:8080

ستجد:
  ✅ صفحة المراقبة المباشرة (Live View)
  ✅ إدارة الكاميرات
  ✅ التسجيلات
  ✅ أحداث الذكاء الاصطناعي
  ✅ إعدادات النظام
```

---

## ⚡ حدود الأداء

| الجهاز | كاميرات RTSP | الدقة | AI |
|---|---|---|---|
| Samsung A52 (2021) | 2 | 720p | ✅ 15fps |
| Samsung S21 (2021) | 4 | 1080p | ✅ 25fps |
| Xiaomi 11 (2021) | 4 | 1080p | ✅ |
| Pixel 6 (2021) | 4 | 1080p | ✅ GPU |
| Old phone (2018) | 1-2 | 720p | ⚠️ CPU only |
| Android TV Box | 4-8 | 1080p | ✅ |

---

## 🔋 إدارة البطارية

الهاتف يعمل كـ 24/7 server — **يجب توصيله بالشاحن دائماً**

إعدادات موصى بها:
```
Settings → Battery → الهاتف → Unrestricted (لا حدود)
Settings → Developer Options → Stay Awake → On
```

---

## 🌡️ الحرارة

الهاتف سيسخن عند تشغيل 24/7:
- **الحل 1:** مروحة تبريد خارجية USB
- **الحل 2:** Thermal throttling تلقائي (النظام يقلل FPS عند 85°C)
- **الحل 3:** Android TV Box (أكثر برودة من الهاتف)

---

## 📡 الوصول من الإنترنت

### الطريقة 1 — Port Forwarding
```
Router → Port Forward:
  External: 8080 → Internal: phone-ip:8080
```

### الطريقة 2 — Tailscale (VPN بدون Port Forwarding)
```bash
# ثبّت Tailscale على الهاتف والكمبيوتر
# الهاتف يظهر على الشبكة الخاصة
# الوصول: http://100.x.x.x:8080
```

### الطريقة 3 — Cloudflare Tunnel
```bash
cloudflared tunnel --url http://localhost:8080
# يعطيك URL عام مثل: https://anubis-xxx.trycloudflare.com
```

---

## 🗺️ الجلسات القادمة

| الجلسة | المحتوى |
|---|---|
| **7** | Cloud Storage (Google Drive/OneDrive) + Telegram الإشعارات |
| **8** | Build Script تلقائي + Sign APK + Final Release |
| **→ APK** | **الـ APK الكامل جاهز للتنزيل** |

---

## 🏗️ بنية المشروع

```
anubis-android/
├── app/
│   └── src/main/
│       ├── java/com/anubis/nvr/
│       │   ├── service/
│       │   │   ├── NvrServerService.kt   ← قلب النظام
│       │   │   ├── NvrWebServer.kt       ← HTTP Server
│       │   │   └── BootReceiver.kt       ← تشغيل عند الإقلاع
│       │   ├── camera/
│       │   │   └── CameraManager.kt      ← RTSP + كاميرا الهاتف
│       │   ├── storage/
│       │   │   └── StorageManager.kt     ← Internal/SD/USB/Cloud
│       │   ├── ai/
│       │   │   └── AiEngine.kt           ← TFLite YOLOv10-nano
│       │   ├── ui/
│       │   │   └── MainActivity.kt       ← Jetpack Compose UI
│       │   └── utils/
│       │       └── Utils.kt              ← Config + Network
│       ├── res/
│       │   ├── drawable/                 ← الأيقونات
│       │   ├── values/                   ← النصوص والألوان
│       │   └── xml/                      ← FileProvider paths
│       └── AndroidManifest.xml
├── build.gradle                          ← Dependencies
├── settings.gradle
└── README.md                             ← هذا الملف
```
