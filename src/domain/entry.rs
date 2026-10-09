use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Scope {
    User,
    System,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Entry {
    source: PathBuf,
    target: PathBuf,
    scope: Scope,
}

impl Entry {
    pub fn new(source: PathBuf, target: PathBuf, scope: Scope) -> Self {
        Self {
            source,
            target,
            scope,
        }
    }

    pub fn source(&self) -> &Path {
        &self.source
    }

    pub fn target(&self) -> &Path {
        &self.target
    }

    pub fn scope(&self) -> Scope {
        self.scope
    }

    pub fn requires_root(&self) -> bool {
        matches!(self.scope, Scope::System)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(scope: Scope) -> Entry {
        Entry::new(PathBuf::from("/repo/a"), PathBuf::from("/home/a"), scope)
    }

    #[test]
    fn user_scope_does_not_require_root() {
        assert!(!entry(Scope::User).requires_root());
    }

    #[test]
    fn system_scope_requires_root() {
        assert!(entry(Scope::System).requires_root());
    }
}
