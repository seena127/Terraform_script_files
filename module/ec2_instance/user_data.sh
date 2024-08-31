 <<-EOF
    #!/bin/bash
    sudo yum -y upgrade
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker  # Ensure Docker starts on boot
    EOF