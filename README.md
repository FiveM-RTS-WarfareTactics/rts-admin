# RTS Admin - Administration Panel

Full-featured admin/mod/support moderation panel for Enyo RTS servers.

**Dependencies:** `enyo-rts`, `oxmysql`

## Permission Levels
| Level | ACE | Capabilities |
|-------|-----|-------------|
| Admin | `command.rtsadmin` | Ban, kick, mute, terminate matches, end all matches, kick all, admin mode |
| Mod | `command.rtsmod` | Kick, mute, clear mutes, announcements, bucket TP, admin mode |
| Support | `command.rtssupport` | Mute/unmute, view data |

## Features
- **Player management**: kick, ban (timed/permanent with custom date/time), mute (duration modal)
- **Server actions**: end all matches, kick all players, clear all mutes, server announcements
- **Map builder**: architect mode with laser-guided placement (Enter to build, F9 cancel)
- **Map loading**: load existing maps directly into builder with all objects/objectives/spawns
- **Admin mode**: random police ped model, weapon, patrol vehicle, F11/N noclip toggle
- **Match spectating**: per-match from the Matches tab
- **Live action log broadcast** to all staff
- **Modern dark-theme UI** with sidebar navigation and tab system
- **F10 keybind** to toggle panel

## Commands
| Command | Key | Description |
|---------|-----|-------------|
| `/admin` | F10 | Open admin panel |
| `rts_noclip` | N | Toggle noclip in admin mode |
| | F9 | Exit admin/architect mode |
| | Enter | Confirm architect placement |

## Keybinds
| Key | Context | Action |
|-----|---------|--------|
| F10 | Anywhere | Toggle admin panel |
| F9 | Admin/Architect | Exit mode, return to RTS |
| N | Admin mode | Toggle noclip |
| Enter | Architect mode | Confirm builder placement |
| WASD | Admin/Architect | Movement |

## Exports (Server)
```lua
exports['rts-admin']:GetPermissionLevel(src)        -- Permission level
exports['rts-admin']:HasPerm(src, level)             -- Permission check
exports['rts-admin']:IsPlayerMuted(pid)              -- Check if player is muted
```

## Events
| Event | Type | Description |
|---|---|---|
| `rts-admin:openPanel` | Client | Open admin panel |
| `enyo-rts:showRTS` | Client (triggered) | Show RTS menu after closing admin |
| `rts-mapbuilder:loadMapData` | Client (triggered) | Send map data to builder |

## License
Apache 2.0
