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
