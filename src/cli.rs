use crate::domain::selection::Selection;
use clap::{Parser, Subcommand, ValueEnum};
use std::path::PathBuf;

#[derive(Parser)]
#[command(
    name = "palamar-hyprland",
    version,
    about = "Replica o ambiente Hyprland"
)]
pub struct Cli {
    #[arg(long, value_name = "DIR", env = "PALAMAR_HYPRLAND_REPO")]
    pub repo: Option<PathBuf>,

    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand)]
pub enum Command {
    Status {
        #[arg(long, value_enum, default_value_t = ScopeArg::User)]
        scope: ScopeArg,
    },
    Apply {
        #[arg(long)]
        dry_run: bool,

        #[arg(long, value_enum, default_value_t = ScopeArg::User)]
        scope: ScopeArg,
    },
    Capture,
    Packages {
        #[command(subcommand)]
        action: PackagesAction,
    },
}

#[derive(Subcommand)]
pub enum PackagesAction {
    Capture,
    Status,
    Install,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
pub enum ScopeArg {
    User,
    System,
    All,
}

impl From<ScopeArg> for Selection {
    fn from(arg: ScopeArg) -> Self {
        match arg {
            ScopeArg::User => Selection::User,
            ScopeArg::System => Selection::System,
            ScopeArg::All => Selection::All,
        }
    }
}
