package ortie.date

import android.os.Bundle
import android.view.View
import androidx.appcompat.widget.Toolbar
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink
import dev.hotwire.navigation.fragments.HotwireWebFragment

@HotwireDestinationDeepLink(uri = "hotwire://fragment/web")
class WebFragment : HotwireWebFragment() {
    override fun toolbarForNavigation(): Toolbar? = null

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        view.findViewById<View>(dev.hotwire.navigation.R.id.app_bar)?.visibility = View.GONE
    }
}
