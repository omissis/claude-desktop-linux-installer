#!/bin/bash
# Make executable with: chmod +x install.sh
#
# All-in-one script for Claude Desktop on Arch Linux
#
# This script will:
# 1. Install required dependencies
# 2. Download and build Claude Desktop for Linux
# 3. Install the application to the user's local application directory
#
# Usage: ./install.sh
#        ./install.sh --clean-install
#        ./install.sh --remove
#        ./install.sh --help

set -euo pipefail

# Configuration
CLAUDE_VERSION="0.7.8"
CLAUDE_URL="https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/claude-build"
OUTPUT_DIR="${SCRIPT_DIR}/claude-desktop"

# Logging functions
log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

log_warning() {
    echo -e "\033[0;33m[WARNING]\033[0m $1"
}

# Error handling
handle_error() {
    log_error "An error occurred on line $1"
    exit 1
}

trap 'handle_error $LINENO' ERR

# Display help menu
show_help() {
    echo -e "Claude Desktop for Arch Linux Installation Script"
    echo -e "Usage: ${0} [OPTION]"
    echo -e "\nOptions:"
    echo -e "  --help\t\tShow this help menu"
    echo -e "  --install\t\tInstall Claude Desktop (default if no option is provided)"
    echo -e "  --clean-install\tRemove existing installation and install fresh"
    echo -e "  --remove\t\tUninstall Claude Desktop completely"
    echo -e "\nExamples:"
    echo -e "  ${0}\t\t\tInstall Claude Desktop"
    echo -e "  ${0} --clean-install\tPerform a clean installation"
    echo -e "  ${0} --remove\t\tRemove Claude Desktop"
    echo -e "\nFor more information, visit: https://github.com/astrosteveo/claude-desktop-linux-bash"
}

# Check if running on Arch Linux
check_arch_linux() {
    if [ ! -f /etc/arch-release ]; then
        log_error "This script is intended for Arch Linux systems only."
        exit 1
    fi
}

# Check for the correct ImageMagick command
check_image_command() {
    if command -v magick >/dev/null 2>&1; then
        IMAGE_CMD="magick"
    elif command -v convert >/dev/null 2>&1; then
        IMAGE_CMD="convert"
    else
        return 1
    fi
    return 0
}

# Install required dependencies
install_dependencies() {
    log_info "Installing required dependencies..."
    
    # Define required packages
    local REQUIRED_PACKAGES="p7zip nodejs rust cargo electron imagemagick icoutils wget"
    
    # Check if packages are already installed
    local PACKAGES_TO_INSTALL=()
    for pkg in $REQUIRED_PACKAGES; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            PACKAGES_TO_INSTALL+=("$pkg")
        fi
    done
    
    # Install missing packages
    if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        log_info "Installing packages: ${PACKAGES_TO_INSTALL[*]}"
        sudo pacman -Sy --needed --noconfirm ${PACKAGES_TO_INSTALL[@]}
    else
        log_info "All required packages are already installed."
    fi
    
    # Install pnpm if not already installed
    if ! command -v pnpm &> /dev/null; then
        log_info "Installing pnpm..."
        curl -fsSL https://get.pnpm.io/install.sh | sh -
        
        # Source pnpm in the current session
        export PNPM_HOME="${HOME}/.local/share/pnpm"
        export PATH="${PNPM_HOME}:${PATH}"
        
        # Check if pnpm was installed correctly
        if ! command -v pnpm &> /dev/null; then
            log_error "Failed to install pnpm. Please install it manually: curl -fsSL https://get.pnpm.io/install.sh | sh -"
            exit 1
        fi
    fi

    # Check for required tools after installation
    log_info "Checking for required tools..."
    local deps=("7za" "pnpm" "node" "cargo" "rustc" "electron" "wrestool" "icotool")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    # Check for either magick or convert
    if ! check_image_command; then
        missing+=("ImageMagick")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Still missing required dependencies: ${missing[*]}"
        exit 1
    fi
}

