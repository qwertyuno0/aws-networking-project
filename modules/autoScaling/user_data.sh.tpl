#!/bin/bash
set -e

REPO_IP="${repo_ip}"

echo "Configuring internal APT repository..."
echo "deb [trusted=yes] http://$REPO_IP/repo ./" > /etc/apt/sources.list.d/internal-repo.list

# Disable the default Ubuntu repos (no internet in the private subnet)
if [ -f /etc/apt/sources.list ]; then
  sed -i 's/^deb /# deb /g' /etc/apt/sources.list
fi
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
  mv /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.disabled
fi

# Wait for the bastion repo, but give up after about 10 minutes
for i in $(seq 1 60); do
  if curl -sf -o /dev/null "http://$REPO_IP/repo/Packages.gz"; then
    break
  fi
  echo "Package repository not available yet... ($i/60)"
  sleep 10
done

#for race condition of private ec2

for i in $(seq 1 20); do
  apt-get -o DPkg::Lock::Timeout=300 update -y \
    && apt-get -o DPkg::Lock::Timeout=300 install -y apache2 \
    && break
  echo "apt failed, retrying ($i/20)"
  sleep 15
done


systemctl enable apache2
systemctl start apache2

HOSTNAME=$(hostname)

cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>DevOps Auto Scaling</title></head>
<body style="font-family: Arial; text-align:center; margin-top:40px;">
  <h1>Private Auto Scaling Server</h1>
  <h2>Environment: ${environment}</h2>
  <p>Server deployed using Terraform.</p>
  <p>Hostname: $HOSTNAME</p>
  <p>Apache installed from internal repository.</p>
  <p>Managed by Auto Scaling Group.</p>
</body>
</html>
HTML

echo "Apache installation completed."
