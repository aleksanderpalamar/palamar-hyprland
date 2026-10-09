use crate::domain::state::TargetState;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Action {
    Create,
    Replace,
    BackupAndCreate,
    AlreadyApplied,
}

impl Action {
    pub fn changes_system(&self) -> bool {
        !matches!(self, Action::AlreadyApplied)
    }
}

pub fn decide(state: &TargetState) -> Action {
    match state {
        TargetState::Missing => Action::Create,
        TargetState::UpToDate => Action::AlreadyApplied,
        TargetState::Stale(_) => Action::Replace,
        TargetState::Occupied => Action::BackupAndCreate,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn missing_target_is_created() {
        assert_eq!(decide(&TargetState::Missing), Action::Create);
    }

    #[test]
    fn up_to_date_target_needs_nothing() {
        assert_eq!(decide(&TargetState::UpToDate), Action::AlreadyApplied);
    }

    #[test]
    fn stale_target_is_replaced() {
        let other = PathBuf::from("/outro/destino");
        assert_eq!(decide(&TargetState::Stale(other)), Action::Replace);
    }

    #[test]
    fn occupied_target_is_backed_up_first() {
        assert_eq!(decide(&TargetState::Occupied), Action::BackupAndCreate);
    }

    #[test]
    fn only_already_applied_leaves_system_untouched() {
        assert!(!Action::AlreadyApplied.changes_system());
        assert!(Action::Create.changes_system());
        assert!(Action::BackupAndCreate.changes_system());
    }
}
