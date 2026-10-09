use std::path::PathBuf;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Outcome {
    Unchanged,
    Linked,
    Replaced,
    BackedUp(PathBuf),
    Failed(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Report {
    target: PathBuf,
    outcome: Outcome,
}

impl Report {
    pub fn new(target: PathBuf, outcome: Outcome) -> Self {
        Self { target, outcome }
    }

    pub fn target(&self) -> &PathBuf {
        &self.target
    }

    pub fn outcome(&self) -> &Outcome {
        &self.outcome
    }

    pub fn failed(&self) -> bool {
        matches!(self.outcome, Outcome::Failed(_))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn failed_only_for_failure_outcome() {
        let target = PathBuf::from("/home/palamar/.config/mako/config");
        assert!(Report::new(target.clone(), Outcome::Failed("erro".into())).failed());
        assert!(!Report::new(target, Outcome::Linked).failed());
    }
}
