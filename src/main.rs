use clap::Parser;
use palamar_hyprland::adapters::{RealFs, SystemPackages};
use palamar_hyprland::app::{Context, apply, capture, packages, status};
use palamar_hyprland::cli::{Cli, Command, PackagesAction};
use std::env;
use std::path::PathBuf;
use std::process::ExitCode;
use std::time::{SystemTime, UNIX_EPOCH};

fn repo_root(flag: Option<PathBuf>) -> PathBuf {
    flag.unwrap_or_else(|| env::current_dir().unwrap_or_else(|_| PathBuf::from(".")))
}

fn backup_suffix() -> String {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|value| value.as_secs())
        .unwrap_or_default();
    format!("bak.{seconds}")
}

fn main() -> ExitCode {
    let cli = Cli::parse();

    let context = match Context::discover(repo_root(cli.repo)) {
        Ok(context) => context,
        Err(error) => {
            eprintln!("{error}");
            return ExitCode::FAILURE;
        }
    };

    let fs = RealFs;
    let outcome = match cli.command {
        Command::Status => status::run(&context, &fs),
        Command::Apply { dry_run } => apply::run(&context, &backup_suffix(), dry_run, &fs, &fs),
        Command::Packages { action } => {
            let inventory = SystemPackages;
            match action {
                PackagesAction::Capture => packages::capture(&context, &inventory),
                PackagesAction::Status => packages::status(&context, &inventory),
                PackagesAction::Install => packages::install(&context, &inventory, &inventory),
            }
        }
        Command::Capture => capture::run(&context, &fs, &fs).map(|failures| {
            for failure in &failures {
                eprintln!("{failure}");
            }
            failures.is_empty()
        }),
    };

    match outcome {
        Ok(true) => ExitCode::SUCCESS,
        Ok(false) => ExitCode::FAILURE,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}
