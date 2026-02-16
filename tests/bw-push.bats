#!/usr/bin/env bats
# Tests for bw-push script

setup() {
    # Create isolated test environment
    export TEST_TMPDIR=$(mktemp -d)
    export HOME="$TEST_TMPDIR/home"
    mkdir -p "$HOME/.ssh"

    # Create stub directory
    export STUB_DIR="$TEST_TMPDIR/stubs"
    mkdir -p "$STUB_DIR"
    export PATH="$STUB_DIR:$PATH"

    # Create rbw stub
    cat > "$STUB_DIR/rbw" << 'EOSTUB'
#!/bin/bash
case "$1" in
    unlocked)
        exit 0
        ;;
    get)
        if [[ "$2" == "--field=private_key" && "$3" == "SSH rodlc" ]]; then
            # rbw get --field=private_key "SSH rodlc"
            if [[ -n "${MOCK_RBW_SSH_MULTIPLE:-}" ]]; then
                echo "multiple entries found" >&2
                exit 1
            elif [[ -n "${MOCK_RBW_SSH_KEY:-}" ]]; then
                echo "$MOCK_RBW_SSH_KEY"
                exit 0
            else
                exit 1
            fi
        elif [[ "$2" == "SSH rodlc" ]]; then
            # rbw get "SSH rodlc" (fallback to secure note)
            if [[ -n "${MOCK_RBW_SSH_MULTIPLE:-}" ]]; then
                echo "multiple entries found" >&2
                exit 1
            elif [[ -n "${MOCK_RBW_SSH_KEY:-}" ]]; then
                echo "$MOCK_RBW_SSH_KEY"
                exit 0
            else
                exit 1
            fi
        elif [[ "$2" == "Dotfiles Env" ]]; then
            if [[ -n "${MOCK_RBW_ENV:-}" ]]; then
                echo "$MOCK_RBW_ENV"
                exit 0
            else
                exit 1
            fi
        fi
        exit 1
        ;;
esac
EOSTUB
    chmod +x "$STUB_DIR/rbw"

    # Create ssh-keygen stub (returns fixed fingerprint)
    cat > "$STUB_DIR/ssh-keygen" << 'EOSTUB'
#!/bin/bash
if [[ "$1" == "-lf" ]]; then
    if [[ "$2" == "/dev/stdin" ]]; then
        # Read from stdin
        cat > /dev/null
    fi
    echo "256 SHA256:abc123fingerprint user@host (ED25519)"
fi
EOSTUB
    chmod +x "$STUB_DIR/ssh-keygen"

    # Create pbcopy stub
    cat > "$STUB_DIR/pbcopy" << 'EOSTUB'
#!/bin/bash
cat > "$TEST_TMPDIR/pbcopy_content"
EOSTUB
    chmod +x "$STUB_DIR/pbcopy"

    # Create editor stub (no-op)
    export EDITOR="$STUB_DIR/true"
    cat > "$STUB_DIR/true" << 'EOSTUB'
#!/bin/bash
exit 0
EOSTUB
    chmod +x "$STUB_DIR/true"

    # Create test SSH key
    export TEST_SSH_KEY="$HOME/.ssh/id_ed25519_rodlc"
    # gitleaks:allow
    echo "-----BEGIN OPENSSH PRIVATE KEY-----
test_local_key_content
-----END OPENSSH PRIVATE KEY-----" > "$TEST_SSH_KEY"

    # Create .env file (in sync by default)
    export TEST_ENV_CONTENT="FOO=bar
BAZ=qux"
    echo "$TEST_ENV_CONTENT" > "$HOME/.env"
    export MOCK_RBW_ENV="$TEST_ENV_CONTENT"
}

teardown() {
    rm -rf "$TEST_TMPDIR"
}

@test "SSH key absent in Bitwarden → pbcopy + instructions" {
    # SSH key not in Bitwarden
    unset MOCK_RBW_SSH_KEY

    run bash "${BATS_TEST_DIRNAME}/../scripts/code/bw-push"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Bitwarden item not found" ]]
    [[ "$output" =~ "Action required" ]]

    # Verify pbcopy was called with local key
    [ -f "$TEST_TMPDIR/pbcopy_content" ]
    grep -q "test_local_key_content" "$TEST_TMPDIR/pbcopy_content"
}

@test "SSH key mismatch → warning + pbcopy" {
    # Different key in Bitwarden
    # gitleaks:allow
    export MOCK_RBW_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
different_bw_key_content
-----END OPENSSH PRIVATE KEY-----"

    run bash "${BATS_TEST_DIRNAME}/../scripts/code/bw-push"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "local ≠ Bitwarden" ]]
    [[ "$output" =~ "Action required" ]]

    # Verify pbcopy was called
    [ -f "$TEST_TMPDIR/pbcopy_content" ]
    grep -q "test_local_key_content" "$TEST_TMPDIR/pbcopy_content"
}

@test "SSH key in sync → no action" {
    # Same key in Bitwarden
    # gitleaks:allow
    export MOCK_RBW_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
test_local_key_content
-----END OPENSSH PRIVATE KEY-----"

    run bash "${BATS_TEST_DIRNAME}/../scripts/code/bw-push"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "SSH rodlc in sync" ]]

    # Verify pbcopy was NOT called
    [ ! -f "$TEST_TMPDIR/pbcopy_content" ]
}

@test "SSH key multiple entries → error message" {
    # Multiple entries in Bitwarden
    export MOCK_RBW_SSH_MULTIPLE=1

    run bash "${BATS_TEST_DIRNAME}/../scripts/code/bw-push"

    [ "$status" -eq 0 ]
    [[ "$output" =~ "multiple Bitwarden entries found" ]]
    [[ "$output" =~ "Delete the duplicate entry" ]]

    # Verify pbcopy was NOT called
    [ ! -f "$TEST_TMPDIR/pbcopy_content" ]
}
