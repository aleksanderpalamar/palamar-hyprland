use std::path::Path;

fn matches(name: &str, pattern: &str) -> bool {
    let Some(core) = pattern.strip_prefix('*') else {
        return match pattern.strip_suffix('*') {
            Some(prefix) => name.starts_with(prefix),
            None => name == pattern,
        };
    };

    match core.strip_suffix('*') {
        Some(middle) => name.contains(middle),
        None => name.ends_with(core),
    }
}

pub fn excluded(path: &Path, patterns: &[String]) -> bool {
    path.components().any(|component| {
        let Some(name) = component.as_os_str().to_str() else {
            return false;
        };
        patterns.iter().any(|pattern| matches(name, pattern))
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn patterns() -> Vec<String> {
        vec![
            "backups".into(),
            "__pycache__".into(),
            "*.bak.*".into(),
            "*.orig".into(),
        ]
    }

    #[test]
    fn exact_component_is_excluded() {
        assert!(excluded(
            &PathBuf::from("/home/palamar/.config/hypr/backups/a.lua"),
            &patterns()
        ));
    }

    #[test]
    fn suffix_pattern_is_excluded() {
        assert!(excluded(
            &PathBuf::from("/home/palamar/.config/mako/config.orig"),
            &patterns()
        ));
    }

    #[test]
    fn middle_pattern_is_excluded() {
        assert!(excluded(
            &PathBuf::from("/home/palamar/.config/fuzzel/fuzzel.ini.bak.1791"),
            &patterns()
        ));
    }

    #[test]
    fn regular_file_is_kept() {
        assert!(!excluded(
            &PathBuf::from("/home/palamar/.config/hypr/hyprland.lua"),
            &patterns()
        ));
    }

    #[test]
    fn empty_patterns_keep_everything() {
        assert!(!excluded(
            &PathBuf::from("/home/palamar/.config/hypr/backups/a"),
            &[]
        ));
    }
}
