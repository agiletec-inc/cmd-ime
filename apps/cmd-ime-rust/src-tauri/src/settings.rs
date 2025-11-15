//! Settings management
//! Handles configuration persistence and app exclusion list

use serde::{Deserialize, Serialize};
use std::env;
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
    pub input_key: String,     // "Command_L", "Command_R"
    pub output_source: String, // IME source ID
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
    fn config_dir() -> PathBuf {
        if let Ok(dir) = env::var("CMD_IME_CONFIG_DIR") {
            return PathBuf::from(dir);
        }

        dirs::home_dir()
            .expect("Failed to get home directory")
            .join(".config/cmd-ime")
    }

    /// Get settings file path
    fn settings_path() -> PathBuf {
        Self::config_dir().join("settings.json")
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

        let content = serde_json::to_string_pretty(self).map_err(|e| e.to_string())?;

        fs::write(&path, content).map_err(|e| e.to_string())?;

        Ok(())
    }

    /// Add an app to exclusion list
    #[allow(dead_code)]
    pub fn add_excluded_app(&mut self, name: String, bundle_id: String) {
        self.excluded_apps.push(AppInfo {
            name,
            bundle_id,
            enabled: true,
        });
    }

    /// Remove an app from exclusion list
    #[allow(dead_code)]
    pub fn remove_excluded_app(&mut self, bundle_id: &str) {
        self.excluded_apps.retain(|app| app.bundle_id != bundle_id);
    }
}

// Add dirs dependency for home_dir
// This will need to be added to Cargo.toml

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use tempfile::TempDir;

    fn with_temp_config_dir<F: FnOnce()>(func: F) {
        let temp = TempDir::new().unwrap();
        env::set_var("CMD_IME_CONFIG_DIR", temp.path());
        func();
        env::remove_var("CMD_IME_CONFIG_DIR");
    }

    #[test]
    fn default_settings_include_two_mappings() {
        let settings = Settings::default();
        assert_eq!(settings.mappings.len(), 2);
        assert!(settings
            .mappings
            .iter()
            .any(|m| m.input_key == "Command_L"));
        assert!(settings
            .mappings
            .iter()
            .any(|m| m.input_key == "Command_R"));
    }

    #[test]
    fn save_and_load_round_trip() {
        with_temp_config_dir(|| {
            let mut settings = Settings::default();
            settings.launch_at_startup = false;
            settings
                .add_excluded_app("Test".into(), "com.example.test".into());
            settings.save().expect("should save");

            let loaded = Settings::load();
            assert!(!loaded.launch_at_startup);
            assert_eq!(loaded.excluded_apps.len(), 1);
            assert_eq!(loaded.excluded_apps[0].bundle_id, "com.example.test");
        });
    }
}
