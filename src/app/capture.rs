use crate::app::context::{Context, ContextError};
use crate::domain::collector::collect;
use crate::domain::entry::Entry;
use crate::domain::layout::{scope_for, source_for};
use crate::domain::manifest::{expand, render};
use crate::ports::{FileCopier, FileSystemExplorer};
use serde::Deserialize;
use std::fs;
use std::path::PathBuf;

pub const SPEC: &str = "capture.toml";

#[derive(Debug, Deserialize, Default)]
pub struct CaptureSpec {
    #[serde(default)]
    pub include: Vec<String>,
    #[serde(default)]
    pub exclude: Vec<String>,
}

fn load_spec(context: &Context) -> Result<CaptureSpec, ContextError> {
    let path = context.repo().join(SPEC);
    let contents =
        fs::read_to_string(&path).map_err(|error| ContextError::Unreadable(path.clone(), error))?;
    toml::from_str(&contents).map_err(|error| ContextError::Manifest(error.into()))
}

fn roots(spec: &CaptureSpec, context: &Context) -> Result<Vec<PathBuf>, ContextError> {
    spec.include
        .iter()
        .map(|item| expand(item, context.home()).map_err(ContextError::from))
        .collect()
}

pub fn run(
    context: &Context,
    explorer: &dyn FileSystemExplorer,
    copier: &dyn FileCopier,
) -> Result<Vec<String>, ContextError> {
    let spec = load_spec(context)?;
    let targets = collect(&roots(&spec, context)?, &spec.exclude, explorer);

    let mut entries = Vec::new();
    let mut failures = Vec::new();

    for target in targets {
        let source = context.repo().join(source_for(&target, context.home()));
        match copier.copy_into(&target, &source) {
            Ok(()) => entries.push(Entry::new(
                source,
                target.clone(),
                scope_for(&target, context.home()),
            )),
            Err(error) => failures.push(format!("{}: {error}", target.display())),
        }
    }

    let text = render(&entries, context.repo(), context.home())?;
    let path = context.manifest_path();
    fs::write(&path, text).map_err(|error| ContextError::Unreadable(path, error))?;

    println!("{} arquivos capturados", entries.len());
    Ok(failures)
}
