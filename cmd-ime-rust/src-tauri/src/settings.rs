//! Settings management
//! Handles configuration persistence and app exclusion list

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Settings {
    pub launch_at_startup: bool,
    pub check_updates_on_startup: bool,
    pub mappings: Vec<KeyMappingConfig>,
    pub excluded_apps: Vec<AppInfo>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeyMappingConfig {
    pub input_key: String,       // "Command_L", "Command_R"
    pub output_source: String,   // IME source ID
    pub enabled: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppInfo {
    pub name: String,
    pub bundle_id: String,
    pub enabled: bool,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            launch_at_startup: true,
            check_updates_on_startup: true,
            mappings: vec![
                KeyMappingConfig {
                    input_key: "Command_L".to_string(),
                    output_source: crate::ime::sources::ALPHANUMERIC.to_string(),
                    enabled: true,
                },
                KeyMappingConfig {
                    input_key: "Command_R".to_string(),
                    output_source: crate::ime::sources::HIRAGANA.to_string(),
                    enabled: true,
                },
            ],
            excluded_apps: Vec::new(),
        }
    }
}

impl Settings {
    /// Get settings file path
    fn settings_path() -> PathBuf {
        let home = dirs::home_dir().expect("Failed to get home directory");
        home.join(".config/cmd-ime/settings.json")
    }

    /// Load settings from file
    pub fn load() -> Self {
        let path = Self::settings_path();

        if !path.exists() {
            return Self::default();
        }

        match fs::read_to_string(&path) {
            Ok(content) => serde_json::from_str(&content).unwrap_or_default(),
            Err(_) => Self::default(),
        }
    }

    /// Save settings to file
    pub fn save(&self) -> Result<(), String> {
        let path = Self::settings_path();

        // Create parent directory if not exists
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).map_err(|e| e.to_string())?;
        }

        let content = serde_json::to_string_pretty(self)
            .map_err(|e| e.to_string())?;

        fs::write(&path, content).map_err(|e| e.to_string())?;

        Ok(())
    }

    /// Add an app to exclusion list
    pub fn add_excluded_app(&mut self, name: String, bundle_id: String) {
        self.excluded_apps.push(AppInfo {
            name,
            bundle_id,
            enabled: true,
        });
    }

    /// Remove an app from exclusion list
    pub fn remove_excluded_app(&mut self, bundle_id: &str) {
        self.excluded_apps.retain(|app| app.bundle_id != bundle_id);
    }
}

// Add dirs dependency for home_dir
// This will need to be added to Cargo.toml
