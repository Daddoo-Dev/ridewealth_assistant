package com.ridewealthassistant.app

import android.content.Intent
import android.net.Uri
import androidx.core.app.ActivityCompat.startActivityForResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener

class StorageAccessPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, ActivityResultListener {
    private lateinit var channel : MethodChannel
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingResult: Result? = null
    private val CREATE_FILE = 1

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.ridewealthassistant.app/storage_access")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "createAndSaveFile" -> {
                val fileName = call.argument<String>("fileName")
                val content = call.argument<String>("content")
                if (fileName != null && content != null) {
                    pendingResult = result
                    createFile(fileName, content)
                } else {
                    result.error("INVALID_ARGUMENTS", "fileName and content are required", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun createFile(fileName: String, content: String) {
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "text/csv"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        activityBinding?.activity?.startActivityForResult(intent, CREATE_FILE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == CREATE_FILE) {
            if (resultCode == android.app.Activity.RESULT_OK) {
                data?.data?.also { uri ->
                    writeContent(uri, pendingResult?.argument<String>("content") ?: "")
                }
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
            return true
        }
        return false
    }

    private fun writeContent(uri: Uri, content: String) {
        try {
            activityBinding?.activity?.contentResolver?.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(content.toByteArray())
            }
            pendingResult?.success(true)
        } catch (e: Exception) {
            pendingResult?.error("WRITE_FAILED", "Failed to write content", e.toString())
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
    }
}