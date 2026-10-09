pub fn parse(contents: &str) -> Vec<String> {
    contents
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(str::to_owned)
        .collect()
}

pub fn render(items: &[String]) -> String {
    let mut sorted = items.to_vec();
    sorted.sort();
    sorted.dedup();
    match sorted.is_empty() {
        true => String::new(),
        false => format!("{}\n", sorted.join("\n")),
    }
}

pub fn without(items: &[String], ignored: &[String]) -> Vec<String> {
    items
        .iter()
        .filter(|item| !ignored.contains(item))
        .cloned()
        .collect()
}

pub fn missing(desired: &[String], installed: &[String]) -> Vec<String> {
    desired
        .iter()
        .filter(|item| !installed.contains(item))
        .cloned()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn list(items: &[&str]) -> Vec<String> {
        items.iter().map(|item| item.to_string()).collect()
    }

    #[test]
    fn parse_skips_comments_and_blanks() {
        let text = "# pacotes\nhyprland\n\n  waybar  \n";
        assert_eq!(parse(text), list(&["hyprland", "waybar"]));
    }

    #[test]
    fn parse_of_empty_text_is_empty() {
        assert!(parse("").is_empty());
    }

    #[test]
    fn render_sorts_and_deduplicates() {
        assert_eq!(
            render(&list(&["waybar", "hyprland", "waybar"])),
            "hyprland\nwaybar\n"
        );
    }

    #[test]
    fn render_of_empty_list_has_no_newline() {
        assert_eq!(render(&[]), "");
    }

    #[test]
    fn missing_keeps_only_absent_packages() {
        let desired = list(&["hyprland", "waybar", "mako"]);
        let installed = list(&["waybar"]);
        assert_eq!(missing(&desired, &installed), list(&["hyprland", "mako"]));
    }

    #[test]
    fn nothing_is_missing_when_all_installed() {
        let desired = list(&["hyprland"]);
        assert!(missing(&desired, &list(&["hyprland", "waybar"])).is_empty());
    }

    #[test]
    fn without_drops_ignored_packages() {
        let items = list(&["hyprland", "astra-browser", "waybar"]);
        let ignored = list(&["astra-browser"]);
        assert_eq!(without(&items, &ignored), list(&["hyprland", "waybar"]));
    }

    #[test]
    fn without_empty_ignore_keeps_everything() {
        let items = list(&["hyprland"]);
        assert_eq!(without(&items, &[]), items);
    }

    #[test]
    fn render_and_parse_round_trip() {
        let original = list(&["fuzzel", "hyprland", "mako"]);
        assert_eq!(parse(&render(&original)), original);
    }
}
