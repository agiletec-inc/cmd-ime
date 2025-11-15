#pragma once

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool cmd_ime_initialize(void);
bool cmd_ime_start_monitoring(void);
void cmd_ime_stop_monitoring(void);
char *cmd_ime_get_settings_json(void);
bool cmd_ime_update_settings_json(const char *json);
bool cmd_ime_reload_settings_from_disk(void);
void cmd_ime_free_c_string(char *ptr);

#ifdef __cplusplus
}
#endif
