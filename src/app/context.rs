use crate::domain::entry::Entry;
use crate::domain::manifest::{self, ManifestError};
use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use thiserror::Error;

pub const MANIFEST: &str = "manifest.toml";

#[derive(Debug, Error)]
pub enum ContextError {
    #[error("HOME não definido")]
    MissingHome,
    #[error("não foi possível ler {0}: {1}")]
    Unreadable(PathBuf, io::Error),
    #[error(transparent)]
    Manifest(#[from] ManifestError),
}

pub struct Context {
    repo: PathBuf,
    home: PathBuf,
}

impl Context {
    pub fn discover(repo: PathBuf) -> Result<Self, ContextError> {
        let home = env::var_os("HOME")
            .map(PathBuf::from)
            .ok_or(ContextError::MissingHome)?;
        Ok(Self { repo, home })
    }

    pub fn repo(&self) -> &Path {
        &self.repo
    }

    pub fn home(&self) -> &Path {
        &self.home
    }

    pub fn manifest_path(&self) -> PathBuf {
        self.repo.join(MANIFEST)
    }

    pub fn entries(&self) -> Result<Vec<Entry>, ContextError> {
        let path = self.manifest_path();
        let contents = fs::read_to_string(&path)
            .map_err(|error| ContextError::Unreadable(path.clone(), error))?;
        Ok(manifest::parse(&contents, &self.repo, &self.home)?)
    }
}
