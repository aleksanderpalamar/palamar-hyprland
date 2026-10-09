use crate::app::context::{Context, ContextError};
use crate::domain::packages::{missing, parse, render, without};
use crate::ports::{Origin, PackageInstaller, PackageInventory};
use std::fs;
use std::path::PathBuf;

pub const DIR: &str = "packages";
pub const IGNORE: &str = "ignore.txt";

fn list_path(context: &Context, origin: Origin) -> PathBuf {
    context.repo().join(DIR).join(origin.file_name())
}

fn read_ignored(context: &Context) -> Vec<String> {
    match fs::read_to_string(context.repo().join(DIR).join(IGNORE)) {
        Ok(contents) => parse(&contents),
        Err(_) => Vec::new(),
    }
}

fn read_list(context: &Context, origin: Origin) -> Vec<String> {
    match fs::read_to_string(list_path(context, origin)) {
        Ok(contents) => parse(&contents),
        Err(_) => Vec::new(),
    }
}

pub fn capture(context: &Context, inventory: &dyn PackageInventory) -> Result<bool, ContextError> {
    let dir = context.repo().join(DIR);
    fs::create_dir_all(&dir).map_err(|error| ContextError::Unreadable(dir, error))?;

    let ignored = read_ignored(context);

    for origin in Origin::all() {
        let installed = inventory
            .installed(origin)
            .map_err(|error| ContextError::Unreadable(list_path(context, origin), error))?;
        let kept = without(&installed, &ignored);
        let path = list_path(context, origin);
        fs::write(&path, render(&kept)).map_err(|error| ContextError::Unreadable(path, error))?;
        println!(
            "{:<12} {} pacotes ({} ignorados)",
            origin.file_name(),
            kept.len(),
            installed.len() - kept.len()
        );
    }

    Ok(true)
}

pub fn status(context: &Context, inventory: &dyn PackageInventory) -> Result<bool, ContextError> {
    let mut complete = true;

    for origin in Origin::all() {
        let desired = read_list(context, origin);
        let installed = inventory
            .installed(origin)
            .map_err(|error| ContextError::Unreadable(list_path(context, origin), error))?;
        let absent = missing(&desired, &installed);

        println!(
            "{:<12} {} faltando de {}",
            origin.file_name(),
            absent.len(),
            desired.len()
        );
        for item in &absent {
            println!("  {item}");
        }

        if !absent.is_empty() {
            complete = false;
        }
    }

    Ok(complete)
}

pub fn install(
    context: &Context,
    inventory: &dyn PackageInventory,
    installer: &dyn PackageInstaller,
) -> Result<bool, ContextError> {
    for origin in Origin::all() {
        let desired = read_list(context, origin);
        let installed = inventory
            .installed(origin)
            .map_err(|error| ContextError::Unreadable(list_path(context, origin), error))?;
        let absent = missing(&desired, &installed);

        if absent.is_empty() {
            println!("{:<12} nada a instalar", origin.file_name());
            continue;
        }

        println!("{:<12} instalando {}", origin.file_name(), absent.len());
        installer
            .install(origin, &absent)
            .map_err(|error| ContextError::Unreadable(list_path(context, origin), error))?;
    }

    Ok(true)
}
