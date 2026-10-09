use crate::app::context::{Context, ContextError};
use crate::app::render::{describe, outcome_line};
use crate::domain::applier::apply;
use crate::domain::planner::{pending, plan};
use crate::ports::{FileSystemReader, FileSystemWriter};

pub fn run(
    context: &Context,
    suffix: &str,
    dry_run: bool,
    reader: &dyn FileSystemReader,
    writer: &dyn FileSystemWriter,
) -> Result<bool, ContextError> {
    let entries = context.entries()?;
    let planned = plan(&entries, reader);
    let todo = pending(&planned);

    if todo.is_empty() {
        println!("nada a fazer");
        return Ok(true);
    }

    if dry_run {
        for item in todo {
            println!("{}", describe(item, context.home()));
        }
        return Ok(true);
    }

    let reports = apply(&planned, suffix, writer);
    let mut ok = true;

    for report in &reports {
        if report.failed() {
            ok = false;
        }
        println!("{}", outcome_line(report, context.home()));
    }

    Ok(ok)
}
