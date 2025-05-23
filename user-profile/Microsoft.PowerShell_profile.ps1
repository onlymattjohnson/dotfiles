# Microsoft.PowerShell_profile.ps1
# This script is loaded every time PowerShell starts.
# It's for configuring your interactive shell experience.

#region PSReadLine Configuration (Optional but Recommended for IntelliSense/Syntax Highlighting)
# Check if PSReadLine module exists and import it
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    # Enable history-based predictions
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView # Or InlineView

    # Enable syntax highlighting (default)
    Set-PSReadLineOption -Colors @{
        Command            = '#FFFFFF' # White
        Operator           = '#F8F8F2' # Light Gray
        Variable           = '#F08D49' # Orange
        String             = '#E7B549' # Yellow
        Number             = '#A6E22E' # Green
        Type               = '#8BE9FD' # Light Blue
        Parameter          = '#50FA7B' # Bright Green
        Member             = '#FF79C6' # Pink
        Error              = '#FF5555' # Red
        Default            = '#F8F8F2' # Light Gray
        Comment            = '#6272A4' # Blue-gray (like Dracula comment)
        Keyword            = '#FF79C6' # Pink
        Selection          = '#44475A' # Dark Gray
        # Add more as needed, check Get-PSReadLineOption -ShowDefaultParameterValues
    }
}
#endregion

#region Oh My Posh and Posh-Git Configuration
# Check if modules exist before importing
if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    # Set a theme for Oh My Posh. You can choose from many built-in themes.
    # Find themes in C:\Program Files\OhMyPosh\themes\
    # Or https://ohmyposh.dev/docs/themes'
    oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedev.omp.json" | Invoke-Expression
}
#endregion

#region Custom Aliases and Functions (Examples)
# You can add your own custom aliases and functions here
# function Set-MyCustomPath {
#     $env:Path += ";C:\MyCustomTool\bin"
# }
# Set-MyCustomPath

# Set-Alias g git # Example Git alias
#endregion