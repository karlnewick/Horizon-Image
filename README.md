# Horizon Golden Image Creation

This Project is to create a Windows 10 image for Horizon View based on the Techzone Article. https://techzone.vmware.com/resource/manually-creating-optimized-windows-images-vmware-horizon-vms

I created an Ansible Controller using Ubuntu Desktop and then installed Ansible and HashiCorp Packer

Folder Structure is created using the creatDir.yml, this will create a folders /Software 
This is the location for all the agents etc and the versions.

Example for the Horizon agent 2209 would be /Software/VMware/View/Agents/2209/

