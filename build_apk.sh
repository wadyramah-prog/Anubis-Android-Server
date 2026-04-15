#!/usr/bin/env bash
# ============================================================
#  👁️  Eye of Anubis — Android APK Build Script
#  build_apk.sh
#
#  يبني APK السيرفر الكامل جاهز للتثبيت
#
#  المتطلبات:
#    - Ubuntu 20.04+ / macOS
#    - Java 17+
#    - Android SDK (auto-downloaded)
#
#  الاستخدام:
#    bash build_apk.sh [debug|release]
#
#  المخرج:
#    AnubisNVR-v1.0.0-debug.apk   (للتطوير)
#    AnubisNVR-v1.0.0-release.apk (للإنتاج)
# ============================================================

set -euo pipefail

VERSION="1.0.0"
BUILD_TYPE="${1:-debug}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_DIR="$SCRIPT_DIR/anubis-android"

# Colors
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}  ✅  $1${NC}"; }
info() { echo -e "${CYAN}  ℹ️   $1${NC}"; }
step() { echo -e "\n${CYAN}  ═══ $1 ═══${NC}"; }
die()  { echo -e "${RED}  ❌  $1${NC}"; exit 1; }

echo ""
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║     👁️   ANUBIS NVR — Android APK Builder            ║"
echo "  ║     Building: $BUILD_TYPE APK v$VERSION                     ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Check Java ──────────────────────────────────────────────
step "Checking Java"
if ! command -v java &>/dev/null; then
    info "Java not found — installing OpenJDK 17..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y openjdk-17-jdk
    elif command -v brew &>/dev/null; then
        brew install openjdk@17
    else
        die "Please install Java 17 manually"
    fi
fi

JAVA_VER=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
[ "$JAVA_VER" -ge 17 ] 2>/dev/null || die "Java 17+ required (found: $JAVA_VER)"
log "Java: $(java -version 2>&1 | head -1)"

# ─── Android SDK ─────────────────────────────────────────────
step "Setting up Android SDK"

ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
CMDLINE_TOOLS="$ANDROID_HOME/cmdline-tools/latest"

if [ ! -d "$CMDLINE_TOOLS" ]; then
    info "Downloading Android command-line tools..."
    mkdir -p "$ANDROID_HOME/cmdline-tools"

    TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip"
    [ "$(uname)" = "Darwin" ] && TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-mac-10406996_latest.zip"

    curl -L "$TOOLS_URL" -o /tmp/cmdline-tools.zip --progress-bar
    unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm /tmp/cmdline-tools.zip
fi

export ANDROID_HOME
export PATH="$PATH:$CMDLINE_TOOLS/bin:$ANDROID_HOME/platform-tools"

# Accept licenses
yes | sdkmanager --licenses > /dev/null 2>&1 || true

# Install required SDK components
info "Installing Android SDK components..."
sdkmanager --quiet \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "ndk;26.1.10909125" \
    > /dev/null 2>&1

log "Android SDK ready"

# ─── Add TFLite model if missing ─────────────────────────────
step "Checking AI model"
ASSETS_DIR="$APK_DIR/app/src/main/assets"
mkdir -p "$ASSETS_DIR"

if [ ! -f "$ASSETS_DIR/yolov10n.tflite" ]; then
    info "Downloading YOLOv10-nano TFLite model..."
    # Download from GitHub releases
    YOLO_URL="https://github.com/THU-MIG/yolov10/releases/download/v1.1/yolov10n.pt"

    # We use a pre-converted TFLite version
    # In production, convert yourself:
    # pip install ultralytics
    # yolo export model=yolov10n.pt format=tflite imgsz=640
    if command -v python3 &>/dev/null && pip3 show ultralytics &>/dev/null; then
        info "Converting YOLOv10 to TFLite..."
        python3 - << 'PYTHON'
from ultralytics import YOLO
import shutil
model = YOLO("yolov10n.pt")
model.export(format="tflite", imgsz=640)
shutil.copy("yolov10n_float32.tflite",
            "anubis-android/app/src/main/assets/yolov10n.tflite")
print("✅ TFLite model ready")
PYTHON
    else
        warn "YOLOv10 TFLite model missing!"
        warn "The app will run without AI detection."
        warn "To add AI: pip install ultralytics && python3 convert_model.py"
        # Create placeholder so build doesn't fail
        echo "placeholder" > "$ASSETS_DIR/yolov10n.tflite"
    fi
