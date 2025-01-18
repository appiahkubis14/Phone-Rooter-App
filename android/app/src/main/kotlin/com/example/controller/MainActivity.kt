package com.example.controller

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.controller"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName
    private val validPins = listOf("1234", "5678", "91011") // Replace with your actual pins
    private val apiUrl = "https://cocoarehabmonitor.com/media/Cocoa_Monitor_V5.apk" // Replace with your actual API URL

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableDeviceAdmin" -> enableDeviceAdmin(result)
                "exitKioskMode" -> exitKioskMode(result)
                "installApps" -> installApps(result)
                else -> result.notImplemented()
            }
        }

        // Automatically enable device admin and lock the device into kiosk mode
        if (devicePolicyManager.isAdminActive(componentName)) {
            lockDevice()
        } else {
            enableDeviceAdmin()
        }
    }

    private fun enableDeviceAdmin(result: MethodChannel.Result? = null) {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "This app requires device admin access.")
        startActivityForResult(intent, 1)
        result?.success(null)
    }

    private fun lockDevice(result: MethodChannel.Result? = null) {
        if (devicePolicyManager.isAdminActive(componentName)) {
            startLockTask()
            result?.success(null)
        } else {
            result?.error("DEVICE_ADMIN_NOT_ACTIVE", "Device admin is not active", null)
        }
    }

    private fun exitKioskMode(result: MethodChannel.Result) {
        showPinDialog {
            stopLockTask() // Exit kiosk mode
            Toast.makeText(this, "Exited kiosk mode", Toast.LENGTH_SHORT).show()
            result.success("Exited kiosk mode")
        }
    }

    private fun showPinDialog(onSuccess: () -> Unit) {
        val builder = AlertDialog.Builder(this)
        val input = EditText(this)
        input.inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_VARIATION_PASSWORD
        builder.setTitle("Enter PIN to Exit")
            .setView(input)
            .setPositiveButton("OK") { dialog, _ ->
                val pin = input.text.toString()
                if (isValidPin(pin)) {
                    onSuccess()
                    dialog.dismiss()
                } else {
                    Toast.makeText(this, "Invalid PIN", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel") { dialog, _ -> dialog.cancel() }
        builder.show()
    }

    private fun isValidPin(pin: String): Boolean {
        return validPins.contains(pin)
    }

    private fun installApps(result: MethodChannel.Result) {
        val apkUrls = fetchAppsToInstall(apiUrl)
        if (apkUrls.isNotEmpty()) {
            for (apkUrl in apkUrls) {
                val success = installAppWithRoot(apkUrl)
                if (!success) {
                    result.error("INSTALL_FAILED", "Failed to install app from $apkUrl", null)
                    return
                }
            }
            result.success("All apps installed successfully")
        } else {
            result.error("NO_APPS", "No apps to install", null)
        }
    }

    private fun fetchAppsToInstall(apiUrl: String): List<String> {
        val urls = mutableListOf<String>()
        try {
            val url = URL(apiUrl)
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"

            val reader = BufferedReader(InputStreamReader(connection.inputStream))
            val response = StringBuilder()
            var line: String?

            while (reader.readLine().also { line = it } != null) {
                response.append(line)
            }

            // Parse the response (e.g., JSON array of URLs)
            val jsonArray = JSONArray(response.toString())
            for (i in 0 until jsonArray.length()) {
                urls.add(jsonArray.getString(i))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return urls
    }

    private fun installAppWithRoot(apkPath: String): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("su")
            val outputStream = process.outputStream
            outputStream.write(("pm install -r $apkPath\n").toByteArray())
            outputStream.flush()
            outputStream.close()

            val bufferedReader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            val output = StringBuilder()
            while (bufferedReader.readLine().also { line = it } != null) {
                output.append(line)
            }
            process.waitFor()

            process.exitValue() == 0
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
