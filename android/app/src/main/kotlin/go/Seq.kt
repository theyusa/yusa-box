package go

import android.content.Context

/**
 * Seq is the Go sequence binding for Android
 * This class is required for gomobile bindings
 */
object Seq {
    
    init {
        System.loadLibrary("box")
    }
    
    /**
     * Set the Android context for Go
     * @param context Android context
     */
    @JvmStatic
    external fun setContext(context: Context)
    
    /**
     * Initialize the sequence
     */
    @JvmStatic
    external fun init()
    
    /**
     * Increment Go reference count
     * @param refnum Reference number
     */
    @JvmStatic
    external fun incGoRef(refnum: Int)
    
    /**
     * Destroy a reference
     * @param refnum Reference number
     */
    @JvmStatic
    external fun destroyRef(refnum: Int)
}