# Remove existing installation
remove_existing_installation() {
    log_info "Removing existing Claude Desktop installation..."
    rm -rf "${HOME}/.local/lib/claude-desktop"
    rm -f "${HOME}/.local/bin/claude-desktop"
    rm -f "${HOME}/.local/share/applications/claude-desktop.desktop"
    
    # Remove icon files
    find "${HOME}/.local/share/icons" -name "claude.png" -delete
    
    # Reset protocol handler
    xdg-mime default "" x-scheme-handler/claude 2>/dev/null || true
    
    log_info "Claude Desktop has been successfully removed."
}

# Create and setup the patchy-cnb native module
setup_patchy_cnb() {
    log_info "Setting up patchy-cnb native module..."
    mkdir -p "$WORK_DIR/patchy-cnb"
    cd "$WORK_DIR/patchy-cnb"
    
    # Create Cargo.toml with minimal dependencies
    cat > Cargo.toml << 'EOF'
[package]
name = "patchy-cnb"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
napi = { version = "2.12.2", default-features = false, features = ["napi4"] }
napi-derive = "2.12.2"
EOF

    # Create stub implementation for native bindings
    mkdir -p src
    cat > src/lib.rs << 'EOF'
#![deny(clippy::all)]

#[macro_use]
extern crate napi_derive;

#[napi]
pub enum KeyboardKey {
    Num0,
    Num1,
    Num2,
    Num3,
    Num4,
    Num5,
    Num6,
    Num7,
    Num8,
    Num9,
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    I,
    J,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z,
    AbntC1,
    AbntC2,
    Accept,
    Add,
    Alt,
    Apps,
    Attn,
    Backspace,
    Break,
    Begin,
    BrightnessDown,
    BrightnessUp,
    BrowserBack,
    BrowserFavorites,
    BrowserForward,
    BrowserHome,
    BrowserRefresh,
    BrowserSearch,
    BrowserStop,
    Cancel,
    CapsLock,
    Clear,
    Command,
    ContrastUp,
    ContrastDown,
    Control,
    Convert,
    Crsel,
    DBEAlphanumeric,
    DBECodeinput,
    DBEDetermineString,
    DBEEnterDLGConversionMode,
    DBEEnterIMEConfigMode,
    DBEEnterWordRegisterMode,
    DBEFlushString,
    DBEHiragana,
    DBEKatakana,
    DBENoCodepoint,
    DBENoRoman,
    DBERoman,
    DBESBCSChar,
    DBESChar,
    Decimal,
    Delete,
    Divide,
    DownArrow,
    Eject,
    End,
    Ereof,
    Escape,
    Execute,
    Excel,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    F7,
    F8,
    F9,
    F10,
    F11,
    F12,
    F13,
    F14,
    F15,
    F16,
    F17,
    F18,
    F19,
    F20,
    F21,
    F22,
    F23,
    F24,
    F25,
    F26,
    F27,
    F28,
    F29,
    F30,
    F31,
    F32,
    F33,
    F34,
    F35,
    Function,
    Final,
    Find,
    GamepadA,
    GamepadB,
    GamepadDPadDown,
    GamepadDPadLeft,
    GamepadDPadRight,
    GamepadDPadUp,
    GamepadLeftShoulder,
    GamepadLeftThumbstickButton,
    GamepadLeftThumbstickDown,
    GamepadLeftThumbstickLeft,
    GamepadLeftThumbstickRight,
    GamepadLeftThumbstickUp,
    GamepadLeftTrigger,
    GamepadMenu,
    GamepadRightShoulder,
    GamepadRightThumbstickButton,
    GamepadRightThumbstickDown,
    GamepadRightThumbstickLeft,
    GamepadRightThumbstickRight,
    GamepadRightThumbstickUp,
    GamepadRightTrigger,
    GamepadView,
    GamepadX,
    GamepadY,
    Hangeul,
    Hangul,
    Hanja,
    Help,
    Home,
    Ico00,
    IcoClear,
    IcoHelp,
    IlluminationDown,
    IlluminationUp,
    IlluminationToggle,
    IMEOff,
    IMEOn,
    Insert,
    Junja,
    Kana,
    Kanji,
    LaunchApp1,
    LaunchApp2,
    LaunchMail,
    LaunchMediaSelect,
    Launchpad,
    LaunchPanel,
    LButton,
    LControl,
    LeftArrow,
    Linefeed,
    LMenu,
    LShift,
    LWin,
    MButton,
    MediaFast,
    MediaNextTrack,
    MediaPlayPause,
    MediaPrevTrack,
    MediaRewind,
    MediaStop,
    Meta,
    MissionControl,
    ModeChange,
    Multiply,
    NavigationAccept,
    NavigationCancel,
    NavigationDown,
    NavigationLeft,
    NavigationMenu,
    NavigationRight,
    NavigationUp,
    NavigationView,
    NoName,
    NonConvert,
    None,
    Numlock,
    Numpad0,
    Numpad1,
    Numpad2,
    Numpad3,
    Numpad4,
    Numpad5,
    Numpad6,
    Numpad7,
    Numpad8,
    Numpad9,
    OEM1,
    OEM102,
    OEM2,
    OEM3,
    OEM4,
    OEM5,
    OEM6,
    OEM7,
    OEM8,
    OEMAttn,
    OEMAuto,
    OEMAx,
    OEMBacktab,
    OEMClear,
    OEMComma,
    OEMCopy,
    OEMCusel,
    OEMEnlw,
    OEMFinish,
    OEMFJJisho,
    OEMFJLoya,
    OEMFJMasshou,
    OEMFJRoya,
    OEMFJTouroku,
    OEMJump,
    OEMMinus,
    OEMNECEqual,
    OEMPA1,
    OEMPA2,
    OEMPA3,
    OEMPeriod,
    OEMPlus,
    OEMReset,
    OEMWsctrl,
    Option,
    PA1,
    Packet,
    PageDown,
    PageUp,
    Pause,
    Play,
    Power,
    Print,
    Processkey,
    RButton,
    RCommand,
    RControl,
    Redo,
    Return,
    RightArrow,
    RMenu,
    ROption,
    RShift,
    RWin,
    Scroll,
    ScrollLock,
    Select,
    ScriptSwitch,
    Separator,
    Shift,
    ShiftLock,
    Sleep,
    Snapshot,
    Space,
    Subtract,
    Super,
    SysReq,
    Tab,
    Undo,
    UpArrow,
    VidMirror,
    VolumeDown,
    VolumeMute,
    VolumeUp,
    MicMute,
    Windows,
    XButton1,
    XButton2,
    Zoom,
}

#[napi]
pub enum ScrollDirection {
    Down = 0,
    Up = 1,
}

#[napi]
pub enum MouseButton {
    Left = 0,
    Middle = 1,
    Right = 2,
}

#[napi]
pub struct MousePosition {
    pub x: u32,
    pub y: u32,
}

#[napi]
pub enum RequestAccessibilityOptions {
    ShowDialog,
    OnlyRegisterInSettings,
}

#[napi]
pub struct MonitorInfo {
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
    pub monitor_name: String,
    pub is_primary: bool,
}

#[napi]
pub struct WindowInfo {
    pub handle: u32,
    pub process_id: u32,
    pub executable_path: String,
    pub title: String,
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}

#[napi]
pub fn request_accessibility(options: i32) -> bool {
    println!("request_accessibility {options}");
    true
}

#[napi]
pub fn get_window_info() -> Vec<WindowInfo> {
    println!("get_window_info");
    vec![]
}

#[napi]
pub fn get_active_window_handle() -> u32 {
    println!("get_active_window_handle");
    0
}

#[napi]
pub fn get_monitor_info() -> MonitorInfo {
    println!("get_monitor_info");
    MonitorInfo {
        x: 0,
        y: 0,
        width: 1920,
        height: 1080,
        monitor_name: "\\\\.\\DISPLAY1".to_string(),
        is_primary: true,
    }
}

#[napi]
pub fn focus_window(handle: u32) {
    println!("focus_window {handle}");
}

#[napi(constructor)]
pub struct InputEmulator {}

#[napi]
impl InputEmulator {
    #[napi]
    pub fn copy(&self) {
        println!("IE copy");
    }

    #[napi]
    pub fn cut(&self) {
        println!("IE cut");
    }

    #[napi]
    pub fn paste(&self) {
        println!("IE paste");
    }

    #[napi]
    pub fn undo(&self) {
        println!("IE undo");
    }

    #[napi]
    pub fn select_all(&self) {
        println!("IE select all");
    }

    #[napi]
    pub fn held(&self) -> Vec<u16> {
        println!("IE held");
        vec![]
    }

    #[napi]
    pub fn press_chars(&self, text: String) {
        println!("IE press chars '{text}'");
    }

    #[napi]
    pub fn press_key(&self, key: Vec<i32>) {
        println!("IE press key {key:?}");
    }

    #[napi]
    pub fn press_then_release_key(key: Vec<i32>) {
        println!("IE press then release key {key:?}");
    }

    #[napi]
    pub fn release_chars(&self, text: String) {
        println!("IE release chars '{text}'");
    }

    #[napi]
    pub fn release_key(&self, key: u32) {
        println!("IE release key {key}");
    }

    #[napi]
    pub fn set_button_click(&self, button: i32) {
        println!("IE set button click {button}");
    }

    #[napi]
    pub fn set_button_toggle(&self, button: i32) {
        println!("IE set button toggle {button}");
    }

    #[napi]
    pub fn get_mouse_position(&self) -> MousePosition {
        println!("IE get mouse position");
        MousePosition { x: 0, y: 0 }
    }

    #[napi]
    pub fn type_text(&self, text: String) {
        println!("IE type text '{text}'");
    }

    #[napi]
    pub fn set_mouse_scroll(&self, direction: i32, amount: i32) {
        println!("IE set mouse scroll {direction} {amount}");
    }
}
EOF

    # Create package.json
    cat > package.json << EOF
{
  "name": "patchy-cnb",
  "version": "0.1.0",
  "main": "index.js",
  "napi": {
    "name": "patchy-cnb",
    "triples": {
      "defaults": false,
      "additional": [
        "x86_64-unknown-linux-gnu"
      ]
    }
  },
  "scripts": {
    "build": "napi build --platform --release"
  },
  "devDependencies": {
    "@napi-rs/cli": "^2.18.4"
  }
}
EOF

    # Build native module with error handling
    log_info "Building native module..."
    if ! pnpm install; then
        log_error "Failed to install dependencies for native module"
        exit 1
    fi

    if ! pnpm run build; then
        log_error "Failed to build native module"
        exit 1
    fi

    # Verify build output
    if [ ! -f "patchy-cnb.linux-x64-gnu.node" ]; then
        log_error "Native module build failed - output file not found"
        exit 1
    fi
}

