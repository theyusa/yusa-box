package io.nekohasekai.libbox

import android.os.ParcelFileDescriptor

/**
 * BoxService is the main service class for sing-box VPN.
 * This class wraps the native BoxService and provides Java/Kotlin interface.
 */
class BoxService {
    
    /**
     * Start the service
     */
    external fun start()
    
    /**
     * Close the service
     */
    external fun close()
    
    /**
     * Pause the service
     */
    external fun pause()
    
    /**
     * Wake the service
     */
    external fun wake()
    
    /**
     * Reset network
     */
    external fun resetNetwork()
    
    /**
     * Check if WiFi state is needed
     * @return true if WiFi state is needed
     */
    external fun needWIFIState(): Boolean
    
    /**
     * Update WiFi state
     * @param ssid WiFi SSID
     * @param bssid WiFi BSSID
     */
    external fun updateWIFIState(ssid: String, bssid: String)
}
