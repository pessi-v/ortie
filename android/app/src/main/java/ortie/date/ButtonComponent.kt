package ortie.date

import android.util.Log
import android.view.MenuItem
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import org.json.JSONObject

class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {

    private var menuItem: MenuItem? = null

    override fun onReceive(message: Message) {
        when (message.event) {
            "connect" -> handleConnectEvent(message)
            else -> Log.w("ButtonComponent", "Unknown event for message: $message")
        }
    }

    private fun handleConnectEvent(message: Message) {
        val title = JSONObject(message.jsonData).optString("title").takeIf { it.isNotEmpty() } ?: return
        val toolbar = delegate.destination.toolbarForNavigation() ?: return
        menuItem = toolbar.menu.add(title).apply {
            setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS)
            setOnMenuItemClickListener { performButtonClick(); true }
        }
    }

    private fun performButtonClick(): Boolean {
        return replyTo("connect")
    }

    override fun onStop() {
        menuItem?.let { item ->
            delegate.destination.toolbarForNavigation()?.menu?.removeItem(item.itemId)
        }
        menuItem = null
    }
}
