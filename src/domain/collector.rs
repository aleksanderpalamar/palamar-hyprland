use crate::domain::filter::excluded;
use crate::ports::FileSystemExplorer;
use std::path::{Path, PathBuf};

fn walk(
    path: &Path,
    excludes: &[String],
    explorer: &dyn FileSystemExplorer,
    found: &mut Vec<PathBuf>,
) {
    if excluded(path, excludes) || !explorer.exists(path) {
        return;
    }

    if !explorer.is_dir(path) {
        found.push(path.to_path_buf());
        return;
    }

    let Ok(children) = explorer.children(path) else {
        return;
    };

    for child in children {
        walk(&child, excludes, explorer, found);
    }
}

pub fn collect(
    roots: &[PathBuf],
    excludes: &[String],
    explorer: &dyn FileSystemExplorer,
) -> Vec<PathBuf> {
    let mut found = Vec::new();
    for root in roots {
        walk(root, excludes, explorer, &mut found);
    }
    found.sort();
    found
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::fake_fs::FakeFs;

    fn tree() -> FakeFs {
        FakeFs::new()
            .with_dir(
                "/home/palamar/.config/waybar",
                &["config.jsonc", "style.css"],
            )
            .with_dir("/home/palamar/.config/hypr", &["hyprland.lua", "backups"])
            .with_dir("/home/palamar/.config/hypr/backups", &["antigo.lua"])
            .with_file("/home/palamar/.config/waybar/config.jsonc")
            .with_file("/home/palamar/.config/waybar/style.css")
            .with_file("/home/palamar/.config/hypr/hyprland.lua")
            .with_file("/home/palamar/.config/hypr/backups/antigo.lua")
    }

    #[test]
    fn expands_directory_into_files() {
        let roots = vec![PathBuf::from("/home/palamar/.config/waybar")];
        let found = collect(&roots, &[], &tree());
        assert_eq!(
            found,
            vec![
                PathBuf::from("/home/palamar/.config/waybar/config.jsonc"),
                PathBuf::from("/home/palamar/.config/waybar/style.css"),
            ]
        );
    }

    #[test]
    fn skips_excluded_directories() {
        let roots = vec![PathBuf::from("/home/palamar/.config/hypr")];
        let found = collect(&roots, &["backups".to_string()], &tree());
        assert_eq!(
            found,
            vec![PathBuf::from("/home/palamar/.config/hypr/hyprland.lua")]
        );
    }

    #[test]
    fn single_file_root_is_kept() {
        let roots = vec![PathBuf::from("/home/palamar/.config/hypr/hyprland.lua")];
        assert_eq!(collect(&roots, &[], &tree()).len(), 1);
    }

    #[test]
    fn missing_root_yields_nothing() {
        let roots = vec![PathBuf::from("/home/palamar/.config/ausente")];
        assert!(collect(&roots, &[], &FakeFs::new()).is_empty());
    }
}
