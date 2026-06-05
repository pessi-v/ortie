package ortie.date

import android.app.Application
import dev.hotwire.core.bridge.BridgeComponentFactory
import dev.hotwire.core.bridge.KotlinXJsonConverter
import dev.hotwire.core.config.Hotwire
import dev.hotwire.navigation.config.defaultFragmentDestination
import dev.hotwire.navigation.config.registerBridgeComponents
import dev.hotwire.navigation.config.registerFragmentDestinations
import dev.hotwire.navigation.fragments.HotwireWebBottomSheetFragment

class OrtieApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Hotwire.config.jsonConverter = KotlinXJsonConverter()
        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("button", ::ButtonComponent)
        )
        Hotwire.registerFragmentDestinations(
            WebFragment::class,
            HotwireWebBottomSheetFragment::class
        )
        Hotwire.defaultFragmentDestination = WebFragment::class
    }
}
