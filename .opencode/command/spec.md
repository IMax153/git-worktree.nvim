---
description: Create a new spec file for the Ralph autonomous loop
---

# Create Spec

Create a new spec file in the `specs/` directory for the Ralph autonomous loop.

## Usage

```
/spec [description]
```

- `description` (optional) - High-level goal of the spec

## Instructions

### If description is provided

Generate all spec details from the description:

1. **Title** - Derive a clear, descriptive title from the goal
2. **Filename** - Generate kebab-case filename from the title (e.g., "Add unit tests for git module" → "unit-tests-git")
3. **Overview** - Expand the goal into 1-3 sentences
4. **Requirements** - Infer specific requirements needed to accomplish the goal
5. **Acceptance Criteria** - Derive criteria that define completion

**Do NOT ask for user input.** Generate everything autonomously.

### If description is NOT provided

Ask the user a single question: "What is the high-level goal of this spec?"

Then generate all details from their response as described above.

## Output

Create the spec file at `specs/<filename>.md` using this template:

```markdown
# <title>

## Overview

<overview>

## Requirements

- <requirement 1>
- <requirement 2>
- ...

## Acceptance Criteria

- [ ] <criterion 1>
- [ ] <criterion 2>
- ...

## Known Issues

_None yet_

## Status

- [ ] Not started
```

## After Creation

Confirm the spec was created and remind the user they can run the autonomous loop with:

```bash
./scripts/ralph-auto.sh
```
