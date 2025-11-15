fn main() {
    if !cmd_ime_rust_lib::cmd_ime_initialize() {
        eprintln!("Failed to initialize cmd-ime backend");
        return;
    }

    if !cmd_ime_rust_lib::cmd_ime_start_monitoring() {
        eprintln!("Failed to start event tap");
    }

    // Run indefinitely when invoked directly.
    loop {
        std::thread::park();
    }
}
