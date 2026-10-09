use crate::domain::entry::Scope;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Install {
    Link,
    Copy,
}

impl Install {
    pub fn of(scope: Scope) -> Self {
        match scope {
            Scope::User => Install::Link,
            Scope::System => Install::Copy,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_entries_are_linked() {
        assert_eq!(Install::of(Scope::User), Install::Link);
    }

    #[test]
    fn system_entries_are_copied() {
        assert_eq!(Install::of(Scope::System), Install::Copy);
    }
}
