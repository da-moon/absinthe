DISTRO := 'arch'
set shell := ["powershell.exe", "-Command"]
alias n := new
new:
	powershell \
	-ExecutionPolicy Bypass \
	-File bin\wsl-up.ps1 -- new \
	--minimal \
	--distro {{DISTRO}} \
	example