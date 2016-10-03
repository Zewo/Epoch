@_exported import Axis
import COpenSSL

private var initialized = false

public func initialize() {
	guard !initialized else { return }
	SSL_library_init()
	SSL_load_error_strings()
	ERR_load_crypto_strings()
	OPENSSL_config(nil)
}
