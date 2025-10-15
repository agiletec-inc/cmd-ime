//! cmd-ime-rust - Command key IME switcher for macOS
//! Rust + Tauri implementation

mod event_tap;
mod ime;
mod settings;

use event_tap::{EventTapManager, KeyMapping};
use settings::{AppInfo, Settings};
use std::sync::{Arc, Mutex};
use tauri::{Manager, State};

/// Application state
pub struct AppState {
    pub event_tap: Arc<Mutex<EventTapManager<'static>>>,
    pub settings: Arc<Mutex<Settings>>,
}

/// Start keyboard monitoring
#[tauri::command]
fn start_monitoring(state: State<'_, AppState>) -> Result<(), String> {
    let mut event_tap = state.event_tap.lock().unwrap();
    event_tap.start()?;
    Ok(())
}

/// Stop keyboard monitoring
#[tauri::command]
fn stop_monitoring(state: State<'_, AppState>) -> Result<(), String> {
    let mut event_tap = state.event_tap.lock().unwrap();
    event_tap.stop();
    Ok(())
}

/// Get current settings
#[tauri::command]
fn get_settings(state: State<'_, AppState>) -> Settings {
    let settings = state.settings.lock().unwrap();
    settings.clone()
}

/// Update settings
#[tauri::command]
fn update_settings(
    state: State<'_, AppState>,
    new_settings: Settings,
) -> Result<(), String> {
    let mut settings = state.settings.lock().unwrap();
    *settings = new_settings.clone();

    // Save to disk
    settings.save()?;

    // Update event tap manager
    let event_tap = state.event_tap.lock().unwrap();
    let mappings = settings_to_key_mappings(&settings);
    event_tap.set_mappings(mappings);

    let excluded_bundle_ids: Vec<String> = settings
        .excluded_apps
        .iter()
        .filter(|app| app.enabled)
        .map(|app| app.bundle_id.clone())
        .collect();
    event_tap.set_excluded_apps(excluded_bundle_ids);

    Ok(())
}

/// Add app to exclusion list
#[tauri::command]
fn add_excluded_app(
    state: State<'_, AppState>,
    name: String,
    bundle_id: String,
) -> Result<(), String> {
    let mut settings = state.settings.lock().unwrap();

    settings.add_excluded_app(name, bundle_id.clone());
    settings.save()?;

    // Update event tap manager
    let event_tap = state.event_tap.lock().unwrap();
    let excluded_bundle_ids: Vec<String> = settings
        .excluded_apps
        .iter()
        .filter(|app| app.enabled)
        .map(|app| app.bundle_id.clone())
        .collect();
    event_tap.set_excluded_apps(excluded_bundle_ids);

    Ok(())
}

/// Remove app from exclusion list
#[tauri::command]
fn remove_excluded_app(
    state: State<'_, AppState>,
    bundle_id: String,
) -> Result<(), String> {
    let mut settings = state.settings.lock().unwrap();

    settings.remove_excluded_app(&bundle_id);
    settings.save()?;

    // Update event tap manager
    let event_tap = state.event_tap.lock().unwrap();
    let excluded_bundle_ids: Vec<String> = settings
        .excluded_apps
        .iter()
        .filter(|app| app.enabled)
        .map(|app| app.bundle_id.clone())
        .collect();
    event_tap.set_excluded_apps(excluded_bundle_ids);

    Ok(())
}

/// Get recently active apps
#[tauri::command]
fn get_recent_apps() -> Vec<AppInfo> {
    // TODO: Implement using NSWorkspace
    // For now, return mock data
    vec![
        AppInfo {
            name: "OBS Studio".to_string(),
            bundle_id: "com.obsproject.obs-studio".to_string(),
            enabled: false,
        },
        AppInfo {
            name: "Warp".to_string(),
            bundle_id: "dev.warp.Warp-Stable".to_string(),
            enabled: false,
        },
        AppInfo {
            name: "Arc".to_string(),
            bundle_id: "company.thebrowser.Browser".to_string(),
            enabled: false,
        },
    ]
}

/// Convert settings to key mappings
fn settings_to_key_mappings(settings: &Settings) -> Vec<KeyMapping> {
    settings
        .mappings
        .iter()
        .map(|config| {
            let input_key = match config.input_key.as_str() {
                "Command_L" => 0x37,
                "Command_R" => 0x36,
                _ => 0x37, // Default to left command
            };

            KeyMapping {
                input_key,
                output_source: config.output_source.clone(),
                enabled: config.enabled,
            }
        })
        .collect()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    // Load settings
    let settings = Settings::load();

    // Create event tap manager
    let event_tap_manager = EventTapManager::new();

    // Configure initial mappings
    let mappings = settings_to_key_mappings(&settings);
    event_tap_manager.set_mappings(mappings);

    let excluded_bundle_ids: Vec<String> = settings
        .excluded_apps
        .iter()
        .filter(|app| app.enabled)
        .map(|app| app.bundle_id.clone())
        .collect();
    event_tap_manager.set_excluded_apps(excluded_bundle_ids);

    // Create app state
    let app_state = AppState {
        event_tap: Arc::new(Mutex::new(event_tap_manager)),
        settings: Arc::new(Mutex::new(settings)),
    };

    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .manage(app_state)
        .invoke_handler(tauri::generate_handler![
            start_monitoring,
            stop_monitoring,
            get_settings,
            update_settings,
            add_excluded_app,
            remove_excluded_app,
            get_recent_apps,
        ])
        .setup(|app| {
            // Auto-start monitoring
            let state: State<AppState> = app.state();
            let mut event_tap = state.event_tap.lock().unwrap();

            if let Err(e) = event_tap.start() {
                eprintln!("Failed to start event tap: {}", e);
            }

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
