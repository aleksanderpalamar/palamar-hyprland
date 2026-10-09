use crate::app::context::{Context, ContextError};
use crate::app::render::{describe, skipped_note};
use crate::domain::planner::{pending, plan};
use crate::domain::selection::{Selection, filter};
use crate::ports::FileSystemReader;

pub fn run(
    context: &Context,
    selection: Selection,
    fs: &dyn FileSystemReader,
) -> Result<bool, ContextError> {
    let all = context.entries()?;
    let chosen = filter(&all, selection);
    let planned = plan(&chosen, fs);
    let todo = pending(&planned);

    for item in &planned {
        println!("{}", describe(item, context.home()));
    }

    println!();
    println!("{} entradas, {} pendentes", planned.len(), todo.len());

    if let Some(note) = skipped_note(all.len() - chosen.len(), selection) {
        println!("{note}");
    }

    Ok(todo.is_empty())
}
