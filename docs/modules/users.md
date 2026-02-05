### LSM Toolkit: Active Users Listing (LSMT-006)

This document describes the implementation of the Active Users Listing feature, part of the User Auditing module.

#### Overview
The `users` module provides a way to list all currently logged-in users on the system, displaying their username, terminal, login time, and host. It also supports filtering by a specific username.

#### Implementation Details
- **File**: `modules/users.sh`
- **Primary Tool**: `who`
- **Dispatcher Support**: The `bin/lsm-toolkit` was updated to correctly pass arguments to module functions, enabling the filtering feature.

#### How to Run

##### 1. Prerequisites
Ensure you have the toolkit on your machine.
```bash
git clone https://github.com/Ogenbertrand/linux-system-management-toolkit
cd linux-system-management-toolkit
chmod +x bin/lsm-toolkit
```

##### 2. Running the User List command
You can run the command directly from the repository:

**List all active users:**
```bash
./bin/lsm-toolkit users list
```

**Filter sessions for a specific user (e.g., 'bryan'):**
```bash
./bin/lsm-toolkit users list bryan
```

**Get help on the users module:**
```bash
./bin/lsm-toolkit users help
```

##### 3. Expected Output
When running `./bin/lsm-toolkit users list`, you should see an output similar to:
```
-----------------------------------------------
LSM Toolkit: Active Users Listing
-----------------------------------------------
Username   | Terminal   | Login Time         | Host
-----------------------------------------------
username   | tty7       | 2026-02-03 08:00   | (:0)
-----------------------------------------------
Total active sessions: 1
-----------------------------------------------
```

#### Ticket Requirements (LSMT-006)
- [x] Show username, terminal, login time, host
- [x] Handle multiple simultaneous sessions
- [x] Support optional filtering by username
- [x] Use `who` or `w` command

---

### LSM Toolkit: User Group Audit (LSMT-007)

This document describes the implementation of the User Group Audit feature.

#### Overview
The `users` module now supports auditing group memberships for all system users. This feature lists every user on the system along with the groups they belong to.

#### Implementation Details
- **File**: `modules/users.sh`
- **Function**: `users_groups`
- **Primary Tool**: `id` and `/etc/passwd` parsing
- **Logic**: Iterates through `/etc/passwd` to find all users, then runs `id -nG` for each to resolve group names.

#### How to Run

**Audit User Groups:**
```bash
./bin/lsm-toolkit users groups
```

#### Expected Output
```
-----------------------------------------------
LSM Toolkit: User Group Membership Audit
-----------------------------------------------
Username             | Groups
-----------------------------------------------
root                 | root
daemon               | daemon
bin                  | bin
arthur               | arthur adm cdrom sudo dip plugdev lpadmin sambashare docker libvirt
...
-----------------------------------------------
```

#### Ticket Requirements (LSMT-007)
- [x] List all groups per user
- [x] Handle system and regular users
- [x] Output in clear tabular format
- [x] Use `/etc/group` or `id` command
