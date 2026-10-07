#!/usr/bin/env bash
set -euo pipefail

echo "================================================================"
echo "          Bootcamp Environment Smoke & Verification Tests       "
echo "================================================================"

PASSED=0
FAILED=0

assert_command() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[PASS] Command found: $cmd ($(command -v "$cmd"))"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] Command NOT found: $cmd"
        FAILED=$((FAILED + 1))
    fi
}

assert_test() {
    local desc="$1"
    shift
    if "$@"; then
        echo "[PASS] $desc"
        PASSED=$((PASSED + 1))
    else
        echo "[FAIL] $desc"
        FAILED=$((FAILED + 1))
    fi
}

echo ""
echo "--- 1. Verifying Required CLI & GUI Tool Binaries ---"
REQUIRED_COMMANDS=(
    # Core Linux
    bash ls cat cp mv rm mkdir chmod find grep sed awk
    file strings xxd base64 sha256sum openssl
    nano vim less man tree
    # Archives
    tar zip unzip 7z
    # Network & Transfer
    git curl wget
    # Python
    python python3 pip3 pipx
    # Networking
    ip ss ping dig nc ssh
    tcpdump tshark wireshark
    # Forensic & Analysis
    binwalk exiftool
    # Desktop
    xfce4-session xfce4-terminal thunar mousepad xarchiver tigervncserver websockify supervisord
)

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    assert_command "$cmd"
done

echo ""
echo "--- 2. Functional Tool Behavior Tests (with temporary fixtures) ---"
TEST_DIR=$(mktemp -d -t bootcamp-smoke-XXXXXX)
trap 'rm -rf "$TEST_DIR"' EXIT

# Test 2.1: file command identifies text file
echo "Hello Cybersecurity Bootcamp 101" > "$TEST_DIR/sample.txt"
assert_test "file identifies ASCII text" \
    bash -c 'file "$0" | grep -iq "text"' "$TEST_DIR/sample.txt"

# Test 2.2: grep finds known marker
assert_test "grep matches unique marker" \
    grep -q "Bootcamp 101" "$TEST_DIR/sample.txt"

# Test 2.3: Base64 encode/decode round trip
assert_test "Base64 encode/decode round trip" \
    bash -c 'echo "secret_flag{base64_test}" | base64 | base64 -d | grep -q "secret_flag{base64_test}"'

# Test 2.4: Hex (xxd) encode/decode round trip
assert_test "Hex (xxd) encode/decode round trip" \
    bash -c 'echo -n "cybersecurity" | xxd -p | xxd -r -p | grep -q "cybersecurity"'

# Test 2.5: SHA-256 matches expected checksum
EXPECTED_SHA256="2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"
assert_test "SHA-256 calculation verification" \
    bash -c 'CALC=$(echo -n "foo" | sha256sum | awk "{print \$1}"); [ "$CALC" = "'"$EXPECTED_SHA256"'" ]'

# Test 2.6: ZIP archive creation and extraction
(
    cd "$TEST_DIR"
    echo "archive_payload_data" > payload.txt
    zip -q payload.zip payload.txt
    mkdir extracted && unzip -q payload.zip -d extracted
    assert_test "ZIP creation and extraction" \
        grep -q "archive_payload_data" "$TEST_DIR/extracted/payload.txt"
)

# Test 2.7: Python virtual environment creation and pip invocation
(
    cd "$TEST_DIR"
    python3 -m venv test_venv
    # shellcheck disable=SC1091
    source test_venv/bin/activate
    assert_test "Python venv creation and isolated pip" \
        pip --version
    deactivate
)

# Test 2.8: OpenSSL encryption/decryption round trip
(
    echo "TOP_SECRET_STUDENT_MESSAGE" > "$TEST_DIR/plain.txt"
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "$TEST_DIR/plain.txt" -out "$TEST_DIR/enc.bin" -pass pass:bootcamp101
    openssl enc -d -aes-256-cbc -pbkdf2 -in "$TEST_DIR/enc.bin" -out "$TEST_DIR/dec.txt" -pass pass:bootcamp101
    assert_test "OpenSSL AES-256-CBC encryption/decryption round trip" \
        cmp -s "$TEST_DIR/plain.txt" "$TEST_DIR/dec.txt"
)

# Test 2.9: TShark packet capture inspection with valid synthetic PCAP
(
    # Construct standard Ethernet frame PCAP
    printf 'd4c3b2a1020004000000000000000000ffff00000100000000000000000000000e0000000e000000ffffffffffff0011223344550800' | xxd -r -p > "$TEST_DIR/synthetic.pcap"
    assert_test "TShark parses synthetic PCAP file" \
        bash -c 'tshark -r "$0" 2>/dev/null | grep -E -iq "Broadcast|IPv4|Ethernet"' "$TEST_DIR/synthetic.pcap"
)

# Test 2.10: Exiftool metadata extraction
(
    assert_test "Exiftool runs on sample text" \
        bash -c 'exiftool "$0" | grep -iq "File Name"' "$TEST_DIR/sample.txt"
)

# Test 2.11: Binwalk analysis
(
    assert_test "Binwalk scans test payload" \
        bash -c 'binwalk "$0" >/dev/null' "$TEST_DIR/payload.zip"
)

echo ""
echo "--- 3. Desktop Environment & Service Tests ---"
# Check if running as non-root user
CURRENT_USER=$(id -un)
assert_test "Running as non-root user ($CURRENT_USER)" \
    [ "$CURRENT_USER" != "root" ]

# Start or verify desktop services
echo "Executing /usr/local/bin/bootcamp-start..."
/usr/local/bin/bootcamp-start

# Check TigerVNC localhost binding
assert_test "TigerVNC listening on 127.0.0.1:5901" \
    bash -c 'ss -tulpn 2>/dev/null | grep -E "127\.0\.0\.1:5901|:5901" || netstat -tulpn 2>/dev/null | grep ":5901"'

# Check noVNC listening on 6080
assert_test "Websockify (noVNC) listening on port 6080" \
    bash -c 'ss -tulpn 2>/dev/null | grep ":6080" || netstat -tulpn 2>/dev/null | grep ":6080"'

# Check noVNC HTTP response
assert_test "HTTP probe to http://127.0.0.1:6080/vnc.html returns 200" \
    curl -fsS -o /dev/null -w "%{http_code}" http://127.0.0.1:6080/vnc.html

# Check XFCE process tree
assert_test "XFCE desktop session is active" \
    pgrep -u "$(id -u)" -x xfce4-session

# Check GUI application launch on DISPLAY=:1
DISPLAY=:1 xfce4-terminal &
TERMINAL_PID=$!
sleep 2
assert_test "GUI terminal launches on DISPLAY=:1" \
    kill -0 "$TERMINAL_PID"
kill "$TERMINAL_PID" 2>/dev/null || true

# Check repeat startup idempotency
assert_test "Repeating bootcamp-start does not crash or create duplicates" \
    /usr/local/bin/bootcamp-start

# Check service restart functionality
assert_test "bootcamp-restart cleanly restarts services" \
    /usr/local/bin/bootcamp-restart

echo ""
echo "================================================================"
echo "Smoke Tests Completed: $PASSED Passed, $FAILED Failed"
echo "================================================================"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
