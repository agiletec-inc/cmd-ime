//! IME switching logic using Carbon Text Input Sources
//! Port of IME switching from KeyEvent.swift

use core_foundation::base::{CFType, TCFType};
use core_foundation::string::{CFString, CFStringRef};
use std::ffi::c_void;

// Carbon Text Input Sources C API bindings
#[link(name = "Carbon", kind = "framework")]
extern "C" {
    fn TISCreateInputSourceList(
        properties: CFTypeRef,
        include_all: bool,
    ) -> CFTypeRef; // CFArrayRef

    fn TISSelectInputSource(source: CFTypeRef);

    fn TISGetInputSourceProperty(
        source: CFTypeRef,
        property_key: CFStringRef,
    ) -> *const c_void;

    static kTISPropertyInputSourceID: CFStringRef;
}

type CFTypeRef = *const c_void;

/// Switch to specified input source
pub fn switch_input_source(source_id: &str) -> Result<(), String> {
    unsafe {
        // Create input source list
        let source_list = TISCreateInputSourceList(
            std::ptr::null(),
            true,
        );

        if source_list.is_null() {
            return Err("Failed to get input source list".to_string());
        }

        // Convert Rust string to CFString
        let target_id = CFString::new(source_id);

        // Search for matching input source
        let array = CFType::wrap_under_get_rule(source_list);

        // Cast to CFArray and iterate
        let array_ptr = source_list as *const __CFArray;
        let count = CFArrayGetCount(array_ptr);

        for i in 0..count {
            let source = CFArrayGetValueAtIndex(array_ptr, i);

            let source_id_ref = TISGetInputSourceProperty(
                source,
                kTISPropertyInputSourceID,
            );

            if !source_id_ref.is_null() {
                let current_id = CFString::wrap_under_get_rule(source_id_ref as CFStringRef);

                if current_id.to_string() == target_id.to_string() {
                    TISSelectInputSource(source);
                    return Ok(());
                }
            }
        }

        Err(format!("Input source not found: {}", source_id))
    }
}

/// Get current input source ID
pub fn get_current_input_source() -> Option<String> {
    unsafe {
        let current_source = TISCopyCurrentKeyboardInputSource();

        if current_source.is_null() {
            return None;
        }

        let source_id_ref = TISGetInputSourceProperty(
            current_source,
            kTISPropertyInputSourceID,
        );

        if source_id_ref.is_null() {
            return None;
        }

        let source_id = CFString::wrap_under_get_rule(source_id_ref as CFStringRef);
        Some(source_id.to_string())
    }
}

extern "C" {
    fn TISCopyCurrentKeyboardInputSource() -> CFTypeRef;
    fn CFArrayGetCount(array: *const __CFArray) -> isize;
    fn CFArrayGetValueAtIndex(array: *const __CFArray, idx: isize) -> *const c_void;
}

#[repr(C)]
struct __CFArray {
    _private: [u8; 0],
}

/// Predefined input source IDs
pub mod sources {
    pub const ALPHANUMERIC: &str = "com.apple.inputmethod.Kotoeri.RomajiTyping.Roman";
    pub const HIRAGANA: &str = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese";
}
