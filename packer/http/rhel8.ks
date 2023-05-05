lang en_GB
keyboard uk
timezone Europe/London --isUtc
rootpw $6$jtuxaxRJULoNO1b.$JJAqn8nmM3FKZ7DArpv1gR.D8DLxBGpx5ezNZeCiEmJbaL2rl5nZZon7zIr1F60BU8DoE5RQUG87yKTFNNaDo. --iscrypted
user --name=ansible --password=$6$FV10vEBLeR10.8QO$Fk6M.V7O5R7SsxyZmXkwGTOsqkb3bSvzjCPGf3qDTQSRs.degZ7zlR2uY0G/dxl3JSp7CR5xSVCCWmCPdGQMt1 --iscrypted
sshkey --username=ansible "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAB3o1EdmoDV+LE7BoVNjBXKOW18h0Gw+qP2ErlYGn6NuEIhv4Awmf37uRW9906vcavhC1Hu7fDX24FdeM709jEEVgHat5faUI1SW5OwLeIxegR4e1Wy55A3dStC4c1qJwtws4S5DRiEHEcZbYCIMFPmHgwBbRXSlns63Twa/5gBeZBaWA== ansible"
reboot
text
cdrom
bootloader --append="rhgb quiet crashkernel=auto"
zerombr
clearpart --all --initlabel
autopart
authselect --passalgo=sha512 --useshadow
selinux --enforcing
firewall --disable --ssh --http
services --enabled sshd,NetworkManager
skipx
firstboot --disable

%packages
qemu-guest-agent
cloud-init
tar
python3
%end

%post
echo "%ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/ansible
touch /etc/cloud/cloud-init.disabled
%end
