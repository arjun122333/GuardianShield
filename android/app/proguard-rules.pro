# Guardian Shield R8 Security Firewall & Obfuscation Rules

# Flutter Obfuscation & Security
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }

# Razorpay Payment Gateway Security & Anti-Tampering
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Prevent Class Name Reverse-Engineering
-repackageclasses ''
-allowaccessmodification

# Strict Native MainActivity Preservation
-keep class com.guardianshield.app.MainActivity { *; }

# Disable Debug Logging in Production Release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
