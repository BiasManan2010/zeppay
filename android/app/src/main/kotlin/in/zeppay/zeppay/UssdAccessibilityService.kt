package `in`.zeppay.zeppay

import android.accessibilityservice.AccessibilityService
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Reads carrier USSD dialog text and injects user replies from [UssdOverlayActivity].
 * Never logs or persists PIN/reply strings.
 */
class UssdAccessibilityService : AccessibilityService() {

    interface UssdSessionListener {
        fun onUssdMessage(message: String, isPinStep: Boolean)
        fun onUssdSessionEnded()
    }

    companion object {
        var listener: UssdSessionListener? = null
        private var active: UssdAccessibilityService? = null

        fun injectReply(reply: String) {
            active?.injectReplyInternal(reply)
        }
    }

    override fun onServiceConnected() {
        active = this
    }

    override fun onDestroy() {
        if (active === this) active = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val root = rootInActiveWindow ?: return
        val text = extractDialogText(root)?.trim().orEmpty()
        if (text.isEmpty()) return
        val pinStep = looksLikePinStep(text)
        listener?.onUssdMessage(text, pinStep)
    }

    private fun looksLikePinStep(text: String): Boolean {
        val lower = text.lowercase()
        return lower.contains("pin") ||
            lower.contains("mpin") ||
            lower.contains("enter") && lower.contains("upi")
    }

    private fun extractDialogText(node: AccessibilityNodeInfo): String? {
        val className = node.className?.toString().orEmpty()
        if (className.contains("TextView") && !node.text.isNullOrBlank()) {
            return node.text.toString()
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                extractDialogText(child)?.let { return it }
            }
        }
        return null
    }

    private fun injectReplyInternal(reply: String) {
        val root = rootInActiveWindow ?: return
        val editField = findEditableNode(root) ?: return
        val args = Bundle()
        args.putCharSequence(
            AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
            reply,
        )
        editField.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        findClickableByText(root, listOf("Send", "OK", "SEND", "Submit"))
            ?.performAction(AccessibilityNodeInfo.ACTION_CLICK)
    }

    private fun findEditableNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isEditable) return node
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                findEditableNode(child)?.let { return it }
            }
        }
        return null
    }

    private fun findClickableByText(
        node: AccessibilityNodeInfo,
        labels: List<String>,
    ): AccessibilityNodeInfo? {
        if (node.isClickable && labels.any { node.text?.contains(it, true) == true }) {
            return node
        }
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { child ->
                findClickableByText(child, labels)?.let { return it }
            }
        }
        return null
    }

    override fun onInterrupt() {}
}
