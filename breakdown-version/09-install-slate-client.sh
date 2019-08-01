echo "Installing SLATE repository and client..."
cat << EOF > /etc/yum.repos.d/slate.repo
[slate-client]
name=SLATE-client
baseurl=https://jenkins.slateci.io/artifacts/client/
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOF

yum install slate-client -y

