use crate::ports::{FileCopier, FileSystemExplorer, FileSystemReader, FileSystemWriter};
use std::fs;
use std::io;
use std::os::unix;
use std::path::{Path, PathBuf};

pub struct RealFs;

impl FileSystemReader for RealFs {
    fn exists(&self, path: &Path) -> bool {
        path.symlink_metadata().is_ok()
    }

    fn symlink_target(&self, path: &Path) -> Option<PathBuf> {
        fs::read_link(path).ok()
    }

    fn same_content(&self, left: &Path, right: &Path) -> bool {
        match (fs::read(left), fs::read(right)) {
            (Ok(left), Ok(right)) => left == right,
            _ => false,
        }
    }
}

impl FileSystemWriter for RealFs {
    fn create_parent_dir(&self, path: &Path) -> io::Result<()> {
        let Some(parent) = path.parent() else {
            return Ok(());
        };
        fs::create_dir_all(parent)
    }

    fn move_aside(&self, path: &Path, suffix: &str) -> io::Result<PathBuf> {
        let saved = PathBuf::from(format!("{}.{}", path.display(), suffix));
        fs::rename(path, &saved)?;
        Ok(saved)
    }

    fn remove_symlink(&self, path: &Path) -> io::Result<()> {
        fs::remove_file(path)
    }

    fn symlink(&self, source: &Path, target: &Path) -> io::Result<()> {
        unix::fs::symlink(source, target)
    }
}

impl FileSystemExplorer for RealFs {
    fn exists(&self, path: &Path) -> bool {
        path.symlink_metadata().is_ok()
    }

    fn is_dir(&self, path: &Path) -> bool {
        path.is_dir()
    }

    fn children(&self, path: &Path) -> io::Result<Vec<PathBuf>> {
        let mut found = Vec::new();
        for item in fs::read_dir(path)? {
            found.push(item?.path());
        }
        Ok(found)
    }
}

impl FileCopier for RealFs {
    fn copy_into(&self, from: &Path, to: &Path) -> io::Result<()> {
        if let Some(parent) = to.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::copy(from, to)?;
        Ok(())
    }
}
