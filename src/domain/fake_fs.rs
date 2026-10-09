use crate::ports::{FileSystemExplorer, FileSystemReader, FileSystemWriter};
use std::cell::RefCell;
use std::collections::HashMap;
use std::io;
use std::path::{Path, PathBuf};

#[derive(Default)]
pub struct FakeFs {
    links: HashMap<PathBuf, PathBuf>,
    files: Vec<PathBuf>,
    dirs: HashMap<PathBuf, Vec<PathBuf>>,
    log: RefCell<Vec<String>>,
    symlink_fails: bool,
}

impl FakeFs {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_dir(mut self, path: &str, children: &[&str]) -> Self {
        let base = PathBuf::from(path);
        let list = children.iter().map(|name| base.join(name)).collect();
        self.dirs.insert(base, list);
        self
    }

    pub fn with_file(mut self, path: &str) -> Self {
        self.files.push(PathBuf::from(path));
        self
    }

    pub fn with_link(mut self, path: &str, target: &str) -> Self {
        self.links
            .insert(PathBuf::from(path), PathBuf::from(target));
        self
    }

    pub fn failing_symlink(mut self) -> Self {
        self.symlink_fails = true;
        self
    }

    pub fn log(&self) -> Vec<String> {
        self.log.borrow().clone()
    }

    fn record(&self, line: String) {
        self.log.borrow_mut().push(line);
    }
}

impl FakeFs {
    fn has(&self, path: &Path) -> bool {
        self.files.iter().any(|item| item == path)
            || self.links.contains_key(path)
            || self.dirs.contains_key(path)
    }
}

impl FileSystemExplorer for FakeFs {
    fn exists(&self, path: &Path) -> bool {
        self.has(path)
    }

    fn is_dir(&self, path: &Path) -> bool {
        self.dirs.contains_key(path)
    }

    fn children(&self, path: &Path) -> io::Result<Vec<PathBuf>> {
        match self.dirs.get(path) {
            Some(list) => Ok(list.clone()),
            None => Err(io::Error::other("nao e diretorio")),
        }
    }
}

impl FileSystemReader for FakeFs {
    fn exists(&self, path: &Path) -> bool {
        self.has(path)
    }

    fn symlink_target(&self, path: &Path) -> Option<PathBuf> {
        self.links.get(path).cloned()
    }
}

impl FileSystemWriter for FakeFs {
    fn create_parent_dir(&self, path: &Path) -> io::Result<()> {
        self.record(format!("mkdir {}", path.display()));
        Ok(())
    }

    fn move_aside(&self, path: &Path, suffix: &str) -> io::Result<PathBuf> {
        let saved = PathBuf::from(format!("{}.{}", path.display(), suffix));
        self.record(format!("backup {}", saved.display()));
        Ok(saved)
    }

    fn remove_symlink(&self, path: &Path) -> io::Result<()> {
        self.record(format!("unlink {}", path.display()));
        Ok(())
    }

    fn symlink(&self, source: &Path, target: &Path) -> io::Result<()> {
        if self.symlink_fails {
            return Err(io::Error::other("sem permissão"));
        }
        self.record(format!("link {} -> {}", target.display(), source.display()));
        Ok(())
    }
}
