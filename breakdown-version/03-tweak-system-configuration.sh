# Disable SELinux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Disable swap
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

