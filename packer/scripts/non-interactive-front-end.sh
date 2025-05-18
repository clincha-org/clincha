# Setup non-interactive shell to stop errors
# See: https://github.com/moby/moby/issues/27988
sudo echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections