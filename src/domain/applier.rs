use crate::domain::placer::Placer;
use crate::domain::planner::PlannedEntry;
use crate::domain::report::Report;

pub fn apply(planned: &[PlannedEntry], suffix: &str, placer: &Placer) -> Vec<Report> {
    planned
        .iter()
        .map(|item| {
            Report::new(
                item.entry().target().to_path_buf(),
                placer.run(item, suffix),
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
    use crate::domain::report::Outcome;
    use std::path::PathBuf;

    const TARGET: &str = "/home/palamar/.config/mako/config";
    const SOURCE: &str = "/repo/config/mako/config";

    fn entry() -> Entry {
        Entry::new(PathBuf::from(SOURCE), PathBuf::from(TARGET), Scope::User)
    }

    fn system_entry() -> Entry {
        Entry::new(
            PathBuf::from("/repo/system/etc/locale.conf"),
            PathBuf::from("/etc/locale.conf"),
            Scope::System,
        )
    }

    fn placer(fs: &FakeFs) -> Placer<'_> {
        Placer {
            writer: fs,
            copier: fs,
        }
    }

    #[test]
    fn reports_one_line_per_entry_in_order() {
        let fs = FakeFs::new();
        let planned = plan(&[entry(), system_entry()], &fs);
        let reports = apply(&planned, "bak", &placer(&fs));

        assert_eq!(reports.len(), 2);
        assert_eq!(reports[0].outcome(), &Outcome::Linked);
        assert_eq!(reports[1].outcome(), &Outcome::Copied);
    }

    #[test]
    fn failure_is_reported_without_stopping() {
        let fs = FakeFs::new().failing_symlink();
        let reports = apply(&plan(&[entry(), entry()], &fs), "bak", &placer(&fs));

        assert_eq!(reports.len(), 2);
        assert!(reports.iter().all(|report| report.failed()));
    }
}
