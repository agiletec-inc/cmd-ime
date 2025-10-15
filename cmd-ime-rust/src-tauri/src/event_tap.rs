//! CGEventTap implementation for keyboard monitoring
//! Port of KeyEvent.swift logic to Rust

use core_graphics::event::{
    CGEvent, CGEventTap, CGEventTapLocation, CGEventTapOptions, CGEventTapPlacement,
    CGEventType, EventField,
};
use std::sync::{Arc, Mutex};

// Key codes for left and right Command keys
const KEY_CODE_COMMAND_L: i64 = 0x37; // 左Command
const KEY_CODE_COMMAND_R: i64 = 0x36; // 右Command

// Thread-safe wrapper for CGEventTap
struct EventTapWrapper<'a>(Option<CGEventTap<'a>>);

unsafe impl<'a> Send for EventTapWrapper<'a> {}
unsafe impl<'a> Sync for EventTapWrapper<'a> {}

pub struct EventTapManager<'a> {
    tap: EventTapWrapper<'a>,
    mappings: Arc<Mutex<Vec<KeyMapping>>>,
    excluded_apps: Arc<Mutex<Vec<String>>>,
}

#[derive(Debug, Clone)]
pub struct KeyMapping {
    pub input_key: i64,
    pub output_source: String, // "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman" or "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese"
    pub enabled: bool,
}

impl<'a> EventTapManager<'a> {
    pub fn new() -> Self {
        Self {
            tap: EventTapWrapper(None),
            mappings: Arc::new(Mutex::new(vec![
                KeyMapping {
                    input_key: KEY_CODE_COMMAND_L,
                    output_source: "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman".to_string(),
                    enabled: true,
                },
                KeyMapping {
                    input_key: KEY_CODE_COMMAND_R,
                    output_source: "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese".to_string(),
                    enabled: true,
                },
            ])),
            excluded_apps: Arc::new(Mutex::new(Vec::new())),
        }
    }

    /// Start monitoring keyboard events
    pub fn start(&mut self) -> Result<(), String> {
        // Check accessibility permissions
        if !Self::check_accessibility_permission() {
            return Err("Accessibility permission not granted".to_string());
        }

        let mappings = Arc::clone(&self.mappings);
        let excluded_apps = Arc::clone(&self.excluded_apps);

        // Create event tap
        let tap = CGEventTap::new(
            CGEventTapLocation::HID,
            CGEventTapPlacement::HeadInsertEventTap,
            CGEventTapOptions::Default,
            vec![CGEventType::KeyDown, CGEventType::FlagsChanged],
            move |_proxy, event_type, event| {
                Self::event_callback(
                    event_type,
                    event,
                    &mappings,
                    &excluded_apps,
                )
            },
        )
        .map_err(|e| format!("Failed to create event tap: {:?}", e))?;

        tap.enable();
        self.tap = EventTapWrapper(Some(tap));

        Ok(())
    }

    /// Stop monitoring
    pub fn stop(&mut self) {
        if let Some(tap) = self.tap.0.take() {
            // Event tap will be automatically disabled when dropped
            drop(tap);
        }
    }

    /// Event callback (matches KeyEvent.swift logic)
    fn event_callback(
        event_type: CGEventType,
        event: &CGEvent,
        mappings: &Arc<Mutex<Vec<KeyMapping>>>,
        excluded_apps: &Arc<Mutex<Vec<String>>>,
    ) -> Option<CGEvent> {
        // Check if current app is excluded
        if Self::is_current_app_excluded(excluded_apps) {
            return Some(event.to_owned());
        }

        match event_type {
            CGEventType::FlagsChanged | CGEventType::KeyDown => {
                let keycode = event.get_integer_value_field(EventField::KEYBOARD_EVENT_KEYCODE);

                // Check if this key matches any mapping
                let mappings_guard = mappings.lock().unwrap();
                for mapping in mappings_guard.iter() {
                    if mapping.enabled && mapping.input_key == keycode {
                        // Switch IME
                        if let Err(e) = crate::ime::switch_input_source(&mapping.output_source) {
                            eprintln!("Failed to switch IME: {}", e);
                        }

                        // Consume the event (don't pass to other apps)
                        return None;
                    }
                }

                // Pass through if no mapping matched
                Some(event.to_owned())
            }
            _ => Some(event.to_owned()),
        }
    }

    /// Check accessibility permission
    fn check_accessibility_permission() -> bool {
        // TODO: Implement IOHIDRequestAccess check
        // For now, assume permission is granted
        true
    }

    /// Check if current app is in exclusion list
    fn is_current_app_excluded(excluded_apps: &Arc<Mutex<Vec<String>>>) -> bool {
        // TODO: Get current frontmost app bundle ID and check against exclusion list
        // This requires NSWorkspace integration
        false
    }

    /// Update key mappings
    pub fn set_mappings(&self, new_mappings: Vec<KeyMapping>) {
        let mut mappings = self.mappings.lock().unwrap();
        *mappings = new_mappings;
    }

    /// Update excluded apps
    pub fn set_excluded_apps(&self, apps: Vec<String>) {
        let mut excluded = self.excluded_apps.lock().unwrap();
        *excluded = apps;
    }
}

impl<'a> Drop for EventTapManager<'a> {
    fn drop(&mut self) {
        self.stop();
    }
}
