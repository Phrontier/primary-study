# Contents Policy

`Contents/` is the app's retained study-asset corpus, not a general dump for every source reference.

What stays in `Contents/`:
- phase content under `1. FAM (Contacts)` through `5. CAPSTONE`
- app-served shared reference documents that the manifest links directly
- `FlashcardImages/` assets used by flashcards

What does not stay in `Contents/`:
- admin/archive/reference material that is not surfaced by the app
- one-off working files, course rosters, legacy slide decks, and local scratch prep

Local archive workflow:
- move non-app reference material into `ReferenceArchive/`
- `ReferenceArchive/` is ignored by git and is not bundled into the app

Git/LFS guardrail:
- retained binary assets in `Contents/` are tracked with Git LFS
- if a new document is only for local reference, archive it instead of recommitting it into `Contents/`
