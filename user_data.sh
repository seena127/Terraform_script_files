#!/bin/bash
    sudo yum update
    sudo yum install -y nginx
    echo '<h1>Hello, World!</h1>' | sudo tee /var/www/html/index.html
    sudo systemctl restart nginx