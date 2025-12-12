#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Wait for RDS to be available
DB_HOST="${db_host}"
DB_HOST_CLEAN="$${DB_HOST%%:*}"
until nc -z -w 5 $DB_HOST_CLEAN 3306; do
  echo "Waiting for database..."
  sleep 5
done

# Create docker-compose.yml for WordPress
cat > /home/ec2-user/docker-compose.yml <<EOF
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: ${db_host}
      WORDPRESS_DB_USER: ${db_user}
      WORDPRESS_DB_PASSWORD: ${db_password}
      WORDPRESS_DB_NAME: ${db_name}
    volumes:
      - wordpress_data:/var/www/html
    restart: always

volumes:
  wordpress_data:
EOF

# Start WordPress container
cd /home/ec2-user
docker-compose up -d

# Install CloudWatch agent (optional)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
