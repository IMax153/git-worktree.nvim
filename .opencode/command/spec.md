---
description: Create a new spec file for the Ralph autonomous loop
---

# Create Spec

Create a new spec file in the `specs/` directory for the Ralph autonomous loop.

## Instructions

Guide the user through creating a well-structured spec by gathering:

1. **Title** - A clear, descriptive title (e.g., "Add unit tests for git module")
2. **Filename** - A kebab-case filename without extension (e.g., "unit-tests-git")
3. **Overview** - Brief description of what this spec accomplishes (1-3 sentences)
4. **Requirements** - Specific requirements that must be implemented
5. **Acceptance Criteria** - Criteria that must be met for completion

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
