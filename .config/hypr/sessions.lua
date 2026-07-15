-- Static sessions that always appear in the session picker, regardless of
-- filesystem scanning.  Each entry maps a human-readable name to a directory
-- and a default workspace to focus when the session is activated.
-- This is the single source of truth — both session_picker.lua and
-- session-picker.sh read from here.

return {
  { name = 'global', dir = os.getenv('HOME'), default_workspace = 'term' },
}
