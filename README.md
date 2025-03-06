# Claude Desktop for Linux

This repository contains scripts to build and install Claude Desktop on Linux distributions, including Arch-based, RHEL-based, and Debian-based systems.

## About Claude Desktop

Claude Desktop is a native desktop application for Claude AI by Anthropic, providing access to Claude's AI capabilities with a dedicated interface. One of the main reasons to use the desktop client instead of the [Claude.ai website](https://claude.ai) is for MCP support, which allows your client to do things such as access your local file system and integrate with services the web client is unable to.

Anthropic does not provide Linux builds for the Claude Desktop client -- even though 99% of their infrastructure runs on Linux. This script simply takes the latest available Windows build, extracts it, and re-builds it.

## Requirements

The script will automatically install the required dependencies:
- p7zip
- nodejs
- rust
- cargo
- electron
- imagemagick
- icoutils
- wget
- pnpm (installed via curl)

## Installation

### Automated Installation (Recommended)

#### Arch Linux

1. Make the installation script executable:
   ```bash
   chmod +x install.sh
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

   To view all available options:
   ```bash
   ./install.sh --help
   ```

   If Claude Desktop is already installed, you can perform a clean installation:
   ```bash
   ./install.sh --clean-install
   ```

   To remove Claude Desktop:
   ```bash
   ./install.sh --remove
   ```

3. Follow the installation instructions displayed at the end of the build process.

This will:
- Install all required dependencies
- Build Claude Desktop from the Windows version
- Install the application to your user's local directory
- Set up the Claude protocol handler for authentication
- Add ~/.local/bin to your PATH if not already there

## Fixing Existing Installations

If you've already installed Claude Desktop but are experiencing issues with the app not launching or the desktop shortcut not working, simply run the install script with the `--clean-install` flag:

1. Make the fix script executable:
   ```bash
   chmod +x install.sh
   ```

2. Run the fix script:
   ```bash
   ./install.sh
   ```

## Troubleshooting

### Application not found in menu

If Claude Desktop doesn't appear in your application menu after installation:
- Try logging out and back in to refresh the XDG desktop entries
- Alternatively, you can run `claude-desktop` directly from a terminal which will give you extra insight if there are additional error messages

### Application won't launch

If Claude Desktop fails to launch, potential issues include:
- Missing the `en-US.json` file (fixed by reinstalling using the `install.sh` script)
- Incorrect electron path in the .desktop file (fixed by reinstalling using the `install.sh` script)
- Run the script with the `--clean-install` flag: `./install.sh --clean-install`

### Missing Dependencies

If you encounter any issues with missing dependencies, you can install them manually:

For Arch Linux:
```bash
sudo pacman -Sy --needed p7zip nodejs rust cargo electron imagemagick icoutils wget
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

For Debian/Ubuntu:
```bash
sudo apt-get install p7zip-full nodejs cargo rustc electron imagemagick icoutils
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

For RHEL/Fedora:
```bash
sudo dnf install p7zip p7zip-plugins nodejs rust cargo electron ImageMagick icoutils
curl -fsSL https://get.pnpm.io/install.sh | sh -
```

After you've installed all the dependencies run the script again.

### Path Issues

If you're unable to run `claude-desktop` from the terminal, ensure that `~/.local/bin` is in your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Uninstallation

To remove Claude Desktop from your system, simply run:
```bash
./install.sh --remove
```

All the binaries and libraries will be removed, but the config files will not be removed.

This will completely remove all Claude Desktop files from your system, including:
- Application files in `~/.local/lib/claude-desktop`
- Executable in `~/.local/bin/claude-desktop`
- Desktop entry in `~/.local/share/applications/claude-desktop.desktop`

## License

This project is licensed under dual MIT/Apache-2.0 license.
