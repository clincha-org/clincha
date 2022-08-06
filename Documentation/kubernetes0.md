# Kubernetes Setup

Using Geoff Geering's Kubernetes Ansible role did not work for me and the constant errors made me realise that I didn't
understand what it was setting up. In the end I decided it would be much more useful for me to create my own role and
experiment with starting up the Kubernets cluster. I started with the following resources:

[Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network)

## Container Runtimes

This section follows the instructions
in [this section](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd) of the
documentation.

I'm selecting containerd as my container runtime. I don't have too much reason to use this, but we use it at work, and
they seem pretty interchangeable. I keep seeing that the docker runtime is being depreciated in a bunch of places but
not really sure what extent that is.

The steps I'll need to implement in Ansible are the following

- Run commands to install 'overlay' and 'br_netfilter' modules into the kernel
- Create the configuration file within the modules-load directory to ensure those modules are loaded on boot
- Set sysctl parameters for ip address configuration
- Install containerd

### Configure prerequisites

#### Modprobe

_[modprobe](https://linux.die.net/man/8/modprobe) intelligently adds or removes a module from the Linux kernel_. The two
modules that I'll add in are used for
transparent masquerading, Virtual Extensible LAN traffic and to provide an overlay filesystem.

**Transparent masquerading** translates the network traffic from the Kubernetes pods into network traffic that looks
like it's coming from the node. When the traffic returns to the other direction the translation happens in reverse so
that the node can pass the traffic back to the right node.

**Virtual Extensible LAN's** tunnel layer 2 traffic over a layer 3 or 4 networks. This is used to reduced overhead added
by the Spanning-tree protocol, overcome the issue of limited numbers of VLANs (4094) and deal with the issue of large
MAC address tables.

**Overlay filesystems** stack multiple layers of filesystems so that the consuming process sees a single unified
filesystem. It should be transparent to the consumer which filesystem they are accessing. However, under the hood Linux
is routing files between the various filesystems. A pod might be consuming files from multiple different sources but all
it sees is a single, normal filesytem to access.

- https://docs.microfocus.com/doc/Data_Center_Automation/2019.11/SetSystemParameters
- http://pedrowa.weba.sk/docs/ipfwadm/node5.html
- https://networklessons.com/cisco/ccnp-encor-350-401/introduction-to-virtual-extensible-lan-vxlan

I can use Ansible to create a modprobe config file which will be loaded on boot.

    # /etc/modules-load.d/containerd.conf
    overlay
    br_netfilter

Then I need to run these command to add the modules to the kernel while the system is running. Should just be a command
block in Ansible.

    sudo modprobe overlay
    sudo modprobe br_netfilter

#### Sysctl

_[sysctl](https://linux.die.net/man/8/sysctl) is used to modify kernel parameters at runtime_. The three parameters that
I'll set are used to configure ip traffic running over bridged connections and to allow the host to handle ip traffic
that is not destined for itself. The final setting is the simplest to understand. Traffic coming to and from pods needs
to be routed by the host to and from the rest of the network. The first two settings pass this traffic through iptables
which provides a firewall service on Linux.

- https://wiki.libvirt.org/page/Net.bridge.bridge-nf-call_and_sysctl.conf
- https://linuxconfig.org/how-to-turn-on-off-ip-forwarding-in-linux
- https://www.howtogeek.com/177621/the-beginners-guide-to-iptables-the-linux-firewall/

Ansible sysctl (ansible.posix.sysctl) module can set these. Using the Ansible module ensures that these are set to start
on boot and that they are set for the running system too.

    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1

### Install containerd

To install containerd I'm using [this guide](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)
. I could install it from the GitHub page but that seems like a faff. Docker packages it up for dnf so I'll try and
install it that way. Instructions passed me over to [this page](https://docs.docker.com/engine/install/debian/) to get
dnf ready to install it.

I'm a bit confused because I'm getting containerd from the Docker wiki now and I thought I was installing containerd not
Docker. I
read [this guide](https://www.theserverside.com/blog/Coffee-Talk-Java-News-Stories-and-Opinions/Whats-the-difference-between-containerd-and-Docker#:~:text=Docker%20is%20a%20broad%20set,uses%20containerd%20as%20its%20runtime.)
and it cleared that up. Docker is a set of technologies that is used to run containers. Containerd is a runtime that
Docker uses.

The guides are quite good, so I won't repeat much here.
