pub mod action;
pub mod applier;
pub mod collector;
pub mod entry;
#[cfg(test)]
pub mod fake_fs;
pub mod filter;
pub mod install;
pub mod layout;
pub mod manifest;
pub mod packages;
pub mod placer;
pub mod planner;
pub mod report;
pub mod selection;
pub mod state;

pub use action::Action;
pub use applier::apply;
pub use entry::{Entry, Scope};
pub use install::Install;
pub use placer::Placer;
pub use planner::{PlannedEntry, pending, plan};
pub use report::{Outcome, Report};
pub use selection::{Selection, filter};
pub use state::TargetState;
