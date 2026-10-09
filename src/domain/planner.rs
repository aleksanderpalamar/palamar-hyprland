use crate::domain::action::{Action, decide};
use crate::domain::entry::Entry;
use crate::domain::install::Install;
use crate::domain::state::TargetState;
use crate::ports::FileSystemReader;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlannedEntry {
    entry: Entry,
    action: Action,
    install: Install,
}

impl PlannedEntry {
    pub fn entry(&self) -> &Entry {
        &self.entry
    }

    pub fn action(&self) -> &Action {
        &self.action
    }

    pub fn install(&self) -> Install {
        self.install
    }
}

fn inspect_link(entry: &Entry, fs: &dyn FileSystemReader) -> TargetState {
    let Some(target) = fs.symlink_target(entry.target()) else {
        return match fs.exists(entry.target()) {
            true => TargetState::Occupied,
            false => TargetState::Missing,
        };
    };

    match target == entry.source() {
        true => TargetState::UpToDate,
        false => TargetState::Stale(target),
    }
}

fn inspect_copy(entry: &Entry, fs: &dyn FileSystemReader) -> TargetState {
    if let Some(target) = fs.symlink_target(entry.target()) {
        return TargetState::Stale(target);
    }

    if !fs.exists(entry.target()) {
        return TargetState::Missing;
    }

    match fs.same_content(entry.source(), entry.target()) {
        true => TargetState::UpToDate,
        false => TargetState::Occupied,
    }
}

pub fn inspect(entry: &Entry, fs: &dyn FileSystemReader) -> TargetState {
    match Install::of(entry.scope()) {
        Install::Link => inspect_link(entry, fs),
        Install::Copy => inspect_copy(entry, fs),
    }
}

pub fn plan(entries: &[Entry], fs: &dyn FileSystemReader) -> Vec<PlannedEntry> {
    entries
        .iter()
        .map(|entry| PlannedEntry {
            entry: entry.clone(),
            action: decide(&inspect(entry, fs)),
            install: Install::of(entry.scope()),
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
        assert_eq!(inspect(&entry(), &fs), TargetState::UpToDate);
    }

    #[test]
    fn symlink_elsewhere_keeps_the_current_target() {
        let fs = FakeFs::new().with_link(TARGET, "/opt/outro.lua");
        let esperado = TargetState::Stale(PathBuf::from("/opt/outro.lua"));
        assert_eq!(inspect(&entry(), &fs), esperado);
    }

    #[test]
    fn user_entries_are_planned_as_links() {
        assert_eq!(plan(&[entry()], &FakeFs::new())[0].install(), Install::Link);
    }

    #[test]
    fn system_entries_are_planned_as_copies() {
        let planned = plan(&[system_entry()], &FakeFs::new());
        assert_eq!(planned[0].install(), Install::Copy);
    }

    #[test]
    fn system_copy_with_equal_content_is_up_to_date() {
        let fs = FakeFs::new()
            .with_content(SYS_SOURCE, "LANG=pt_BR.UTF-8")
            .with_content(SYS_TARGET, "LANG=pt_BR.UTF-8");
        assert_eq!(inspect(&system_entry(), &fs), TargetState::UpToDate);
    }

    #[test]
    fn system_copy_with_other_content_is_occupied() {
        let fs = FakeFs::new()
            .with_content(SYS_SOURCE, "LANG=pt_BR.UTF-8")
            .with_content(SYS_TARGET, "LANG=C");
        assert_eq!(inspect(&system_entry(), &fs), TargetState::Occupied);
    }

    #[test]
    fn symlink_in_a_system_path_is_always_stale() {
        let fs = FakeFs::new().with_link(SYS_TARGET, SYS_SOURCE);
        let esperado = TargetState::Stale(PathBuf::from(SYS_SOURCE));
        assert_eq!(inspect(&system_entry(), &fs), esperado);
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