# Download and extract the Windows client
download_and_extract() {
    log_info "Downloading Claude Desktop..."
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    if [ ! -f "Claude-Setup-x64.exe" ]; then
        wget "$CLAUDE_URL" -O "Claude-Setup-x64.exe" || {
            log_error "Failed to download Claude Desktop"
            exit 1
        }
    fi
    
    log_info "Extracting..."
    7z x -y "Claude-Setup-x64.exe" || {
        log_error "Failed to extract Claude-Setup-x64.exe"
        exit 1
    }
    
    # Find the actual nupkg file instead of assuming the name
    NUPKG_FILE=$(find . -name "*.nupkg" | head -n 1)
    if [ -z "$NUPKG_FILE" ]; then
        log_error "Could not find .nupkg file"
        exit 1
    fi
    
    7z x -y "$NUPKG_FILE" || {
        log_error "Failed to extract $NUPKG_FILE"
        exit 1
    }
}

# Process icons
process_icons() {
    log_info "Processing icons..."
    cd "$WORK_DIR"
    
    wrestool -x -t 14 "lib/net45/claude.exe" -o claude.ico || {
        log_error "Failed to extract icons from claude.exe"
        exit 1
    }
    
    icotool -x claude.ico || {
        log_error "Failed to convert ico file"
        exit 1
    }
    
    mkdir -p "$OUTPUT_DIR/share/icons/hicolor"
    for size in 16 24 32 48 64 256; do
        mkdir -p "$OUTPUT_DIR/share/icons/hicolor/${size}x${size}/apps"
        $IMAGE_CMD "claude_*${size}x${size}x32.png" \
            "$OUTPUT_DIR/share/icons/hicolor/${size}x${size}/apps/claude.png" || {
            log_warning "Failed to convert icon for size ${size}x${size}"
        }
    done
}

