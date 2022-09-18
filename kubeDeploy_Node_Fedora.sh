firewall-cmd --permanent --zone=trusted --add-port=6443/tcp --add-port=2379-2380/tcp
firewall-cmd --permanent --zone=trusted --add-port=10251/tcp
firewall-cmd --permanent --zone=trusted --add-port=10252/tcp
firewall-cmd --permanent --zone=trusted --add-port=10250/tcp
firewall-cmd --permanent --zone=trusted --add-port=30000-32767/tcp
firewall-cmd --permanent --zone=trusted --add-port=80/tcp
firewall-cmd --permanent --zone=trusted --add-port=443/tcp
firewall-cmd --permanent --zone=trusted --add-port=22/tcp
firewall-cmd --reload
firewall-cmd --list-all
modprobe overlay
modprobe br_netfilter
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
cat << EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo yum update
sudo yum install containerd
mkdir  -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum update


VERSION=$(yum list --showduplicates kubectl --disableexcludes=kubernetes | tail -n 2 | head -n 1 | cut -d' ' -f24)
yum install -y kubelet-$VERSION kubeadm-$VERSION kubectl-$VERSION

sed -i s/^disabled_plugins/#disabled_plugins/ /etc/containerd/config.toml

yum remove zram-generator-defaults

swapoff -a

systemctl enable --now containerd kubelet

