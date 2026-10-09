use crate::domain::action::Action;
use crate::domain::planner::PlannedEntry;
use crate::domain::report::{Outcome, Report};
use crate::ports::FileSystemWriter;

fn link(item: &PlannedEntry, writer: &dyn FileSystemWriter) -> Result<(), String> {
    writer
        .create_parent_dir(item.entry().target())
        .map_err(|error| error.to_string())?;
    writer
        .symlink(item.entry().source(), item.entry().target())
        .map_err(|error| error.to_string())
}

fn run(item: &PlannedEntry, suffix: &str, writer: &dyn FileSystemWriter) -> Outcome {
    match item.action() {
        Action::AlreadyApplied => Outcome::Unchanged,
        Action::Create => match link(item, writer) {
            Ok(()) => Outcome::Linked,
            Err(error) => Outcome::Failed(error),
        },
        Action::Replace => {
            if let Err(error) = writer.remove_symlink(item.entry().target()) {
                return Outcome::Failed(error.to_string());
            }
            match link(item, writer) {
                Ok(()) => Outcome::Replaced,
                Err(error) => Outcome::Failed(error),
            }
        }
        Action::BackupAndCreate => {
            let saved = match writer.move_aside(item.entry().target(), suffix) {
                Ok(path) => path,
                Err(error) => return Outcome::Failed(error.to_string()),
            };
            match link(item, writer) {
                Ok(()) => Outcome::BackedUp(saved),
                Err(error) => Outcome::Failed(error),
            }
        }
    }
}

pub fn apply(planned: &[PlannedEntry], suffix: &str, writer: &dyn FileSystemWriter) -> Vec<Report> {
    planned
        .iter()
        .map(|item| {
            Report::new(
                item.entry().target().to_path_buf(),
                run(item, suffix, writer),
            )
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::entry::{Entry, Scope};
    use crate::domain::fake_fs::FakeFs;
    use crate::domain::planner::plan;
    use std::path::PathBuf;

    const TARGET: &str = "/home/palamar/.config/mako/config";
    const SOURCE: &str = "/repo/config/mako/config";

    fn entry() -> Entry {
        Entry::new(PathBuf::from(SOURCE), PathBuf::from(TARGET), Scope::User)
    }

    #[test]
    fn creates_link_when_target_is_missing() {
        let fs = FakeFs::new();
        let reports = apply(&plan(&[entry()], &fs), "bak", &fs);

        assert_eq!(reports[0].outcome(), &Outcome::Linked);
        assert_eq!(
            fs.log(),
            vec![
                format!("mkdir {TARGET}"),
                format!("link {TARGET} -> {SOURCE}"),
            ]
        );
    }

    #[test]
    fn existing_file_is_moved_aside_before_linking() {
        let fs = FakeFs::new().with_file(TARGET);
        let reports = apply(&plan(&[entry()], &fs), "20261009", &fs);

        let saved = PathBuf::from(format!("{TARGET}.20261009"));
        assert_eq!(reports[0].outcome(), &Outcome::BackedUp(saved));
        assert!(fs.log()[0].starts_with("backup "));
    }

    #[test]
    fn foreign_symlink_is_removed_before_linking() {
        let fs = FakeFs::new().with_link(TARGET, "/opt/outro");
        let reports = apply(&plan(&[entry()], &fs), "bak", &fs);

        assert_eq!(reports[0].outcome(), &Outcome::Replaced);
        assert_eq!(fs.log()[0], format!("unlink {TARGET}"));
    }

    #[test]
    fn already_linked_target_touches_nothing() {
        let fs = FakeFs::new().with_link(TARGET, SOURCE);
        let reports = apply(&plan(&[entry()], &fs), "bak", &fs);

        assert_eq!(reports[0].outcome(), &Outcome::Unchanged);
        assert!(fs.log().is_empty());
    }

    #[test]
    fn failure_is_reported_without_stopping() {
        let fs = FakeFs::new().failing_symlink();
        let reports = apply(&plan(&[entry(), entry()], &fs), "bak", &fs);

        assert_eq!(reports.len(), 2);
        assert!(reports.iter().all(|report| report.failed()));
    }
}
