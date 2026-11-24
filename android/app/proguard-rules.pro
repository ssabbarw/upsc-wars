# Flutter's Gradle plugin also applies flutter_proguard_rules.pro.
# Plugin AARs contribute their own consumer keep rules.
# Keep this file narrow so R8 can still shrink, obfuscate, and optimize.

# Room creates *_Impl databases by reflection (WorkManager's WorkDatabase at
# startup). Room 2.6's own rule keeps the class only; R8 full mode then drops
# the no-arg constructor and the app crashes on launch.
-keep class * extends androidx.room.RoomDatabase { <init>(); }

# Readable Crashlytics traces for the Java/Kotlin layer after shrinking.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