# Process and repackage app.asar
process_asar() {
    log_info "Processing app.asar..."
    cd "$WORK_DIR"
    
    mkdir -p "$OUTPUT_DIR/lib/claude-desktop"
    cp "lib/net45/resources/app.asar" "$OUTPUT_DIR/lib/claude-desktop/" || {
        log_error "Failed to copy app.asar"
        exit 1
    }
    
    cp -r "lib/net45/resources/app.asar.unpacked" "$OUTPUT_DIR/lib/claude-desktop/" || {
        log_error "Failed to copy app.asar.unpacked"
        exit 1
    }
    
    cd "$OUTPUT_DIR/lib/claude-desktop"
    npx asar extract app.asar app.asar.contents || {
        log_error "Failed to extract app.asar"
        exit 1
    }
    
    # Replace native bindings
    cp "$WORK_DIR/patchy-cnb/patchy-cnb.linux-x64-gnu.node" \
        "app.asar.contents/node_modules/claude-native/claude-native-binding.node" || {
        log_error "Failed to copy native binding to app.asar.contents"
        exit 1
    }
    
    cp "$WORK_DIR/patchy-cnb/patchy-cnb.linux-x64-gnu.node" \
        "app.asar.unpacked/node_modules/claude-native/claude-native-binding.node" || {
        log_error "Failed to copy native binding to app.asar.unpacked"
        exit 1
    }
    
    # Copy Tray icons
    mkdir -p app.asar.contents/resources
    cp "$WORK_DIR/lib/net45/resources/Tray"* app.asar.contents/resources/ || {
        log_error "Failed to copy tray icons"
        exit 1
    }
    
    # Create the missing i18n file
    log_info "Creating missing i18n file..."
    mkdir -p "app.asar.contents/resources/i18n"
    echo "{}" > "app.asar.contents/resources/i18n/en-US.json"
    
    # Repackage app.asar
    npx asar pack app.asar.contents app.asar || {
        log_error "Failed to repackage app.asar"
        exit 1
    }
}

