package a.gautham.downloader_try1

import android.content.Intent.FLAG_ACTIVITY_NEW_TASK
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {

    private val CHANNEL = "a.gautham/getUri"

    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
            this.finish()
            intent.addFlags(FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "getFileUri") {
                val uri: Uri? = getFileUri(File(call.argument<String>("path").toString()))

                if (uri != null) {
                    result.success(uri.toString())
                } else {
                    result.error("404", "Something went wrong", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getFileUri(file: File): Uri? {
        return FileProvider.getUriForFile(
            this,
            this.packageName.toString() + ".provider",
            file
        )
    }

}
