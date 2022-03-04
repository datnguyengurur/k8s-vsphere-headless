# Deploy K8S Headless on vSphere
Firstly, we need to create a linux box template
I found this example is the good one. 
Use packer to create the template.
https://github.com/vmware-samples/packer-examples-for-vsphere

## Re-Create the tfvars file included in the repo
- Create a folder name credentials and put your ssh private key in.
- As the script I wrote for debian base, RHEL like kernel may not work, you may need to redact the scripts a bit.