use std::io;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Origin {
    Repository,
    Aur,
    Flatpak,
}

impl Origin {
    pub fn file_name(&self) -> &'static str {
        match self {
            Origin::Repository => "pacman.txt",
            Origin::Aur => "aur.txt",
            Origin::Flatpak => "flatpak.txt",
        }
    }

    pub fn all() -> [Origin; 3] {
        [Origin::Repository, Origin::Aur, Origin::Flatpak]
    }
}

pub trait PackageInventory {
    fn installed(&self, origin: Origin) -> io::Result<Vec<String>>;
}

pub trait PackageInstaller {
    fn install(&self, origin: Origin, items: &[String]) -> io::Result<()>;
}
