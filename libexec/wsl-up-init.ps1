# Usage: wsl-up init [options]
# Summary: new wsl development environment
# Help: Creates a wsl-up json config file
# in invocation directory and optionally 
# spins up wsl development environment:
#      wsl-up init
#
# Options:
#   -s, --spin-up             spins up the wsl environment right
#                             after creation
#   -n, --name                wsl environment name
#                             DEFAULT: parent directory name
#   -f, --file                overrides location it stores
#                             wsl-up file.
#                             DEFAULT: .wsl-up.json