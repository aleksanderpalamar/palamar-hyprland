use crate::app::context::{Context, ContextError};
use crate::app::render::{describe, outcome_line, skipped_note};
use crate::domain::applier::apply;
use crate::domain::planner::{pending, plan};
use crate::domain::selection::{Selection, filter};
use crate::ports::{FileSystemReader, FileSystemWriter};

pub struct Options<'a> {
    pub selection: Selection,
    pub suffix: &'a str,
    pub dry_run: bool,
}

pub fn run(
    context: &Context,
    options: Options,
    reader: &dyn FileSystemReader,
    writer: &dyn FileSystemWriter,
) -> Result<bool, ContextError> {
    let all = context.entries()?;
    let chosen = filter(&all, options.selection);
    let planned = plan(&chosen, reader);
    let todo = pending(&planned);
    let note = skipped_note(all.len() - chosen.len(), options.selection);

    if todo.is_empty() {
        println!("nada a fazer");
        if let Some(note) = note {
            println!("{note}");
        }
        return Ok(true);
    }

    if options.dry_run {
        for item in todo {
            println!("{}", describe(item, context.home()));
        }
        if let Some(note) = note {
            println!("{note}");
        }
        return Ok(true);
    }

    let reports = apply(&planned, options.suffix, writer);
    let mut ok = true;

    for report in &reports {
        if report.failed() {
            ok = false;
        }
        println!("{}", outcome_line(report, context.home()));
    }

    if let Some(note) = note {
        println!("{note}");
    }

    Ok(ok)
}
