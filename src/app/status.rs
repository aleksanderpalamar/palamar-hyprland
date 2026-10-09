use crate::app::context::{Context, ContextError};
use crate::app::render::describe;
use crate::domain::planner::{pending, plan};
use crate::ports::FileSystemReader;

pub fn run(context: &Context, fs: &dyn FileSystemReader) -> Result<bool, ContextError> {
    let entries = context.entries()?;
    let planned = plan(&entries, fs);
    let todo = pending(&planned);

    for item in &planned {
        println!("{}", describe(item, context.home()));
    }

    println!();
    println!("{} entradas, {} pendentes", planned.len(), todo.len());
    Ok(todo.is_empty())
}
