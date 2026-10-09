use crate::domain::entry::{Entry, Scope};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Selection {
    #[default]
    User,
    System,
    All,
}

impl Selection {
    pub fn includes(&self, scope: Scope) -> bool {
        matches!(
            (self, scope),
            (Selection::All, _)
                | (Selection::User, Scope::User)
                | (Selection::System, Scope::System)
        )
    }
}

pub fn filter(entries: &[Entry], selection: Selection) -> Vec<Entry> {
    entries
        .iter()
        .filter(|entry| selection.includes(entry.scope()))
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn entry(scope: Scope) -> Entry {
        Entry::new(PathBuf::from("/repo/a"), PathBuf::from("/destino/a"), scope)
    }

    fn both() -> Vec<Entry> {
        vec![entry(Scope::User), entry(Scope::System)]
    }

    #[test]
    fn default_selection_is_user() {
        assert_eq!(Selection::default(), Selection::User);
    }

    #[test]
    fn user_selection_drops_system_entries() {
        let kept = filter(&both(), Selection::User);
        assert_eq!(kept.len(), 1);
        assert_eq!(kept[0].scope(), Scope::User);
    }

    #[test]
    fn system_selection_drops_user_entries() {
        let kept = filter(&both(), Selection::System);
        assert_eq!(kept.len(), 1);
        assert!(kept[0].requires_root());
    }

    #[test]
    fn all_selection_keeps_everything() {
        assert_eq!(filter(&both(), Selection::All).len(), 2);
    }

    #[test]
    fn empty_input_yields_empty_output() {
        assert!(filter(&[], Selection::All).is_empty());
    }

    #[test]
    fn includes_matches_each_scope() {
        assert!(Selection::User.includes(Scope::User));
        assert!(!Selection::User.includes(Scope::System));
        assert!(Selection::System.includes(Scope::System));
        assert!(!Selection::System.includes(Scope::User));
        assert!(Selection::All.includes(Scope::User));
        assert!(Selection::All.includes(Scope::System));
    }
}
