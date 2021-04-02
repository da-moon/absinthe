synced_folder  = ENV[     'SYNCED_FOLDER'      ]  || "/home/vagrant/#{File.basename(Dir.pwd)}"
memory         = ENV[           'MEMORY'       ]  || 8192
cpus           = ENV[           'CPUS'         ]  || 4
vm_name        = ENV[           'VM_NAME'      ]  || File.basename(Dir.pwd)
forwarded_ports= []
PS1_BASE_URL                = "https://raw.githubusercontent.com/da-moon/provisioner-scripts/master/powershell"
Vagrant.configure("2") do |config|
    config.vm.box = "gusztavvargadr/windows-10"
	  config.vagrant.plugins=["vagrant-vbguest","vagrant-reload"]
	  config.vm.communicator = "winrm"
	  config.trigger.before :all do |trigger|
	    trigger.name = "RDP"
	    trigger.warn = "use 'xfreerdp' package for RDP. i.e 'xfreerdp /u:\"vagrant\" /v:127.0.0.1:33389'"
	    trigger.ignore = [:destroy, :halt,:suspend]
	  end
	  config.vm.provider "virtualbox" do |vb, override|
      override.vm.synced_folder ".", "#{synced_folder}",disabled: false,
        auto_correct:true, owner: "vagrant",group: "vagrant",type: "virtualbox"
#	    vb.memory = "#{memory}"
#	    vb.cpus   = "#{cpus}"
	    vb.gui = "on"
	    vb.check_guest_additions = true
	    vb.linked_clone = true
#     vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
#	    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
#	    vb.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
	    vb.customize ["modifyvm", :id, "--vram", "256"]
	    # => bidirectional clipboard sync between host and guest
	    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
	    # => bidriectional drag and drop between host and guest
	    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
	  end
    config.vm.provision "shell",privileged:true,name:"vagrant-auto-login", path:"#{PS1_BASE_URL}/vagrant-auto-login.ps1"
    config.vm.provision "shell", name:"enable-remote-desktop",privileged: true, inline: <<-SHELL
      Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server'-name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    SHELL
    config.vm.provision "shell",privileged:true,name:"apps", path:"#{PS1_BASE_URL}/apps.ps1"
    config.vm.provision "shell",privileged:true,name:"perf", path:"#{PS1_BASE_URL}/adjust-for-best-performance.ps1"
    config.vm.provision "reload"
  forwarded_ports.each do |port|
    box.vm.network "forwarded_port", 
      guest: port, 
      host: port,
      auto_correct: true
  end
  config.vm.define "#{vm_name}"
  config.vm.hostname = "#{vm_name}"
  config.vm.synced_folder ".","#{synced_folder}",auto_correct:true, owner: "vagrant",group: "vagrant",disabled:true
end
