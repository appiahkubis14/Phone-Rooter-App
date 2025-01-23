package com.example.controller

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.URL
import android.provider.Settings 

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.controller"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    companion object {
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize DevicePolicyManager for device admin functionalities
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableDeviceAdmin" -> enableDeviceAdmin(result)
                "lockDevice" -> lockDevice(result)
                "unlockDevice" -> unlockDevice(result)
                "downloadAndInstallApp" -> {
                    val url = call.argument<String>("url")
                    val appName = call.argument<String>("appName") ?: "UnknownApp"
                    if (url != null) {
                        downloadAndInstallApp(url, appName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL is null or invalid", null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        launchApp(packageName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null or invalid", null)
                    }
                }
                "setLock" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        setLock(packageName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null or invalid", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }


    private fun enableDeviceAdmin(result: MethodChannel.Result) {
        if (devicePolicyManager.isAdminActive(componentName)) {
            result.success("Device Admin already enabled")
        } else {
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
                putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "This app requires device admin access.")
            }
            startActivityForResult(intent, 1)
            result.success("Device Admin requested")
        }
    }

    private fun lockDevice(result: MethodChannel.Result) {
        try {
            if (devicePolicyManager.isAdminActive(componentName)) {
                startLockTask()
                result.success("Device locked successfully")
            } else {
                result.error("LOCK_FAILED", "Device admin not active", null)
            }
        } catch (e: Exception) {
            result.error("LOCK_FAILED", "Error locking device: ${e.message}", null)
        }
    }

    private fun unlockDevice(result: MethodChannel.Result) {
        try {
            stopLockTask() // Unlocks the device from the app
            result.success("Device unlocked successfully")
        } catch (e: Exception) {
            result.error("UNLOCK_FAILED", "Error unlocking device: ${e.message}", null)
        }
    }

    private fun downloadAndInstallApp(apkUrl: String, appName: String, result: MethodChannel.Result) {
        Log.d(TAG, "Starting download for app: $appName from $apkUrl")
        
        // Check if the app has permission to install unknown apps
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !packageManager.canRequestPackageInstalls()) {
            // If not, redirect to the settings to allow the permission
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                data = Uri.parse("package:$packageName") // Set the URI to the current app
            }
            Log.e(TAG, "Install unknown apps permission is required")
            result.error(
                "PERMISSION_DENIED",
                "Install unknown apps permission is required. Redirecting to settings...",
                null
            )
            startActivity(intent) // Start the intent to open the settings page for permission
            return
        }
        
        // Proceed with downloading and installing the APK
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val apkFileName = "$appName.apk"
                val apkFilePath = "${applicationContext.getExternalFilesDir(null)}/$apkFileName"
                val apkFile = File(apkFilePath)
        
                Log.d(TAG, "Connecting to URL: $apkUrl")
                val url = URL(apkUrl)
                val connection = url.openConnection()
                connection.connect()
        
                Log.d(TAG, "Downloading APK file to: $apkFilePath")
                val inputStream: InputStream = connection.getInputStream()
        
                FileOutputStream(apkFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
        
                if (!apkFile.exists() || apkFile.length() == 0L) {
                    throw IOException("Failed to download the APK file or file is empty")
                }
        
                Log.d(TAG, "APK file downloaded successfully: $apkFilePath")
                val uri: Uri = FileProvider.getUriForFile(this@MainActivity, "$packageName.provider", apkFile)
        
                withContext(Dispatchers.Main) {
                    Log.d(TAG, "Starting APK installation for: $apkFileName")
                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, "application/vnd.android.package-archive")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                    }
                    startActivity(intent)
    
                    // Notify Flutter app about the installation process
                    result.success("APK installation started successfully")
                    
                    // Log after the installation attempt
                    Log.d(TAG, "Installation process triggered. Please check the device for the app.")
                }
            } catch (e: IOException) {
                Log.e(TAG, "IOException occurred: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error("IO_EXCEPTION", "Error during file operation: ${e.message}", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error occurred: ${e.message}", e)
                withContext(Dispatchers.Main) {
                    result.error("DOWNLOAD_INSTALL_FAILED", "Unexpected error: ${e.message}", null)
                }
            }
        }
    }
    
    private fun launchApp(packageName: String, result: MethodChannel.Result) {
        try {
            val packageManager = packageManager
    
            // Log all installed packages on the device to help verify the correct package name
            val installedPackages = packageManager.getInstalledPackages(0)
            installedPackages.forEach {
                Log.d("InstalledApp", "Installed package: ${it.packageName}")
            }
    
            // Check if the app is installed and get the launch intent
            val intent: Intent? = packageManager.getLaunchIntentForPackage(packageName)
    
            // Log the package name and intent for debugging
            Log.d("LaunchApp", "Package: $packageName, Intent: $intent")
    
            // Check if the intent is null (meaning the app is not installed)
            if (intent != null) {
                // Ensure the intent has the necessary flag to launch the app
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    
                // Start the app on the UI thread to avoid issues
                runOnUiThread {
                    startActivity(intent)
                }
    
                result.success("Launching app: $packageName")
            } else {
                // If the app is not installed, just return an error without opening Play Store
                Log.w("LaunchApp", "App not found: $packageName")
                result.error("APP_NOT_FOUND", "App with package name $packageName not found.", null)
            }
        } catch (e: Exception) {
            // Catch any unexpected errors and log them
            Log.e("LaunchApp", "Error launching app", e)
            result.error("ERROR", "Error launching app: ${e.message}", null)
        }
    }
    
    private fun setLock(packageName: String, result: MethodChannel.Result) {
        try {
            // Ensure that the app has device admin privileges
            if (devicePolicyManager.isAdminActive(componentName)) {
                // Set the device to lock task mode (single app mode) and allow only this app to be used
                devicePolicyManager.setLockTaskPackages(componentName, arrayOf(packageName))
                startLockTask() // This will lock the device to the specified package

                result.success("Device locked into $packageName")
            } else {
                result.error("DEVICE_ADMIN_NOT_ACTIVE", "Device admin is not active", null)
            }
        } catch (e: Exception) {
            result.error("SET_LOCK_FAILED", "Failed to lock device into app", null)
        }
    }
    
    

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus && devicePolicyManager.isAdminActive(componentName)) {
            // Toast.makeText(this, "Press Back + Recent simultaneously to exit", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onBackPressed() {
        if (devicePolicyManager.isAdminActive(componentName)) {
            // Toast.makeText(this, "App is locked. You cannot go back.", Toast.LENGTH_SHORT).show()
        } else {
            super.onBackPressed()
        }
    }

    override fun onUserLeaveHint() {
        if (devicePolicyManager.isAdminActive(componentName)) {
            // Toast.makeText(this, "App is locked. Press Back + Recent simultaneously to exit.", Toast.LENGTH_SHORT).show()
        } else {
            super.onUserLeaveHint()
        }
    }
}
