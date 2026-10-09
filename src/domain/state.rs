use std::path::PathBuf;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TargetState {
    Missing,
    LinkedToSource,
    LinkedElsewhere(PathBuf),
    Occupied,
}
