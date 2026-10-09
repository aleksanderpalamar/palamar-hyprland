use crate::domain::action::{Action, decide};
use crate::domain::entry::Entry;
use crate::domain::state::TargetState;
use crate::ports::FileSystemReader;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlannedEntry {
    entry: Entry,
    action: Action,
}

impl PlannedEntry {
    pub fn entry(&self) -> &Entry {
        &self.entry
    }

    pub fn action(&self) -> &Action {
        &self.action
    }
}

pub fn inspect(entry: &Entry, fs: &dyn FileSystemReader) -> TargetState {
    let Some(target) = fs.symlink_target(entry.target()) else {
        return match fs.exists(entry.target()) {
            true => TargetState::Occupied,
            false => TargetState::Missing,
        };
    };

    match target == entry.source() {
        true => TargetState::LinkedToSource,
        false => TargetState::LinkedElsewhere(target),
    }
}

pub fn plan(entries: &[Entry], fs: &dyn FileSystemReader) -> Vec<PlannedEntry> {
    entries
        .iter()
        .map(|entry| PlannedEntry {
            entry: entry.clone(),
            action: decide(&inspect(entry, fs)),
        })
        .collect()
}

pub fn pending(planned: &[PlannedEntry]) -> Vec<&PlannedEntry> {
    planned
        .iter()
        .filter(|item| item.action().changes_system())
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::entry::Scope;
    use crate::domain::fake_fs::FakeFs;
    use std::path::PathBuf;

    const TARGET: &str = "/home/palamar/.config/hypr/hyprland.lua";
    const SOURCE: &str = "/repo/config/hypr/hyprland.lua";

    fn entry() -> Entry {
        Entry::new(PathBuf::from(SOURCE), PathBuf::from(TARGET), Scope::User)
    }

    #[test]
    fn absent_target_is_missing() {
        assert_eq!(inspect(&entry(), &FakeFs::new()), TargetState::Missing);
    }

    #[test]
    fn regular_file_occupies_the_target() {
        let fs = FakeFs::new().with_file(TARGET);
        assert_eq!(inspect(&entry(), &fs), TargetState::Occupied);
    }

    #[test]
    fn symlink_to_source_is_already_applied() {
        let fs = FakeFs::new().with_link(TARGET, SOURCE);
        assert_eq!(inspect(&entry(), &fs), TargetState::LinkedToSource);
    }

    #[test]
    fn symlink_elsewhere_keeps_the_current_target() {
        let fs = FakeFs::new().with_link(TARGET, "/opt/outro.lua");
        let esperado = TargetState::LinkedElsewhere(PathBuf::from("/opt/outro.lua"));
        assert_eq!(inspect(&entry(), &fs), esperado);
    }

    #[test]
    fn pending_hides_entries_already_applied() {
        let fs = FakeFs::new().with_link(TARGET, SOURCE);
        let planned = plan(&[entry()], &fs);
        assert_eq!(planned.len(), 1);
        assert!(pending(&planned).is_empty());
    }

    #[test]
    fn pending_lists_entries_that_change_the_system() {
        let planned = plan(&[entry()], &FakeFs::new());
        assert_eq!(pending(&planned).len(), 1);
        assert_eq!(pending(&planned)[0].action(), &Action::Create);
    }
}
