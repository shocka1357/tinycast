---
title: Aliases
description: Give anything in the launcher a short name of your own that wins when you type it.
---

An alias is your own name for a launcher entry. Type `ps` and get Photoshop. Type `sh` and get the
shell script you run every morning.

Aliases work on **any** entry: apps, System Settings panes, commands, Quick Actions, quicklinks,
snippets, system actions, window commands and layouts, and extension commands.

## Setting one

Open **Settings → Aliases** to see every alias in one place, search the list, remove an alias, or
choose **Add Alias…** to find any launcher item and name it. The same controls also remain in the
item's own settings pane, and both views stay synchronized.

Every pane that lists launcher
items has one, including Applications, System Settings, System Actions, Commands, Quicklinks,
Quick Actions and each feature's own command list. For an extension, it sits beside each command's
shortcut in **Settings → Extensions**.

One alias per entry. The field has a clear button and a bolt. Turn the bolt on to make the alias
instant: typing the complete alias launches the entry without waiting for Return. A partial match
still only filters the list, and aliases whose bolt is off behave exactly as before.

This is on purpose not in the <kbd>⌘</kbd><kbd>K</kbd> menu. Naming something is a setting you choose
once, not something you do in the middle of a search.

## How an alias ranks

- **Typing the whole alias exactly always wins**, whatever you picked before and whatever else has
  that name.
- **Typing the start of an alias** ranks just above names that start the same way. Something you
  pick very often can still move ahead of it.
- A match in the **middle** of an alias ranks like the other names an app is known by.
- **Scattered letters never match an alias.** `ps` will not match an alias of `Pixelmator Studio` by
  skipping letters, because that would make short aliases useless.

The first rule is the point: a two-letter alias should win outright, or it is not worth setting.

## In the list

An entry with an alias shows it as a small tag after the name, so you can see at a glance which
entries you have named.

## Backups and cleanup

Aliases and their instant setting are included in [backups](/docs/reference/backup).

An alias goes away with the thing it names. Uninstall the app, delete the quicklink or remove the
extension, and the alias goes too, instead of lingering and matching nothing.

Raycast exports carry an alias per command. The [importer](/docs/reference/import-from-raycast)
brings the ones for apps across.
