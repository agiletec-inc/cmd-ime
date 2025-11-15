import CmdIMERuntime

enum CmdImeRuntime {
    @discardableResult
    static func initialize() -> Bool {
        cmd_ime_initialize()
    }

    @discardableResult
    static func startMonitoring() -> Bool {
        cmd_ime_start_monitoring()
    }

    static func stopMonitoring() {
        cmd_ime_stop_monitoring()
    }

    @discardableResult
    static func reloadSettings() -> Bool {
        cmd_ime_reload_settings_from_disk()
    }

    static func currentSettingsJSON() -> String? {
        guard let pointer = cmd_ime_get_settings_json() else {
            return nil
        }

        let value = String(cString: pointer)
        cmd_ime_free_c_string(pointer)
        return value
    }

    @discardableResult
    static func updateSettings(json: String) -> Bool {
        json.withCString { cString in
            cmd_ime_update_settings_json(cString)
        }
    }
}

protocol CmdImeRuntimeClient {
    @discardableResult func initialize() -> Bool
    @discardableResult func startMonitoring() -> Bool
    func stopMonitoring()
    @discardableResult func reloadSettings() -> Bool
    func currentSettingsJSON() -> String?
    @discardableResult func updateSettings(json: String) -> Bool
}

struct SystemCmdImeRuntime: CmdImeRuntimeClient {
    @discardableResult
    func initialize() -> Bool {
        CmdImeRuntime.initialize()
    }

    @discardableResult
    func startMonitoring() -> Bool {
        CmdImeRuntime.startMonitoring()
    }

    func stopMonitoring() {
        CmdImeRuntime.stopMonitoring()
    }

    @discardableResult
    func reloadSettings() -> Bool {
        CmdImeRuntime.reloadSettings()
    }

    func currentSettingsJSON() -> String? {
        CmdImeRuntime.currentSettingsJSON()
    }

    @discardableResult
    func updateSettings(json: String) -> Bool {
        CmdImeRuntime.updateSettings(json: json)
    }
}
