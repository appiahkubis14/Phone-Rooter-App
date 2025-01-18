package com.controller

import java.io.File
import java.io.DataOutputStream
import java.io.IOException

object RootUtils {
    // Check if the device is rooted
    fun isRooted(): Boolean {
        val paths = arrayOf(
            "/system/xbin/su", 
            "/system/bin/su", 
            "/su/bin/su"
        )
        for (path in paths) {
            if (File(path).exists()) {
                return true
            }
        }
        return false
    }

    // Execute root command to install APK
    fun installApp(apkPath: String) {
        try {
            val process = Runtime.getRuntime().exec("su")
            val outputStream = DataOutputStream(process.outputStream)
            outputStream.writeBytes("pm install $apkPath\n")
            outputStream.flush()
            outputStream.writeBytes("exit\n")
            outputStream.flush()
            process.waitFor()
        } catch (e: IOException) {
            e.printStackTrace()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
    }
}
