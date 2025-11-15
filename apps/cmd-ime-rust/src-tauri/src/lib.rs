//! cmd-ime-rust - Command key IME switcher for macOS
//! Provides the low-level keyboard hook and settings persistence.

mod event_tap;
mod ime;
mod settings;

use event_tap::{EventTapManager, KeyMapping};
use once_cell::sync::OnceCell;
use settings::Settings;
use std::ffi::{c_char, CStr, CString};
use std::sync::{Arc, Mutex};

/// Shared application state owned by the Rust backend.
struct AppState {
    event_tap: Arc<Mutex<EventTapManager<'static>>>,
    settings: Arc<Mutex<Settings>>,
}

static APP_STATE: OnceCell<AppState> = OnceCell::new();

fn ensure_state() -> &'static AppState {
    APP_STATE.get_or_init(|| {
        let settings = Settings::load();
        let mut event_tap = EventTapManager::new();
        apply_settings_to_event_tap(&mut event_tap, &settings);

        AppState {
            event_tap: Arc::new(Mutex::new(event_tap)),
            settings: Arc::new(Mutex::new(settings)),
        }
    })
}

fn apply_settings_to_event_tap(event_tap: &mut EventTapManager<'static>, settings: &Settings) {
    let mappings = settings_to_key_mappings(settings);
    event_tap.set_mappings(mappings);

    let excluded: Vec<String> = settings
        .excluded_apps
        .iter()
        .filter(|app| app.enabled)
        .map(|app| app.bundle_id.clone())
        .collect();
    event_tap.set_excluded_apps(excluded);
}

fn settings_to_key_mappings(settings: &Settings) -> Vec<KeyMapping> {
    settings
        .mappings
        .iter()
        .map(|config| {
            let input_key = match config.input_key.as_str() {
                "Command_L" => 0x37,
                "Command_R" => 0x36,
                _ => 0x37,
            };

            KeyMapping {
                input_key,
                output_source: config.output_source.clone(),
                enabled: config.enabled,
            }
        })
        .collect()
}

fn with_c_str<F>(ptr: *const c_char, f: F) -> bool
where
    F: FnOnce(&str) -> bool,
{
    if ptr.is_null() {
        return false;
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    match c_str.to_str() {
        Ok(value) => f(value),
        Err(_) => false,
    }
}

#[no_mangle]
pub extern "C" fn cmd_ime_initialize() -> bool {
    ensure_state();
    true
}

#[no_mangle]
pub extern "C" fn cmd_ime_start_monitoring() -> bool {
    let state = ensure_state();
    let mut event_tap = state.event_tap.lock().unwrap();
    event_tap.start().is_ok()
}

#[no_mangle]
pub extern "C" fn cmd_ime_stop_monitoring() {
    if let Some(state) = APP_STATE.get() {
        let mut event_tap = state.event_tap.lock().unwrap();
        event_tap.stop();
    }
}

#[no_mangle]
pub extern "C" fn cmd_ime_get_settings_json() -> *mut c_char {
    let state = ensure_state();
    let settings = state.settings.lock().unwrap();

    match serde_json::to_string(&*settings) {
        Ok(json) => CString::new(json).unwrap().into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn cmd_ime_update_settings_json(json: *const c_char) -> bool {
    with_c_str(json, |value| {
        match serde_json::from_str::<Settings>(value) {
            Ok(new_settings) => {
                let state = ensure_state();
                {
                    let mut settings = state.settings.lock().unwrap();
                    *settings = new_settings.clone();
                    if settings.save().is_err() {
                        return false;
                    }
                }

                let mut event_tap = state.event_tap.lock().unwrap();
                apply_settings_to_event_tap(&mut event_tap, &new_settings);
                true
            }
            Err(_) => false,
        }
    })
}

#[no_mangle]
pub extern "C" fn cmd_ime_reload_settings_from_disk() -> bool {
    let state = ensure_state();
    let updated = Settings::load();
    {
        let mut settings = state.settings.lock().unwrap();
        *settings = updated.clone();
    }

    let mut event_tap = state.event_tap.lock().unwrap();
    apply_settings_to_event_tap(&mut event_tap, &updated);
    true
}

/// # Safety
/// The pointer must have been obtained from `cmd_ime_get_settings_json` and not
/// freed earlier. Passing any other pointer (or double-freeing) will result in
/// undefined behavior.
#[no_mangle]
pub unsafe extern "C" fn cmd_ime_free_c_string(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }

    drop(CString::from_raw(ptr));
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::settings::{KeyMappingConfig, Settings};

    #[test]
    fn converts_settings_into_key_mappings() {
        let settings = Settings {
            launch_at_startup: true,
            check_updates_on_startup: false,
            mappings: vec![
                KeyMappingConfig {
                    input_key: "Command_L".to_string(),
                    output_source: "roman".to_string(),
                    enabled: true,
                },
                KeyMappingConfig {
                    input_key: "Command_R".to_string(),
                    output_source: "hiragana".to_string(),
                    enabled: false,
                },
                KeyMappingConfig {
                    input_key: "Unknown".to_string(),
                    output_source: "roman".to_string(),
                    enabled: true,
                },
            ],
            excluded_apps: vec![],
        };

        let mappings = settings_to_key_mappings(&settings);
        assert_eq!(mappings[0].input_key, 0x37);
        assert_eq!(mappings[1].input_key, 0x36);
        assert_eq!(mappings[2].input_key, 0x37);
        assert_eq!(mappings.len(), 3);
    }
}
