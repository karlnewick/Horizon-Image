# Horizon Golden Image Creation

This Project is to create a Windows 10 image for Horizon View based on the Techzone Article. https://techzone.vmware.com/resource/manually-creating-optimized-windows-images-vmware-horizon-vms

I created an Ansible Controller using Ubuntu Desktop 20.04 LTS and then installed Ansible and HashiCorp Packer

Folder Structure is created using the creatDir.yml, this will create a folders /Software 
This is the location for all the agents etc and the versions.

Example for the Horizon agent 2209 would be /Software/VMware/View/Agents/2209/

In the file https://github.com/karlnewick/Horizon-Image/blob/main/provisioners/ansible/playbooks/vars/sample_config.yml is all the information about what you would like deployed to the image, the version on the Horizon Agent, Direct Connect Agent, DEM STD or Ent and AppVolumes and the AVM VIP.
I have a lot of TBD that I want to apply as time allows.
Some of the optimzations options don't work as expected.
Rename the sample_config.yml to config.yml and update.

Next, create a copy of https://github.com/karlnewick/Horizon-Image/blob/main/sample%20-%20windows-10.pkr.hcl and rename to windows-10.pkr.hcl
In this hcl is the config for the vCenter, the account you want to attach, Cluster, storage etc. Update and save.

Note, the Datastore will have the Windows ISO and the VMware Tools ISO. This will have to manually uploaded to the DataStore, just update the windows-10.pkr.hcl to reflect the iso naming.

once everything is ready

within the working directory of the project run
packer build windows-10.pkr.hcl

On average it takes about 30-40 minutes to create a fresh Windows 10 image with the version of the agent selected and installed.

