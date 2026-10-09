use crate::domain::action::Action;
use crate::domain::install::Install;
use crate::domain::planner::PlannedEntry;
use crate::domain::report::Outcome;
use crate::ports::{FileCopier, FileSystemWriter};

pub struct Placer<'a> {
    pub writer: &'a dyn FileSystemWriter,
    pub copier: &'a dyn FileCopier,
}

impl Placer<'_> {
    fn place(&self, item: &PlannedEntry) -> Result<Outcome, String> {
        let entry = item.entry();
        match item.install() {
            Install::Link => {
                self.writer
                    .create_parent_dir(entry.target())
                    .map_err(|error| error.to_string())?;
                self.writer
                    .symlink(entry.source(), entry.target())
                    .map(|()| Outcome::Linked)
                    .map_err(|error| error.to_string())
            }
            Install::Copy => self
                .copier
                .copy_into(entry.source(), entry.target())
                .map(|()| Outcome::Copied)
                .map_err(|error| error.to_string()),
        }
    }

    pub fn run(&self, item: &PlannedEntry, suffix: &str) -> Outcome {
        match item.action() {
            Action::AlreadyApplied => Outcome::Unchanged,
            Action::Create => self.place(item).unwrap_or_else(Outcome::Failed),
            Action::Replace => {
                if let Err(error) = self.writer.remove_symlink(item.entry().target()) {
                    return Outcome::Failed(error.to_string());
                }
                match self.place(item) {
                    Ok(_) => Outcome::Replaced,
                    Err(error) => Outcome::Failed(error),
                }
            }
            Action::BackupAndCreate => {
                let saved = match self.writer.move_aside(item.entry().target(), suffix) {
                    Ok(path) => path,
                    Err(error) => return Outcome::Failed(error.to_string()),
                };
                match self.place(item) {
                    Ok(_) => Outcome::BackedUp(saved),
                    Err(error) => Outcome::Failed(error),
                }
            }
        }
    }
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
    const SYS_TARGET: &str = "/etc/locale.conf";
    const SYS_SOURCE: &str = "/repo/system/etc/locale.conf";

    fn entry() -> Entry {
        Entry::new(PathBuf::from(SOURCE), PathBuf::from(TARGET), Scope::User)
    }

    fn system_entry() -> Entry {
        Entry::new(
            PathBuf::from(SYS_SOURCE),
            PathBuf::from(SYS_TARGET),
            Scope::System,
        )
    }

    fn placed(fs: &FakeFs, entry: Entry, suffix: &str) -> Outcome {
        let placer = Placer {
            writer: fs,
            copier: fs,
        };
        placer.run(&plan(&[entry], fs)[0], suffix)
    }

    #[test]
    fn user_entry_is_linked() {
        let fs = FakeFs::new();
        assert_eq!(placed(&fs, entry(), "bak"), Outcome::Linked);
        assert_eq!(
            fs.log(),
            vec![
                format!("mkdir {TARGET}"),
                format!("link {TARGET} -> {SOURCE}"),
            ]
        );
    }

    #[test]
    fn system_entry_is_copied_instead_of_linked() {
        let fs = FakeFs::new();
        assert_eq!(placed(&fs, system_entry(), "bak"), Outcome::Copied);
        assert_eq!(fs.log(), vec![format!("copy {SYS_TARGET} <- {SYS_SOURCE}")]);
    }

    #[test]
    fn system_entry_with_other_content_is_backed_up_first() {
        let fs = FakeFs::new()
            .with_content(SYS_SOURCE, "LANG=pt_BR.UTF-8")
            .with_content(SYS_TARGET, "LANG=C");
        let saved = PathBuf::from(format!("{SYS_TARGET}.20261009"));

        assert_eq!(
            placed(&fs, system_entry(), "20261009"),
            Outcome::BackedUp(saved)
        );
        assert!(fs.log()[0].starts_with("backup "));
        assert!(fs.log()[1].starts_with("copy "));
    }

    #[test]
    fn system_entry_already_equal_touches_nothing() {
        let fs = FakeFs::new()
            .with_content(SYS_SOURCE, "LANG=pt_BR.UTF-8")
            .with_content(SYS_TARGET, "LANG=pt_BR.UTF-8");

        assert_eq!(placed(&fs, system_entry(), "bak"), Outcome::Unchanged);
        assert!(fs.log().is_empty());
    }

    #[test]
    fn symlink_left_in_a_system_path_is_replaced_by_a_copy() {
        let fs = FakeFs::new().with_link(SYS_TARGET, SYS_SOURCE);

        assert_eq!(placed(&fs, system_entry(), "bak"), Outcome::Replaced);
        assert_eq!(fs.log()[0], format!("unlink {SYS_TARGET}"));
        assert!(fs.log()[1].starts_with("copy "));
    }

    #[test]
    fn existing_file_is_moved_aside_before_linking() {
        let fs = FakeFs::new().with_file(TARGET);
        let saved = PathBuf::from(format!("{TARGET}.20261009"));

        assert_eq!(placed(&fs, entry(), "20261009"), Outcome::BackedUp(saved));
        assert!(fs.log()[0].starts_with("backup "));
    }

    #[test]
    fn foreign_symlink_is_removed_before_linking() {
        let fs = FakeFs::new().with_link(TARGET, "/opt/outro");

        assert_eq!(placed(&fs, entry(), "bak"), Outcome::Replaced);
        assert_eq!(fs.log()[0], format!("unlink {TARGET}"));
    }

    #[test]
    fn already_linked_target_touches_nothing() {
        let fs = FakeFs::new().with_link(TARGET, SOURCE);

        assert_eq!(placed(&fs, entry(), "bak"), Outcome::Unchanged);
        assert!(fs.log().is_empty());
    }

    #[test]
    fn link_failure_becomes_an_error_outcome() {
        let fs = FakeFs::new().failing_symlink();
        assert!(matches!(placed(&fs, entry(), "bak"), Outcome::Failed(_)));
    }

    #[test]
    fn copy_failure_becomes_an_error_outcome() {
        let fs = FakeFs::new().failing_copy();
        assert!(matches!(
            placed(&fs, system_entry(), "bak"),
            Outcome::Failed(_)
        ));
    }
}
