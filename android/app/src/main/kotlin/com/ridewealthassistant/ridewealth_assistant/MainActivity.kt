package com.ridewealthassistant.app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ridewealthassistant.app/file_saver"
    private var pendingResult: MethodChannel.Result? = null
    private val CREATE_FILE = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createFile" -> {
                    pendingResult = result
                    createFile(call.argument("fileName")!!)
                }
                "writeFile" -> {
                    val uri = Uri.parse(call.argument("uri")!!)
                    val content = call.argument("content")!!
                    writeFile(uri, content, result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createFile(fileName: String) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "text/csv"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        startActivityForResult(intent, CREATE_FILE)
    }

    private fun writeFile(uri: Uri, content: String, result: MethodChannel.Result) {
        try {
            contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(content.toByteArray())
            }
            result.success(null)
        } catch (e: IOException) {
            result.error("WRITE_FAILED", "Failed to write to file", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CREATE_FILE && resultCode == RESULT_OK) {
            data?.data?.also { uri ->
                pendingResult?.success(uri.toString())
            }
        } else {
            pendingResult?.success(null)
        }
        pendingResult = null
    }
}