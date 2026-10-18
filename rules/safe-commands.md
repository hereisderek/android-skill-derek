# Command execution and safety

Before executing any command, evaluate its impact and follow these guidelines by command type.

## 1. Read-only commands

Execute normally.

## 2. Modification commands (state-altering)

- **Visibility:** state the exact command you are executing. After it runs, show the resulting output or confirmation.
- **Explanation:** if the command is complex (chained commands, heavy use of flags, regex, unfamiliar binaries), give a brief 1-2 sentence explanation of what it will do before running it.

## 3. Destructive or dangerous commands

For any command that deletes, overwrites, formats, or makes system-wide irreversible changes (for example `rm`, `drop`, `truncate`, `kill`), pause, explain the command and its risks, and ask for explicit user confirmation. Do not execute the command until the user says "yes".
