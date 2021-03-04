#!/bin/bash
set -x

export AWS_DEFAULT_REGION="${aws_region}"
MONGODB_DATA_DIR="/var/lib/mongo"

echo "* hard nofile 64000" >> /etc/security/limits.conf
echo "* soft nofile 64000" >> /etc/security/limits.conf
echo "root hard nofile 64000" >> /etc/security/limits.conf
echo "root soft nofile 64000" >> /etc/security/limits.conf

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)

# Attach EIP
aws ec2 associate-address --instance-id $${INSTANCE_ID} --allocation-id ${eipalloc} --allow-reassociation

# Attach volume for MongoDB
aws ec2 detach-volume --volume-id ${volume_id}

until aws ec2 attach-volume --volume-id ${volume_id} --instance-id $${INSTANCE_ID} --device /dev/sdf; do
  sleep 10
  echo "Trying to attach volume"
done

# wait for EBS volume to attach
DATA_STATE="unknown"
until [[ $${DATA_STATE} == "attached" ]]; do
  DATA_STATE=$(aws ec2 describe-volumes \
      --filters \
          Name=attachment.instance-id,Values=$${INSTANCE_ID} \
          Name=attachment.device,Values=/dev/sdf \
      --query Volumes[].Attachments[].State \
      --output text)
  echo 'waiting for volume...'
  sleep 5
done

echo 'EBS volume attached!'

# Change source-destination checking
aws ec2 modify-instance-attribute --instance-id $${INSTANCE_ID} --source-dest-check "{\"Value\": false}"

sleep 5
FILESYSTEM=$(file -s /dev/nvme1n1 | grep filesystem)

if [[ $${#FILESYSTEM} -eq 0 ]]; then
  mkfs -t ext4 /dev/nvme1n1
fi


tee /etc/yum.repos.d/mongodb-org-4.2.repo << EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

tee /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/amazonlinux/2/
gpgcheck=1
enabled=1
EOF

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; rpm --import key.tmp; rm -f key.tmp
yum -y install pritunl mongodb-org

mount /dev/nvme1n1 $${MONGODB_DATA_DIR}
chown -R mongod:mongod $${MONGODB_DATA_DIR}
echo "/dev/nvme1n1 $${MONGODB_DATA_DIR} ext4 defaults,nofail 0 2" >> /etc/fstab

systemctl enable mongod pritunl
pritunl set-mongodb 'mongodb://localhost:27017/pritunl'


systemctl start mongod pritunl