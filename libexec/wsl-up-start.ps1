# Usage: wsl-up start [options]
# Summary: starts a wsl development environment
# Help: reads a given 'wsl-up' file and either
# spins up a new wsl environment or start the existing
# one :
#      wsl-up start
# Options:
#   -f, --file             override wsl-up file path
#   -p, --provision        provision/reporovisions the 
#                          environment
#                          keep in mind that packages/users
#                          not included in wsl-up file will
#                          be removed
