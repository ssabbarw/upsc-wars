# Flutter's Gradle plugin also applies flutter_proguard_rules.pro.
# Plugin AARs contribute their own consumer keep rules.
# Keep this file narrow so R8 can still shrink, obfuscate, and optimize.

# Readable Crashlytics traces for the Java/Kotlin layer after shrinking.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