# Create launcher script
create_launcher() {
    log_info "Creating launcher script..."
    mkdir -p "$OUTPUT_DIR/bin"
    
    # Get the path to electron cli.js
    ELECTRON_CLI_PATH=$(find $(pnpm -g root) -name "cli.js" -path "*/electron/*" | head -n 1)
    if [ -z "$ELECTRON_CLI_PATH" ]; then
        log_warning "Could not find electron cli.js, using default path"
        ELECTRON_CLI_PATH="$(pnpm -g root)/electron/cli.js"
    fi
    log_info "Using electron CLI path: $ELECTRON_CLI_PATH"
    
    cat > "$OUTPUT_DIR/bin/claude-desktop" << EOF
#!/bin/bash
# Generated by Copilot

# Ensure ~/.local/bin is in PATH for tools like uvx
export PATH="\$HOME/.local/bin:\$PATH"

# Set icon and app name parameters
ICON_PARAMS="--icon=\$HOME/.local/share/icons/hicolor/256x256/apps/claude.png --app-name=Claude"

# Set Wayland parameters if needed
WAYLAND_PARAMS=""
if [ -n "\$WAYLAND_DISPLAY" ]; then
    WAYLAND_PARAMS="--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations"
fi

# Launch with electron directly, ensuring icon comes first
electron "\$HOME/.local/lib/claude-desktop/app.asar" \$ICON_PARAMS \$WAYLAND_PARAMS "\$@"
EOF
    chmod +x "$OUTPUT_DIR/bin/claude-desktop"
}

