#!/bin/sh

FACTORY_MP_CFG_FILE="/factory/mp_cfg.json"
USRDATA_MP_CFG_FILE="/usrdata/mp_cfg.json"

# Calculate MD5 value of a file
calculate_md5() {
    local file="$1"
    if [ -f "$file" ]; then
        # Use md5sum or similar tools
        if command -v md5sum >/dev/null 2>&1; then
            md5sum "$file" | cut -d' ' -f1
        elif command -v md5 >/dev/null 2>&1; then
            md5 -q "$file"
        elif command -v openssl >/dev/null 2>&1; then
            openssl md5 "$file" | cut -d' ' -f2
        else
            # If no MD5 tool, use file size as simple comparison
            stat -c%s "$file"
        fi
    else
        echo ""  # Return empty if file doesn't exist
    fi
}

# Compare MD5 values of two files
compare_files_md5() {
    local file1="$1"
    local file2="$2"
    
    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        return 2  # File doesn't exist
    fi
    
    local md5_1=$(calculate_md5 "$file1")
    local md5_2=$(calculate_md5 "$file2")
    
    if [ "$md5_1" = "$md5_2" ]; then
        return 0  # Same
    else
        return 1  # Different
    fi
}

# Safely copy file with verification
safe_copy_file() {
    local src="$1"
    local dst="$2"
    local desc="$3"
    
    echo "[INFO] cp: $src -> $dst"
    echo "  $desc"
    
    # First check disk space
    src_size=$(stat -c%s "$src" 2>/dev/null || echo 0)
    dst_dir=$(dirname "$dst")
    available_space=$(df -k "$dst_dir" 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
    available_space=$((available_space * 1024))  # Convert KB to bytes
    
    if [ "$src_size" -gt "$available_space" ]; then
        echo "[ERROR] Insufficient disk space: need $src_size bytes, available $available_space bytes" >&2
        return 1
    fi
    
    # Copy file
    if cp -p "$src" "$dst"; then
        # Verify copy result
        if compare_files_md5 "$src" "$dst"; then
            echo "[SUCCESS] File copy completed and verified successfully"
            return 0
        else
            echo "[ERROR] Copy verification failed: MD5 values don't match" >&2
            return 1
        fi
    else
        echo "[ERROR] Copy failed! Please check permissions or disk space" >&2
        return 1
    fi
}

sync_mp_cfg() {
    local factory_mp_cfg_file="$1"
    local usrdata_mp_cfg_file="$2"
    
    echo "=== Start syncing configuration files ==="
    
    # Check if files exist
    local factory_exists=0
    local usrdata_exists=0
    
    [ -f "$factory_mp_cfg_file" ] && factory_exists=1
    [ -f "$usrdata_mp_cfg_file" ] && usrdata_exists=1
    
    # Case 1: Both files exist
    if [ "$factory_exists" -eq 1 ] && [ "$usrdata_exists" -eq 1 ]; then
        echo "[INFO] Both configuration files exist"
        if compare_files_md5 "$factory_mp_cfg_file" "$usrdata_mp_cfg_file"; then
            echo "[INFO] Files have same content, no sync needed"
        else
            echo "[INFO] Files have different content, sync from factory to userdata"
            safe_copy_file "$factory_mp_cfg_file" "$usrdata_mp_cfg_file" "Factory config -> User data"
        fi
    
    # Case 2: Only factory config file exists
    elif [ "$factory_exists" -eq 1 ] && [ "$usrdata_exists" -eq 0 ]; then
        echo "[INFO] Only factory config file exists, copy to userdata"
        safe_copy_file "$factory_mp_cfg_file" "$usrdata_mp_cfg_file" "Factory config -> User data"
    
    # Case 3: Only userdata config file exists
    elif [ "$factory_exists" -eq 0 ] && [ "$usrdata_exists" -eq 1 ]; then
        echo "[INFO] Only userdata config file exists, copy to factory"
        safe_copy_file "$usrdata_mp_cfg_file" "$factory_mp_cfg_file" "User data -> Factory config"
    
    # Case 4: Neither file exists
    else
        echo "[ERROR] Both configuration files don't exist!" >&2
        echo "  $factory_mp_cfg_file: Not found" >&2
        echo "  $usrdata_mp_cfg_file: Not found" >&2
        return 1
    fi
    
    # Final sync
    sync
    echo "[INFO] Data synced to disk"
    echo "=== Sync completed ==="
    echo ""
}

# Main program
main() {
    # Ensure directories exist
    mkdir -p "$(dirname "$FACTORY_MP_CFG_FILE")" 2>/dev/null
    mkdir -p "$(dirname "$USRDATA_MP_CFG_FILE")" 2>/dev/null
    
    # Execute sync
    sync_mp_cfg "$FACTORY_MP_CFG_FILE" "$USRDATA_MP_CFG_FILE"
    
    # Show final status
    echo "=== Final status ==="
    [ -f "$FACTORY_MP_CFG_FILE" ] && \
        echo "Factory config: $FACTORY_MP_CFG_FILE ($(stat -c%s "$FACTORY_MP_CFG_FILE" 2>/dev/null || echo 0) bytes)" || \
        echo "Factory config: Not found"
    
    [ -f "$USRDATA_MP_CFG_FILE" ] && \
        echo "User data: $USRDATA_MP_CFG_FILE ($(stat -c%s "$USRDATA_MP_CFG_FILE" 2>/dev/null || echo 0) bytes)" || \
        echo "User data: Not found"
    
    # If both files exist, compare MD5
    if [ -f "$FACTORY_MP_CFG_FILE" ] && [ -f "$USRDATA_MP_CFG_FILE" ]; then
        if compare_files_md5 "$FACTORY_MP_CFG_FILE" "$USRDATA_MP_CFG_FILE"; then
            echo "Status: Both files have same content ✓"
        else
            echo "Status: Files have different content ✗"
        fi
    fi
}

# Run main program
main