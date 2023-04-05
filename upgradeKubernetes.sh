# based on this https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/

for ver in 4 5 6
do

VERSION=$(yum list --showduplicates kubeadm --disableexcludes=kubernetes -y | grep 1.2$ver| tail -n 1 | head -n 1 | cut -d' ' -f24)
sudo yum install -y kubeadm-$VERSION --disableexcludes=kubernetes

if [ ! -z "$(kubectl get node $(hostname) | grep control-plane)" ]
then
sudo kubeadm version
sudo kubeadm upgrade plan
sudo kubeadm upgrade apply v$VERSION
else
sudo kubeadm upgrade node
fi

kubectl drain $(hostname) --ignore-daemonsets &
sudo yum install -y kubelet-$VERSION kubectl-$VERSION --disableexcludes=kubernetes
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo kubeadm init phase kubelet-start
kubectl uncordon $(hostname)

kubectl get nodes

read -p "Press any key to continue:"

done
