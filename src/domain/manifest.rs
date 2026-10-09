use crate::domain::entry::Entry;
use crate::domain::layout::{scope_for, source_for};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ManifestError {
    #[error("manifesto inválido: {0}")]
    Syntax(#[from] toml::de::Error),
    #[error("não foi possível gerar o manifesto: {0}")]
    Render(#[from] toml::ser::Error),
    #[error("destino precisa ser absoluto ou começar com ~/: {0}")]
    RelativeTarget(String),
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct ManifestFile {
    #[serde(default)]
    targets: Vec<String>,
}

pub fn expand(target: &str, home: &Path) -> Result<PathBuf, ManifestError> {
    if let Some(rest) = target.strip_prefix("~/") {
        return Ok(home.join(rest));
    }
    match Path::new(target).is_absolute() {
        true => Ok(PathBuf::from(target)),
        false => Err(ManifestError::RelativeTarget(target.to_owned())),
    }
}

fn shorten(target: &Path, home: &Path) -> String {
    match target.strip_prefix(home) {
        Ok(rest) => format!("~/{}", rest.display()),
        Err(_) => target.display().to_string(),
    }
}

pub fn parse(contents: &str, repo: &Path, home: &Path) -> Result<Vec<Entry>, ManifestError> {
    let file: ManifestFile = toml::from_str(contents)?;
    file.targets
        .into_iter()
        .map(|spec| {
            let target = expand(&spec, home)?;
            let source = repo.join(source_for(&target, home));
            let scope = scope_for(&target, home);
            Ok(Entry::new(source, target, scope))
        })
        .collect()
}

pub fn render(entries: &[Entry], home: &Path) -> Result<String, ManifestError> {
    let file = ManifestFile {
        targets: entries
            .iter()
            .map(|entry| shorten(entry.target(), home))
            .collect(),
    };
    Ok(toml::to_string_pretty(&file)?)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::entry::Scope;

    fn repo() -> PathBuf {
        PathBuf::from("/home/palamar/Projetos/palamar-hyprland")
    }

    fn home() -> PathBuf {
        PathBuf::from("/home/palamar")
    }

    #[test]
    fn expands_tilde_against_home() {
        let entries = parse(
            "targets = [\"~/.config/hypr/hyprland.lua\"]\n",
            &repo(),
            &home(),
        )
        .expect("manifesto válido");

        assert_eq!(entries.len(), 1);
        assert_eq!(
            entries[0].target(),
            Path::new("/home/palamar/.config/hypr/hyprland.lua")
        );
        assert_eq!(entries[0].source(), repo().join("config/hypr/hyprland.lua"));
        assert_eq!(entries[0].scope(), Scope::User);
    }

    #[test]
    fn keeps_absolute_system_targets() {
        let entries =
            parse("targets = [\"/etc/sddm.conf\"]\n", &repo(), &home()).expect("manifesto válido");

        assert_eq!(entries[0].target(), Path::new("/etc/sddm.conf"));
        assert_eq!(entries[0].source(), repo().join("system/etc/sddm.conf"));
        assert!(entries[0].requires_root());
    }

    #[test]
    fn scripts_land_in_bin() {
        let entries = parse(
            "targets = [\"~/.local/bin/hypr-theme\"]\n",
            &repo(),
            &home(),
        )
        .expect("manifesto válido");

        assert_eq!(entries[0].source(), repo().join("bin/hypr-theme"));
    }

    #[test]
    fn rejects_relative_target() {
        let error = parse("targets = [\".config/a\"]\n", &repo(), &home());
        assert!(matches!(error, Err(ManifestError::RelativeTarget(_))));
    }

    #[test]
    fn empty_manifest_has_no_entries() {
        assert!(parse("", &repo(), &home()).expect("vazio").is_empty());
    }

    #[test]
    fn renders_one_line_per_target() {
        let entries = vec![
            Entry::new(
                repo().join("config/hypr/hyprland.lua"),
                home().join(".config/hypr/hyprland.lua"),
                Scope::User,
            ),
            Entry::new(
                repo().join("system/etc/sddm.conf"),
                PathBuf::from("/etc/sddm.conf"),
                Scope::System,
            ),
        ];

        let text = render(&entries, &home()).expect("render");

        assert!(text.contains("\"~/.config/hypr/hyprland.lua\""));
        assert!(text.contains("\"/etc/sddm.conf\""));
        assert!(!text.contains("source"));
        assert!(!text.contains("scope"));
    }

    #[test]
    fn render_and_parse_round_trip() {
        let original = vec![
            Entry::new(
                repo().join("config/hypr/hyprland.lua"),
                home().join(".config/hypr/hyprland.lua"),
                Scope::User,
            ),
            Entry::new(
                repo().join("system/etc/sddm.conf"),
                PathBuf::from("/etc/sddm.conf"),
                Scope::System,
            ),
        ];

        let text = render(&original, &home()).expect("render");
        let parsed = parse(&text, &repo(), &home()).expect("parse");

        assert_eq!(parsed, original);
    }
}
