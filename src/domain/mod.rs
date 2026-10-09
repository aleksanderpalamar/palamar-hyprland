pub mod action;
pub mod applier;
pub mod collector;
pub mod entry;
#[cfg(test)]
pub mod fake_fs;
pub mod filter;
pub mod layout;
pub mod manifest;
pub mod packages;
pub mod planner;
pub mod report;
pub mod state;

pub use action::Action;
pub use applier::apply;
pub use entry::{Entry, Scope};
pub use planner::{PlannedEntry, pending, plan};
pub use report::{Outcome, Report};
pub use state::TargetState;
