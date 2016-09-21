import COpenSSL

public enum KeyError: Error {
    case error(description: String)
}

public class Key {
	var key: UnsafeMutablePointer<EVP_PKEY>

	init(key: UnsafeMutablePointer<EVP_PKEY>) {
		initialize()
		self.key = key
	}

	init(io: IO) throws {
		initialize()
		guard let _key = PEM_read_bio_PrivateKey(io.bio, nil, nil, nil) else {
			throw KeyError.error(description: lastSSLErrorDescription)
		}
		self.key = _key
	}

	public convenience init(pemString: String) throws {
		try self.init(io: IO(buffer: pemString))
	}

	deinit {
		EVP_PKEY_free(key)
	}

	public static func generate(keyLength: Int32 = 2048) -> Key {
		let key = Key(key: EVP_PKEY_new())
		let rsa = RSA_new()
		let exponent = BN_new()
		BN_set_word(exponent, 0x10001)
		RSA_generate_key_ex(rsa, keyLength, exponent, nil)
		EVP_PKEY_set1_RSA(key.key, rsa)
		return key
	}
}
