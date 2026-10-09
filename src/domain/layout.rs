use crate::domain::entry::Scope;
use std::path::{Path, PathBuf};

const CONFIG: &str = ".config";
const LOCAL_BIN: &str = ".local/bin";

pub fn source_for(target: &Path, home: &Path) -> PathBuf {
    if let Ok(rest) = target.strip_prefix(home.join(LOCAL_BIN)) {
        return Path::new("bin").join(rest);
    }
    if let Ok(rest) = target.strip_prefix(home.join(CONFIG)) {
        return Path::new("config").join(rest);
    }
    if let Ok(rest) = target.strip_prefix(home) {
        return Path::new("home").join(rest);
    }
    match target.strip_prefix("/") {
        Ok(rest) => Path::new("system").join(rest),
        Err(_) => Path::new("system").join(target),
    }
}

pub fn scope_for(target: &Path, home: &Path) -> Scope {
    match target.starts_with(home) {
        true => Scope::User,
        false => Scope::System,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn home() -> PathBuf {
        PathBuf::from("/home/palamar")
    }

    fn assert_source(target: &str, expected: &str) {
        assert_eq!(
            source_for(Path::new(target), &home()),
            PathBuf::from(expected)
        );
    }

    #[test]
    fn config_files_go_to_config() {
        assert_source(
            "/home/palamar/.config/hypr/hyprland.lua",
            "config/hypr/hyprland.lua",
        );
    }

    #[test]
    fn scripts_go_to_bin() {
        assert_source(
            "/home/palamar/.local/bin/hypr-system-menu",
            "bin/hypr-system-menu",
        );
    }

    #[test]
    fn other_home_files_go_to_home() {
        assert_source("/home/palamar/.zshrc", "home/.zshrc");
    }

    #[test]
    fn system_files_keep_their_path_under_system() {
        assert_source("/etc/sddm.conf", "system/etc/sddm.conf");
    }

    #[test]
    fn home_targets_are_user_scope() {
        assert_eq!(
            scope_for(Path::new("/home/palamar/.config/a"), &home()),
            Scope::User
        );
    }

    #[test]
    fn outside_home_is_system_scope() {
        assert_eq!(
            scope_for(Path::new("/etc/sddm.conf"), &home()),
            Scope::System
        );
    }

    #[test]
    fn local_bin_wins_over_home() {
        assert_source("/home/palamar/.local/bin/hypr-theme", "bin/hypr-theme");
    }
}
