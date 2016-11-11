#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CPOSIX

public var environment = Environment()

public struct Environment {
    public lazy var variables: [String: String] = {
        var envs: [String: String] = [:]

        #if os(Linux)
            guard var env = __environ else {
                return envs
            }
        #else
            guard var env = environ else {
                return envs
            }
        #endif

        while true {
            guard let envPointee = env.pointee else {
                break
            }

            guard let envString = String(validatingUTF8: envPointee) else {
                env += 1
                continue
            }

            guard let index = envString.unicodeScalars.index(of: "=") else {
                env += 1
                continue
            }

            let name = String(envString.unicodeScalars.prefix(upTo: index))
            let value = String(envString.unicodeScalars.suffix(from: envString.unicodeScalars.index(after: index)))
            envs[name] = value
            env += 1
        }

        return envs
    }()

    public subscript(variable: String) -> String? {
        get {
            return get(variable: variable)
        }

        nonmutating set(value) {
            if let value = value {
                set(value: value, to: variable, replace: true)
            } else {
                remove(variable: variable)
            }
        }
    }

    public func get(variable: String) -> String? {
        guard let value = getenv(variable) else {
            return nil
        }
        return String(validatingUTF8: value)
    }

    public func set(value: String, to variable: String, replace: Bool = true) {
        setenv(variable, value, replace ? 1 : 0)
    }

    public func remove(variable: String) {
        unsetenv(variable)
    }
}
