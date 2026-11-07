package com.example.billing_software

import android.Manifest
import android.content.ContentValues
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "billing_software/downloads"
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingFileName: String? = null
    private val storagePermissionRequestCode = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToDownloads" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val fileName = call.argument<String>("fileName") ?: "receipt.pdf"

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("INVALID_DATA", "PDF bytes are empty", null)
                        return@setMethodCallHandler
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        try {
                            val savedPath = saveViaMediaStore(bytes, fileName)
                            if (savedPath != null) {
                                result.success(savedPath)
                            } else {
                                result.error("SAVE_FAILED", "Failed to save file to Downloads", null)
                            }
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", e.localizedMessage ?: e.message ?: "Unknown error", null)
                        }
                    } else {
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                            == PackageManager.PERMISSION_GRANTED
                        ) {
                            try {
                                val savedPath = saveToDownloadsLegacy(bytes, fileName)
                                result.success(savedPath)
                            } catch (e: Exception) {
                                result.error("SAVE_ERROR", e.localizedMessage ?: e.message ?: "Unknown error", null)
                            }
                        } else {
                            pendingResult = result
                            pendingBytes = bytes
                            pendingFileName = fileName
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.READ_EXTERNAL_STORAGE),
                                storagePermissionRequestCode
                            )
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveViaMediaStore(bytes: ByteArray, fileName: String): String? {
        val resolver = applicationContext.contentResolver
        val contentValues = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
        }

        val uri: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
        } else {
            null
        }

        if (uri != null) {
            resolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                contentValues.clear()
                contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)
            }
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            return "${downloadsDir.path}/$fileName"
        }
        return null
    }

    private fun saveToDownloadsLegacy(bytes: ByteArray, fileName: String): String {
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }
        var targetFile = File(downloadsDir, fileName)
        var counter = 1
        val baseName = fileName.substringBeforeLast(".")
        val extension = fileName.substringAfterLast(".", "pdf")
        while (targetFile.exists()) {
            targetFile = File(downloadsDir, "$baseName ($counter).$extension")
            counter++
        }
        FileOutputStream(targetFile).use { it.write(bytes) }
        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(targetFile.absolutePath),
            arrayOf("application/pdf"),
            null
        )
        return targetFile.absolutePath
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == storagePermissionRequestCode) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                val bytes = pendingBytes
                val fileName = pendingFileName
                val result = pendingResult
                pendingBytes = null
                pendingFileName = null
                pendingResult = null

                if (bytes != null && fileName != null && result != null) {
                    try {
                        val savedPath = saveToDownloadsLegacy(bytes, fileName)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_ERROR", e.localizedMessage ?: e.message ?: "Unknown error", null)
                    }
                }
            } else {
                pendingResult?.error("PERMISSION_DENIED", "Storage permission was denied by the user", null)
                pendingResult = null
                pendingBytes = null
                pendingFileName = null
            }
        }
    }
}
