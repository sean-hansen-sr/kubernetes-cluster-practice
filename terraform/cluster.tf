# 5. Deploy 3 Ubuntu VMs with No External IP
resource "aws_instance" "ubuntu_vm" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  # This explicitly prevents assigning a public/external IP address
  associate_public_ip_address = false

  tags = {
    Name = count.index == 0 ? "ubuntu-control-plane-${count.index + 1}" : "ubuntu-worker-node-${count.index}"
    Role = count.index == 0 ? "Control_Plane_${count.index + 1}" : "Worker_Node_${count.index}"
  }
}
