# ==== Flutter ====
# Flutter dvigateli o'z ichida consumer-proguard qoidalarini olib keladi,
# lekin xavfsizlik uchun qo'shimcha saqlaymiz.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**.* { *; }
-keep class io.flutter.util.**.* { *; }
-keep class io.flutter.view.**.* { *; }
-keep class io.flutter.**.* { *; }
-keep class io.flutter.plugins.**.* { *; }
-dontwarn io.flutter.embedding.**

# ==== Firebase / Google Play Services ====
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ==== Native (JNI) metodlar — masalan sqlite3 kutubxonasi ====
-keepclasseswithmembernames class * {
    native <methods>;
}

# ==== Parcelable / Serializable ====
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ==== Annotatsiyalarni saqlash (ko'p kutubxonalar shunga tayanadi) ====
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# ==== flutter_local_notifications (Gson bilan saqlanadigan rejalar) ====
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
