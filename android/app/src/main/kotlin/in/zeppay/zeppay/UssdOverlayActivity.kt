package `in`.zeppay.zeppay

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView

/**
 * Translucent overlay for USSD replies. PIN is pass-through only — never stored.
 */
class UssdOverlayActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ussd_overlay)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_DIM_BEHIND,
        )
        window.setDimAmount(0.55f)

        val prompt = intent.getStringExtra(EXTRA_PROMPT).orEmpty()
        val pinStep = intent.getBooleanExtra(EXTRA_PIN_STEP, false)

        findViewById<TextView>(R.id.ussd_prompt).text = prompt
        val input = findViewById<EditText>(R.id.ussd_input)
        if (pinStep) {
            input.hint = "UPI PIN"
            input.inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_VARIATION_PASSWORD
        }

        findViewById<Button>(R.id.ussd_cancel).setOnClickListener { finish() }
        findViewById<Button>(R.id.ussd_submit).setOnClickListener {
            val reply = input.text?.toString().orEmpty()
            if (reply.isNotEmpty()) {
                UssdAccessibilityService.injectReply(reply)
            }
            input.text = null
            finish()
        }
    }

    companion object {
        private const val EXTRA_PROMPT = "prompt"
        private const val EXTRA_PIN_STEP = "isPinStep"

        fun show(context: Context, prompt: String, isPinStep: Boolean) {
            val overlayIntent = Intent(context, UssdOverlayActivity::class.java).apply {
                putExtra(EXTRA_PROMPT, prompt)
                putExtra(EXTRA_PIN_STEP, isPinStep)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(overlayIntent)
        }
    }
}
