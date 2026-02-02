# Linux System Management Toolkit (LSMT)

A lightweight, modular CLI toolkit designed for streamlined Linux system administration. LSMT consolidates essential GNU/Unix utilities into a single, extensible command-line interface.

## 🚀 Features

- **Centralized Entry Point**: Use `./lsmt` for all administrative tasks.
- **Modular Architecture**: Built with a "brain" dispatcher that routes commands to modular scripts in `lib/`.
- **Extensible**: Easily add new functionality by dropping Bash scripts into the `lib/` directory.
- **Built-in Documentation**: Access global help with `--help`.

## 📂 Project Structure

```text
.
├── lsmt              # The "Brain" (Main dispatcher script)
├── lib/              # Modular sub-scripts
│   └── health.sh     # System health monitoring module
└── README.md
```

## 🛠️ Usage

Ensure the scripts are executable:
```bash
chmod +x lsmt lib/*.sh
```

### Common Commands

**Show Help:**
```bash
./lsmt --help
```

**Monitor System Health:**
```bash
./lsmt health
```

## 🏗️ Adding New Modules

To add a new command (e.g., `disk`):
1.  Create a new script in the `lib/` folder: `lib/disk.sh`.
2.  Make the script executable: `chmod +x lib/disk.sh`.
3.  LSMT will automatically detect it: `./lsmt disk`.

---
*Developed for University CA Project - GNU Commands & System Management.*
