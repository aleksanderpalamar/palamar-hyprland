use clap::{Parser, Subcommand};
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
    Status,
    Apply {
        #[arg(long)]
        dry_run: bool,
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