# Install Claude Desktop to user's local application directory
install_claude_desktop() {
    log_info "Installing Claude Desktop to user's local directories..."
    
    # Get the path to electron cli.js
    ELECTRON_CLI_PATH=$(find $(pnpm -g root) -name "cli.js" -path "*/electron/*" | head -n 1)
    if [ -z "$ELECTRON_CLI_PATH" ]; then
        log_warning "Could not find electron cli.js, using default path"
        ELECTRON_CLI_PATH="$(pnpm -g root)/electron/cli.js"
    fi
    log_info "Using electron CLI path: $ELECTRON_CLI_PATH"
    
    # Create necessary directories
    mkdir -p "${HOME}/.local/bin"
    mkdir -p "${HOME}/.local/share/applications"
    mkdir -p "${HOME}/.local/share/icons"
    mkdir -p "${HOME}/.local/lib"
    
    # Copy app files
    cp -r "${OUTPUT_DIR}/lib/claude-desktop" "${HOME}/.local/lib/"
    cp "${OUTPUT_DIR}/bin/claude-desktop" "${HOME}/.local/bin/"
    
    # Create the .desktop file with the correct path and explicit icon
    cat > "${HOME}/.local/share/applications/claude-desktop.desktop" << EOF
[Desktop Entry]
Name=Claude Desktop
Comment=Claude AI Assistant
Exec=${HOME}/.local/bin/claude-desktop %U
Icon=${HOME}/.local/share/icons/hicolor/256x256/apps/claude.png
Type=Application
Terminal=false
Categories=Utility;
MimeType=x-scheme-handler/claude
StartupWMClass=Claude
EOF
    
    # Copy icons
    cp -r "${OUTPUT_DIR}/share/icons/"* "${HOME}/.local/share/icons/"
    
    # Update .desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "${HOME}/.local/share/applications"
    else
        log_warning "update-desktop-database not found. Desktop entry might not be immediately visible."
    fi
    
    # Set up Claude protocol handler
    xdg-mime default claude-desktop.desktop x-scheme-handler/claude
    
    log_info "Adding ${HOME}/.local/bin to PATH if not already there..."
    if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "${HOME}/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
        log_info "Added ${HOME}/.local/bin to PATH in .bashrc"
    fi
    
    if [ -f "${HOME}/.zshrc" ]; then
        if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "${HOME}/.zshrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
            log_info "Added ${HOME}/.local/bin to PATH in .zshrc"
        fi
    fi
}

# Display final instructions
show_final_instructions() {
    log_info "Claude Desktop has been successfully installed!"
    log_info "You can now launch it from your application menu or by running 'claude-desktop' in a terminal."
    log_info ""
    log_info "Note: If Claude Desktop doesn't appear in your application menu immediately,"
    log_info "try logging out and back in, or run 'claude-desktop' from a new terminal session."
    log_info ""
    log_info "To use Claude Desktop with Google login, the protocol handler has been set up."
}

# Build Claude Desktop
build_claude_desktop() {
    log_info "Building Claude Desktop for Linux..."
    
    # Create clean build environment
    rm -rf "$WORK_DIR" "$OUTPUT_DIR"
    mkdir -p "$WORK_DIR" "$OUTPUT_DIR"
    
    setup_patchy_cnb
    download_and_extract
    process_icons
    process_asar
    create_launcher
}

# Main execution
main() {
    # Check for help flag
    for arg in "$@"; do
        if [ "$arg" = "--help" ]; then
            show_help
            exit 0
        fi
    done
    
    log_info "Starting Claude Desktop installation/management for Arch Linux..."
    check_arch_linux
    
    # Check for remove flag
    for arg in "$@"; do
        if [ "$arg" = "--remove" ]; then
            remove_existing_installation
            exit 0
        fi
    done
    
    # Check for clean install flag
    for arg in "$@"; do
        if [ "$arg" = "--clean-install" ]; then
            remove_existing_installation
        fi
    done
    
    # If no arguments provided and script is run directly, assume install
    if [ $# -eq 0 ]; then
        log_info "No options provided. Proceeding with default installation..."
    fi
    
    install_dependencies
    build_claude_desktop
    install_claude_desktop
    show_final_instructions
}

# Run main function
main "$@"