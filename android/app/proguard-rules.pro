# Keep Google Play Services Credentials API classes
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep interface com.google.android.gms.auth.api.credentials.** { *; }
-keepclassmembers class com.google.android.gms.auth.api.credentials.** { *; }

# Keep Razorpay classes
-keep class com.razorpay.** { *; }
-keepclassmembers class com.razorpay.** { *; }

# Keep smart_auth plugin classes
-keep class fman.ge.smart_auth.** { *; }
-keepclassmembers class fman.ge.smart_auth.** { *; }

# Don't warn about missing GMS classes (they're conditionally used)
-dontwarn com.google.android.gms.auth.api.credentials.**

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

