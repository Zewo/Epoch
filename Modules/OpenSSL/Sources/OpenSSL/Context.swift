import COpenSSL

public enum ContextError : Error {
    case context(description: String)
    case certificate(description: String)
    case key(description: String)
}

public class Context {
	let mode: SSLMethod.Mode
	var context: UnsafeMutablePointer<SSL_CTX>?
	var sniHostname: String? = nil

	public init(method: SSLMethod = .sslv23, mode: SSLMethod.Mode = .client) throws {
		self.mode = mode

		initialize()
		context = SSL_CTX_new(method.getMethod(mode: mode))

		if context == nil {
			throw ContextError.context(description: lastSSLErrorDescription)
		}

		if mode == .client {
			SSL_CTX_set_verify(context, SSL_VERIFY_NONE, nil)
//			SSL_CTX_set_verify_depth(context, 4)
//			SSL_CTX_ctrl(context, SSL_CTRL_OPTIONS, SSL_OP_NO_SSLv2 | SSL_OP_NO_SSLv3 | SSL_OP_NO_COMPRESSION, nil)
//			try useDefaultVerifyPaths()
		} else {
			SSL_CTX_set_verify(context, SSL_VERIFY_NONE, nil)
		}
	}

	public convenience init(method: SSLMethod = .sslv23, mode: SSLMethod.Mode = .client, certificatePath: String? = nil, privateKeyPath: String? = nil, certificateChainPath: String? = nil, verifyBundle: String? = nil, sniHostname: String? = nil) throws {
		try self.init(method: method, mode: mode)

		if let verifyBundle = verifyBundle {
			try useVerifyBundle(verifyBundle: verifyBundle)
		}

		if let certificateChain = certificateChainPath {
			try useCertificateChainFile(certificateChainFile: certificateChain)
		}

		if let certificate = certificatePath {
			try useCertificateFile(certificateFile: certificate)
		}

		if let privateKey = privateKeyPath {
			try usePrivateKeyFile(privateKeyFile: privateKey)
		}

		if let sniHostname = sniHostname {
			try setServerNameIndication(hostname: sniHostname)
		}
	}

	deinit {
		SSL_CTX_free(context)
	}

	public func useDefaultVerifyPaths() throws {
		if SSL_CTX_set_default_verify_paths(context) != 1 {
			throw ContextError.context(description: lastSSLErrorDescription)
		}
	}

	public func useVerifyBundle(verifyBundle: String) throws {
		if SSL_CTX_load_verify_locations(context, verifyBundle, nil) != 1 {
			throw ContextError.context(description: lastSSLErrorDescription)
		}
	}

	public func useCertificate(certificate: Certificate) throws {
		if SSL_CTX_use_certificate(context, certificate.certificate) != 1 {
			throw ContextError.certificate(description: lastSSLErrorDescription)
		}
	}

	public func useCertificateFile(certificateFile: String) throws {
		if SSL_CTX_use_certificate_file(context, certificateFile, SSL_FILETYPE_PEM) != 1 {
			throw ContextError.certificate(description: lastSSLErrorDescription)
		}
	}

	public func useCertificateChainFile(certificateChainFile: String) throws {
		if SSL_CTX_use_certificate_chain_file(context, certificateChainFile) != 1 {
			throw ContextError.certificate(description: lastSSLErrorDescription)
		}
	}

	public func usePrivateKey(privateKey: Key, check: Bool = true) throws {
		if SSL_CTX_use_PrivateKey(context, privateKey.key) != 1 {
			throw ContextError.key(description: lastSSLErrorDescription)
		}
		if check {
			try checkPrivateKey()
		}
	}

	public func usePrivateKeyFile(privateKeyFile: String, check: Bool = true) throws {
		if SSL_CTX_use_PrivateKey_file(context, privateKeyFile, SSL_FILETYPE_PEM) != 1 {
			throw ContextError.key(description: lastSSLErrorDescription)
		}
		if check {
			try checkPrivateKey()
		}
	}

	private func checkPrivateKey() throws {
		if SSL_CTX_check_private_key(context) != 1 {
			throw ContextError.key(description: lastSSLErrorDescription)
		}
	}

	public func setCipherSuites(cipherSuites: String) throws {
		if SSL_CTX_set_cipher_list(context, cipherSuites) != 1 {
			throw ContextError.context(description: lastSSLErrorDescription)
		}
	}

	public func setSrtpProfiles(srtpProfiles: String) throws {
		if SSL_CTX_set_tlsext_use_srtp(context, srtpProfiles) != 1 {
			throw ContextError.context(description: lastSSLErrorDescription)
		}
	}

	public func setServerNameIndication(hostname: String) throws {
		sniHostname = hostname
	}
}
