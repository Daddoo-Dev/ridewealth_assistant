# Optional ML Kit script packs are compileOnly in google_mlkit_text_recognition.
# Receipt scan only uses Latin, so tell R8 these classes are unused.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
