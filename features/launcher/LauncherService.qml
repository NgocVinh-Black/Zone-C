pragma Singleton

import QtQuick
import Quickshell
import qs.core.config
import "LauncherLogic.js" as Logic
import "schema.js" as Schema

// The desktop entry database, ranked for the launcher popup.
Singleton {
    id: root

    readonly property var settings: Config.feature("launcher", Schema.fields)

    // Flattened into plain objects so ranking stays a pure function; `entry` keeps
    // the real DesktopEntry for launching and its icon.
    readonly property var entries: DesktopEntries.applications.values.filter(entry => !entry.noDisplay).map(entry => ({
                name: entry.name,
                comment: entry.comment,
                keywords: entry.keywords,
                categories: entry.categories,
                icon: entry.icon,
                entry: entry
            }))

    function search(query: string): var {
        return Logic.search(entries, query, settings.maxResults);
    }

    function launch(item: var): void {
        const entry = item?.entry;
        if (!entry)
            return;
        if (entry.runInTerminal)
            Quickshell.execDetached(settings.terminal.concat(entry.command));
        else
            entry.execute();
    }
}