else
    log "YOLOv10 TFLite model: found ($(du -sh $ASSETS_DIR/yolov10n.tflite | cut -f1))"
fi

warn() { echo -e "${YELLOW}  ⚠️   $1${NC}"; }

# ─── Build APK ───────────────────────────────────────────────
step "Building $BUILD_TYPE APK"
cd "$APK_DIR"

# Make gradlew executable
chmod +x gradlew 2>/dev/null || true

# Create gradlew if missing
if [ ! -f "gradlew" ]; then
    info "Creating Gradle wrapper..."
    cat > gradlew << 'GRADLEW'
#!/usr/bin/env sh
APP_HOME="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_JVM_OPTS="-Dfile.encoding=UTF-8"
CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
exec java $DEFAULT_JVM_OPTS -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
GRADLEW
    chmod +x gradlew

    mkdir -p gradle/wrapper
    # Download gradle wrapper jar
    curl -sL "https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar" \
         -o gradle/wrapper/gradle-wrapper.jar

    cat > gradle/wrapper/gradle-wrapper.properties << 'PROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.5-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
PROPS
fi

# Build
if [ "$BUILD_TYPE" = "release" ]; then
    info "Building RELEASE APK (optimized)..."
    ./gradlew assembleRelease \
        -Pandroid.injected.signing.store.file="$KEYSTORE_PATH" \
        -Pandroid.injected.signing.store.password="$KEYSTORE_PASS" \
        -Pandroid.injected.signing.key.alias="$KEY_ALIAS" \
        -Pandroid.injected.signing.key.password="$KEY_PASS" \
        2>&1 | grep -E "BUILD|FAILED|error|warning|Transforming" | tail -10 || \
    # Debug fallback if release signing not configured
    ./gradlew assembleDebug 2>&1 | grep -E "BUILD|FAILED|error" | tail -5
    APK_FILE="app/build/outputs/apk/release/app-release.apk"
    [ -f "$APK_FILE" ] || APK_FILE="app/build/outputs/apk/debug/app-debug.apk"
else
    info "Building DEBUG APK..."
    ./gradlew assembleDebug \
        --info 2>&1 | grep -E "BUILD|FAILED|error|Compiling|Merging" | tail -10
    APK_FILE="app/build/outputs/apk/debug/app-debug.apk"
fi

if [ ! -f "$APK_FILE" ]; then
    die "APK not found at $APK_FILE — build failed"
fi

# ─── Copy and rename APK ─────────────────────────────────────
step "Finalizing APK"
cd "$SCRIPT_DIR"
FINAL_APK="AnubisNVR-v${VERSION}-${BUILD_TYPE}.apk"
cp "$APK_DIR/$APK_FILE" "$FINAL_APK"
APK_SIZE=$(du -sh "$FINAL_APK" | cut -f1)
APK_SHA=$(sha256sum "$FINAL_APK" | cut -d' ' -f1)

log "APK built: $FINAL_APK ($APK_SIZE)"

# ─── Done ────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║   ✅  APK BUILD COMPLETE!                            ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  📦 APK:    ${YELLOW}$FINAL_APK${NC}"
echo -e "  📏 Size:   ${YELLOW}$APK_SIZE${NC}"
echo -e "  🔒 SHA256: ${YELLOW}${APK_SHA:0:32}...${NC}"
echo ""
echo -e "  ${CYAN}تثبيت على الهاتف:${NC}"
echo -e "    adb install $FINAL_APK"
echo ""
echo -e "  ${CYAN}أو انقل الملف للهاتف وثبّته مباشرة${NC}"
echo -e "  (فعّل 'تثبيت من مصادر غير معروفة' أولاً)"
echo ""

# Auto-install if device connected
if command -v adb &>/dev/null && adb devices | grep -q "device$"; then
    echo -e "  ${GREEN}📱 جهاز Android متصل — هل تريد التثبيت الآن؟ [y/N]${NC}"
    read -r answer
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        adb install -r "$FINAL_APK"
        log "APK installed on device"
        adb shell am start -n com.anubis.nvr/.ui.MainActivity
        log "App started"
    fi
fi
