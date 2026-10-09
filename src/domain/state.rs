use std::path::PathBuf;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TargetState {
    Missing,
    UpToDate,
    Stale(PathBuf),
    Occupied,
}
