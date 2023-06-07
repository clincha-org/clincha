lang en_GB
keyboard uk
timezone Europe/London --utc
rootpw $2b$10$5zWDuEuXs.cVx40FdjCPt.SsmNswVGiScHmgUpUygIazHhCF06lt6 --iscrypted
user --name=ansible --password=$2y$10$dzT2n6aZlzwn.7ltbmdF9OVwRbpQliWDQU7DwklDZEzIlk1/1P1te --iscrypted
sshkey --username=ansible "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICDMAJMgmScKdlNtaIUHdCZ85cx76MVe1iUJwiU0/NyM ansible@clincha.co.uk"
reboot
text
cdrom
bootloader --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
network --bootproto=dhcp
skipx
firstboot --disable
selinux --enforcing
firewall --enabled --http --ssh
%post
echo "%ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ansible
touch /etc/cloud/cloud-init.disabled
%end
%packages
@^server-product-environment
qemu-guest-agent
cloud-init
tar
python3
%end
