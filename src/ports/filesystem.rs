use std::io;
use std::path::{Path, PathBuf};

pub trait FileSystemReader {
    fn exists(&self, path: &Path) -> bool;
    fn symlink_target(&self, path: &Path) -> Option<PathBuf>;
}

pub trait FileSystemWriter {
    fn create_parent_dir(&self, path: &Path) -> io::Result<()>;
    fn move_aside(&self, path: &Path, suffix: &str) -> io::Result<PathBuf>;
    fn remove_symlink(&self, path: &Path) -> io::Result<()>;
    fn symlink(&self, source: &Path, target: &Path) -> io::Result<()>;
}

pub trait FileSystemExplorer {
    fn exists(&self, path: &Path) -> bool;
    fn is_dir(&self, path: &Path) -> bool;
    fn children(&self, path: &Path) -> io::Result<Vec<PathBuf>>;
}

pub trait FileCopier {
    fn copy_into(&self, from: &Path, to: &Path) -> io::Result<()>;
}
