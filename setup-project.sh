#!/usr/bin/env bash
# ============================================================
# setup-project.sh — تجهيز مشروع WiFi Usage Tester من ملف ZIP
# يعمل على: Termux / Linux / GitHub Actions (ubuntu-latest)
# الاستخدام:  chmod +x setup-project.sh && ./setup-project.sh
# أو مع مسار مخصص:  ./setup-project.sh /path/to/wifi-usage-project.zip
# ============================================================
set -euo pipefail

ZIP_NAME="${1:-wifi-usage-project.zip}"
PROJECT_DIR="wifi-usage-project"

echo "=============================================="
echo "  WiFi Usage Tester — تجهيز المشروع"
echo "=============================================="

# --- 1) التأكد من وجود ملف ZIP ---
if [ ! -f "$ZIP_NAME" ]; then
    echo "❌ خطأ: لم يتم العثور على الملف: $ZIP_NAME"
    echo "   ضع الملف في نفس المجلد الحالي أو مرّر مساره كمعامل."
    exit 1
fi
echo "✅ تم العثور على: $ZIP_NAME"

# --- 2) فك الضغط في مجلد مؤقت ثم نقل المحتويات ---
command -v unzip >/dev/null 2>&1 || { echo "❌ unzip غير مثبت. ثبّته: pkg install unzip (Termux) أو apt install unzip (Linux)"; exit 1; }

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
unzip -q -o "$ZIP_NAME" -d "$TMP_DIR"
echo "✅ تم فك الضغط"

# --- 3) معالجة مجلد داخلي محتمل (إذا كان ZIP يحتوي مجلدًا واحدًا أعلى الملفات) ---
INNER="$TMP_DIR"
first_dir="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
total_top="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 | wc -l)"
if [ "$total_top" -eq 1 ] && [ -n "$first_dir" ]; then
    INNER="$first_dir"
    echo "ℹ️  الملف يحتوي على مجلد داخلي: $(basename "$INNER") — سيتم استخدام محتوياته"
fi

# --- 4) نسخ المشروع إلى مجلده النهائي ---
mkdir -p "$PROJECT_DIR"
cp -r "$INNER"/. "$PROJECT_DIR"/
echo "✅ تم نسخ المشروع إلى: $PROJECT_DIR/"

# --- 5) التحقق من الملفات الأساسية ---
REQUIRED=(
    "settings.gradle.kts"
    "build.gradle.kts"
    "gradle.properties"
    "app/build.gradle.kts"
    "app/src/main/AndroidManifest.xml"
    "app/src/main/java/com/wifiusagetester/app/MainActivity.kt"
    "app/src/main/res/layout/activity_main.xml"
    "app/src/main/res/values/strings.xml"
    "app/src/main/res/values/themes.xml"
    ".github/workflows/build.yml"
)
MISSING=0
for f in "${REQUIRED[@]}"; do
    if [ -f "$PROJECT_DIR/$f" ]; then
        echo "   ✅ $f"
    else
        echo "   ❌ ناقص: $f"
        MISSING=1
    fi
done
if [ "$MISSING" -eq 1 ]; then
    echo "❌ توجد ملفات ناقصة — المشروع غير جاهز. أعد تنزيل ZIP."
    exit 1
fi
echo "✅ جميع الملفات الأساسية موجودة"

# --- 6) gradlew إن وُجد ---
if [ -f "$PROJECT_DIR/gradlew" ]; then
    chmod +x "$PROJECT_DIR/gradlew"
    echo "✅ gradlew أصبح قابلًا للتنفيذ"
else
    echo "ℹ️  لا يوجد Gradle Wrapper — البناء يتم عبر GitHub Actions (Gradle يُثبّت في الـ workflow)."
fi

echo "=============================================="
echo "  ✅ المشروع جاهز في: $PROJECT_DIR/"
echo "=============================================="
echo ""
echo "الخطوات التالية:"
echo "  1) ادخل للمجلد:        cd $PROJECT_DIR"
echo "  2) ارفع إلى GitHub (من Termux):"
echo "       git init && git add . && git commit -m 'Phase 1'"
echo "       gh repo create wifi-usage-tester --private --source=. --push"
echo "  3) بعد الـ push سيبني GitHub Actions الـ APK تلقائيًا."
echo "  4) حمّل APK من: تبويب Actions ← آخر run ← Artifacts ← wifi-usage-tester-debug"
echo ""
echo "ملاحظة: إذا كان Gradle مثبتًا محليًا يمكنك البناء بـ:"
echo "       gradle assembleDebug"
echo "       (الـ APK الناتج: app/build/outputs/apk/debug/)"
