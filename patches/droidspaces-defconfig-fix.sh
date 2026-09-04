#!/bin/bash
# Droidspaces kernel config fixes for E404 SM8250
# This script patches all vendor defconfigs to enable Droidspaces support
# Copyright (C) 2026 - Based on Droidspaces-OSS kernel configuration guide

set -euo pipefail

DEFCONFIG_DIR="${1:-arch/arm64/configs/vendor}"

echo "=== Applying Droidspaces fixes to defconfigs in $DEFCONFIG_DIR ==="

# List of defconfigs to patch (clang variants)
DEFCONFIGS=(
    "alioth_defconfig"
    "apollo_defconfig"
    "cas_defconfig"
    "cmi_defconfig"
    "elish_defconfig"
    "enuma_defconfig"
    "lmi_defconfig"
    "munch_defconfig"
    "pipa_defconfig"
    "thyme_defconfig"
    "umi_defconfig"
)

# Function to set a config option
# If option exists as "# CONFIG_X is not set", change to "CONFIG_X=y"
# If option exists as "CONFIG_X=y" or "CONFIG_X=n", leave it
# If option doesn't exist, append it
set_config() {
    local file="$1"
    local config="$2"
    local value="$3"

    if grep -q "^${config}=" "$file"; then
        # Option exists with a value - update it
        sed -i "s|^${config}=.*|${config}=${value}|" "$file"
    elif grep -q "^# ${config} is not set" "$file"; then
        # Option is explicitly disabled - enable it
        sed -i "s|^# ${config} is not set|${config}=${value}|" "$file"
    else
        # Option doesn't exist - append it
        echo "${config}=${value}" >> "$file"
    fi
}

for defconfig in "${DEFCONFIGS[@]}"; do
    filepath="$DEFCONFIG_DIR/$defconfig"
    if [[ ! -f "$filepath" ]]; then
        echo "  SKIP: $defconfig not found"
        continue
    fi

    echo "  Patching: $defconfig"

    # === CRITICAL: Android Paranoid Network ===
    # Without this, networking inside containers is completely blocked
    # "socket: permission denied" on all AF_INET operations
    set_config "$filepath" "CONFIG_ANDROID_PARANOID_NETWORK" "n"

    # === CRITICAL: Cgroup Device ===
    # Without this, Droidspaces cannot set up /dev inside containers
    set_config "$filepath" "CONFIG_CGROUP_DEVICE" "y"

    # === Namespaces & IPC ===
    set_config "$filepath" "CONFIG_POSIX_MQUEUE" "y"
    set_config "$filepath" "CONFIG_USER_NS" "y"

    # === Cgroup support ===
    set_config "$filepath" "CONFIG_CGROUP_PIDS" "y"
    set_config "$filepath" "CONFIG_MEMCG" "y"
    set_config "$filepath" "CONFIG_FAIR_GROUP_SCHED" "y"

    # === Filesystem ===
    set_config "$filepath" "CONFIG_OVERLAY_FS" "y"
    set_config "$filepath" "CONFIG_TMPFS_POSIX_ACL" "y"
    set_config "$filepath" "CONFIG_TMPFS_XATTR" "y"

    # === Firmware ===
    set_config "$filepath" "CONFIG_FW_LOADER_COMPRESS" "y"

    # === Networking (NAT mode support) ===
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_TARGET_MASQUERADE" "y"
    set_config "$filepath" "CONFIG_NF_CONNTRACK_NETLINK" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_STATE" "y"

    # === Firewall support (UFW/Fail2ban) ===
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_COMMENT" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_CONNTRACK" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_MULTIPORT" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_HL" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_TARGET_REJECT" "y"
    set_config "$filepath" "CONFIG_IP_NF_TARGET_REJECT" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_TARGET_LOG" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_RECENT" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_LIMIT" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_HASHLIMIT" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_OWNER" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_PKTTYPE" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_MATCH_MARK" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_TARGET_MARK" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_TARGET_NFLOG" "y"

    # === IP Set support (Fail2ban) ===
    set_config "$filepath" "CONFIG_IP_SET" "y"
    set_config "$filepath" "CONFIG_IP_SET_HASH_IP" "y"
    set_config "$filepath" "CONFIG_IP_SET_HASH_NET" "y"
    set_config "$filepath" "CONFIG_NETFILTER_XT_SET" "y"

    # === Netfilter queue/logging ===
    set_config "$filepath" "CONFIG_NETFILTER_NETLINK_QUEUE" "y"
    set_config "$filepath" "CONFIG_NETFILTER_NETLINK_LOG" "y"

    echo "  Done: $defconfig"
done

echo ""
echo "=== Droidspaces fixes applied successfully ==="
echo ""
echo "Changes summary:"
echo "  - CONFIG_ANDROID_PARANOID_NETWORK=n (fix network blocking)"
echo "  - CONFIG_CGROUP_DEVICE=y (fix container /dev setup)"
echo "  - CONFIG_USER_NS=y (fix Docker unsafe procfs)"
echo "  - CONFIG_POSIX_MQUEUE=y (IPC support)"
echo "  - CONFIG_CGROUP_PIDS=y (PID cgroup tracking)"
echo "  - CONFIG_MEMCG=y (memory limits per container)"
echo "  - CONFIG_FAIR_GROUP_SCHED=y (fair CPU scheduling)"
echo "  - CONFIG_OVERLAY_FS=y (volatile mode support)"
echo "  - CONFIG_TMPFS_POSIX_ACL/XATTR=y (NixOS support)"
echo "  - CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y (NAT support)"
echo "  - CONFIG_NETFILTER_XT_TARGET_MASQUERADE=y (NAT/MASQUERADE)"
echo "  - CONFIG_IP_SET=y + hash (Fail2ban support)"
echo "  - Firewall/UFW configs enabled"
