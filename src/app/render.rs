use crate::domain::action::Action;
use crate::domain::planner::PlannedEntry;
use crate::domain::report::{Outcome, Report};
use std::path::Path;

pub fn shorten(path: &Path, home: &Path) -> String {
    match path.strip_prefix(home) {
        Ok(rest) => format!("~/{}", rest.display()),
        Err(_) => path.display().to_string(),
    }
}

pub fn label(action: &Action) -> &'static str {
    match action {
        Action::Create => "criar",
        Action::Replace => "substituir",
        Action::BackupAndCreate => "backup+criar",
        Action::AlreadyApplied => "ok",
    }
}

pub fn describe(item: &PlannedEntry, home: &Path) -> String {
    format!(
        "{:<13} {}",
        label(item.action()),
        shorten(item.entry().target(), home)
    )
}

pub fn outcome_line(report: &Report, home: &Path) -> String {
    let target = shorten(report.target(), home);
    match report.outcome() {
        Outcome::Unchanged => format!("{:<13} {}", "ok", target),
        Outcome::Linked => format!("{:<13} {}", "ligado", target),
        Outcome::Replaced => format!("{:<13} {}", "substituido", target),
        Outcome::BackedUp(saved) => {
            format!(
                "{:<13} {} (backup: {})",
                "ligado",
                target,
                shorten(saved, home)
            )
        }
        Outcome::Failed(error) => format!("{:<13} {}: {}", "ERRO", target, error),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::entry::{Entry, Scope};
    use crate::domain::fake_fs::FakeFs;
    use crate::domain::planner::plan;
    use std::path::PathBuf;

    fn home() -> PathBuf {
        PathBuf::from("/home/palamar")
    }

    #[test]
    fn home_paths_are_shortened() {
        assert_eq!(
            shorten(&home().join(".config/mako"), &home()),
            "~/.config/mako"
        );
    }

    #[test]
    fn system_paths_stay_absolute() {
        assert_eq!(
            shorten(Path::new("/etc/sddm.conf"), &home()),
            "/etc/sddm.conf"
        );
    }

    #[test]
    fn describes_pending_entry() {
        let entry = Entry::new(
            PathBuf::from("/repo/config/mako/config"),
            home().join(".config/mako/config"),
            Scope::User,
        );
        let planned = plan(&[entry], &FakeFs::new());
        assert_eq!(
            describe(&planned[0], &home()),
            "criar         ~/.config/mako/config"
        );
    }

    #[test]
    fn failure_line_keeps_the_error() {
        let report = Report::new(
            home().join(".config/mako/config"),
            Outcome::Failed("sem permissao".into()),
        );
        assert!(outcome_line(&report, &home()).contains("sem permissao"));
    }
}
