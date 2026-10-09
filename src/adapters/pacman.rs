use crate::domain::packages::parse;
use crate::ports::{Origin, PackageInstaller, PackageInventory};
use std::io;
use std::process::Command;

pub struct SystemPackages;

fn command_for(origin: Origin) -> (&'static str, Vec<&'static str>) {
    match origin {
        Origin::Repository => ("pacman", vec!["-Qqen"]),
        Origin::Aur => ("pacman", vec!["-Qqem"]),
        Origin::Flatpak => ("flatpak", vec!["list", "--app", "--columns=application"]),
    }
}

fn run(program: &str, args: &[&str]) -> io::Result<Vec<String>> {
    let output = match Command::new(program).args(args).output() {
        Ok(output) => output,
        Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(Vec::new()),
        Err(error) => return Err(error),
    };

    if !output.status.success() {
        return Err(io::Error::other(format!("{program} falhou")));
    }

    Ok(parse(&String::from_utf8_lossy(&output.stdout)))
}

impl PackageInventory for SystemPackages {
    fn installed(&self, origin: Origin) -> io::Result<Vec<String>> {
        let (program, args) = command_for(origin);
        run(program, &args)
    }
}

fn installer_for(origin: Origin) -> (&'static str, Vec<&'static str>) {
    match origin {
        Origin::Repository => ("sudo", vec!["pacman", "-S", "--needed", "--noconfirm"]),
        Origin::Aur => ("yay", vec!["-S", "--needed", "--noconfirm"]),
        Origin::Flatpak => ("flatpak", vec!["install", "-y", "flathub"]),
    }
}

impl PackageInstaller for SystemPackages {
    fn install(&self, origin: Origin, items: &[String]) -> io::Result<()> {
        if items.is_empty() {
            return Ok(());
        }

        let (program, base) = installer_for(origin);
        let status = Command::new(program).args(&base).args(items).status()?;

        match status.success() {
            true => Ok(()),
            false => Err(io::Error::other(format!("{program} falhou"))),
        }
    }
}
