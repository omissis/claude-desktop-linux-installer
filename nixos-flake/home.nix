{ config, pkgs, claude-desktop, username, ... }:

{
  # Home Manager basics - programmatically set
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "23.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install Claude Desktop
  home.packages = [
    claude-desktop.packages.x86_64-linux.claude-desktop
  ];

  # Create a local copy of the desktop file with the right permissions and full path
  home.activation.setupClaudeDesktop = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Create local applications directory if it doesn't exist
    mkdir -p $HOME/.local/share/applications
    
    # Remove existing desktop file if it exists
    rm -f $HOME/.local/share/applications/claude-desktop.desktop
    
    # Copy the desktop file (instead of symlinking)
    cp -f $HOME/.nix-profile/share/applications/claude-desktop.desktop $HOME/.local/share/applications/
    
    # Ensure we have write permissions
    chmod u+w $HOME/.local/share/applications/claude-desktop.desktop
    
    # Update the Exec line to use the full path
    sed -i "s|^Exec=claude-desktop|Exec=$HOME/.nix-profile/bin/claude-desktop|g" $HOME/.local/share/applications/claude-desktop.desktop
    
    # Add StartupWMClass for better dock integration
    if ! grep -q "StartupWMClass" $HOME/.local/share/applications/claude-desktop.desktop; then
      echo "StartupWMClass=Claude" >> $HOME/.local/share/applications/claude-desktop.desktop
    fi
    
    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
      update-desktop-database $HOME/.local/share/applications
    fi
  '';

  # Configure MIME handling for claude:// URLs
  xdg.enable = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/claude" = "claude-desktop.desktop";
    };
  };
}
