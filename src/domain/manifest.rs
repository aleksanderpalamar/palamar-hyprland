use crate::domain::entry::{Entry, Scope};
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

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
enum ScopeSpec {
    User,
    System,
}

impl From<ScopeSpec> for Scope {
    fn from(spec: ScopeSpec) -> Self {
        match spec {
            ScopeSpec::User => Scope::User,
            ScopeSpec::System => Scope::System,
        }
    }
}

impl From<Scope> for ScopeSpec {
    fn from(scope: Scope) -> Self {
        match scope {
            Scope::User => ScopeSpec::User,
            Scope::System => ScopeSpec::System,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
struct EntrySpec {
    source: String,
    target: String,
    scope: ScopeSpec,
}

#[derive(Debug, Serialize, Deserialize, Default)]
struct ManifestFile {
    #[serde(default)]
    entry: Vec<EntrySpec>,
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
    file.entry
        .into_iter()
        .map(|spec| {
            Ok(Entry::new(
                repo.join(&spec.source),
                expand(&spec.target, home)?,
                spec.scope.into(),
            ))
        })
        .collect()
}

pub fn render(entries: &[Entry], repo: &Path, home: &Path) -> Result<String, ManifestError> {
    let file = ManifestFile {
        entry: entries
            .iter()
            .map(|entry| EntrySpec {
                source: entry
                    .source()
                    .strip_prefix(repo)
                    .unwrap_or(entry.source())
                    .display()
                    .to_string(),
                target: shorten(entry.target(), home),
                scope: entry.scope().into(),
            })
            .collect(),
    };
    Ok(toml::to_string_pretty(&file)?)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn repo() -> PathBuf {
        PathBuf::from("/home/palamar/Projetos/palamar-hyprland")
    }

    fn home() -> PathBuf {
        PathBuf::from("/home/palamar")
    }

    #[test]
    fn expands_tilde_against_home() {
        let entries = parse(
            "[[entry]]\nsource = \"config/hypr/hyprland.lua\"\ntarget = \"~/.config/hypr/hyprland.lua\"\nscope = \"user\"\n",
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
        let entries = parse(
            "[[entry]]\nsource = \"system/sddm.conf\"\ntarget = \"/etc/sddm.conf\"\nscope = \"system\"\n",
            &repo(),
            &home(),
        )
        .expect("manifesto válido");

        assert_eq!(entries[0].target(), Path::new("/etc/sddm.conf"));
        assert!(entries[0].requires_root());
    }

    #[test]
    fn rejects_relative_target() {
        let error = parse(
            "[[entry]]\nsource = \"a\"\ntarget = \".config/a\"\nscope = \"user\"\n",
            &repo(),
            &home(),
        );
        assert!(matches!(error, Err(ManifestError::RelativeTarget(_))));
    }

    #[test]
    fn empty_manifest_has_no_entries() {
        assert!(parse("", &repo(), &home()).expect("vazio").is_empty());
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
                repo().join("system/sddm.conf"),
                PathBuf::from("/etc/sddm.conf"),
                Scope::System,
            ),
        ];

        let text = render(&original, &repo(), &home()).expect("render");
        let parsed = parse(&text, &repo(), &home()).expect("parse");

        assert_eq!(parsed, original);
    }
}
