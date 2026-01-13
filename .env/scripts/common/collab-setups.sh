#!/usr/bin/env bash
set -euo pipefail

########################################
# SAFETY
########################################
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)" >&2
  exit 1
fi

########################################
# INTERACTIVE INPUT
########################################
read -rp "Workspace path (e.g. /ws): " WORKDIR
read -rp "Collaboration group name: " GROUP
read -rp "Comma-separated users to ADD (e.g. admin,keeperos): " USERS
read -rp "Allow non-group users read access? (yes/no): " PUBLIC_READ

########################################
# NORMALIZE
########################################
IFS=',' read -ra USER_LIST <<< "$USERS"

########################################
# CREATE GROUP
########################################
if ! getent group "$GROUP" >/dev/null; then
  groupadd "$GROUP"
  echo "Created group: $GROUP"
else
  echo "Group exists: $GROUP"
fi

########################################
# CREATE WORKDIR
########################################
mkdir -p "$WORKDIR"

########################################
# OWNERSHIP + BASE PERMS
########################################
chown root:"$GROUP" "$WORKDIR"

if [[ "$PUBLIC_READ" == "yes" ]]; then
  chmod 2775 "$WORKDIR"
else
  chmod 2770 "$WORKDIR"
fi

########################################
# ADD USERS TO GROUP
########################################
for U in "${USER_LIST[@]}"; do
  if id "$U" &>/dev/null; then
    usermod -aG "$GROUP" "$U"
    echo "Added $U to $GROUP"
  else
    echo "User does not exist: $U"
  fi
done

########################################
# ACL HARDENING (OPTIONAL BUT STRONG)
########################################
if command -v setfacl >/dev/null; then
  setfacl -m g::rwx "$WORKDIR"
  setfacl -d -m g::rwx "$WORKDIR"

  if [[ "$PUBLIC_READ" == "yes" ]]; then
    setfacl -m o::rx "$WORKDIR"
    setfacl -d -m o::rx "$WORKDIR"
  else
    setfacl -m o::--- "$WORKDIR"
    setfacl -d -m o::--- "$WORKDIR"
  fi

  echo "ACLs applied"
else
  echo "ACL tools not installed; using POSIX perms only"
fi

########################################
# FIX EXISTING CONTENT (SAFE)
########################################
find "$WORKDIR" -type d -exec chmod g+rws {} +
find "$WORKDIR" -type f -exec chmod g+rw {} +

########################################
# SUMMARY
########################################
echo
echo "===== SETUP COMPLETE ====="
ls -ld "$WORKDIR"
getent group "$GROUP"
echo
echo "NOTE: Users must log out/in for group changes to apply."
