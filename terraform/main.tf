// Create several similar vm (example for zabbix-agent and zabbix-server)

// Configure the Yandex Cloud provider

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.OAuthTocken
  cloud_id  = "b1gob4asoo1qa32tbt9b"
  folder_id = "b1gob4asoo1qa32tbt9b"
  zone      = "ru-central1-a"
}


  
//create zabbix-agents

resource "yandex_compute_instance" "vm-agent" {
  name = "${var.guest_name_prefix}-vm0${count.index + 1}" #variables.tf 
  count = 2    


  resources {
    cores     = 4
    memory    = 4
  
  }

  boot_disk {
    initialize_params {
      image_id = "fd8456n7d102l8p6ipgl" #Debian 11
      type     = "network-ssd"
      size     = "16"
    }
  }

    network_interface {
    subnet_id = "e9bf0qhr78eltofkhvbb"
    nat       = true
    ip_address     = lookup(var.vm_ips, count.index) #terraform.tfvars
    }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }


  provisioner "remote-exec" {
    connection {
      host = lookup(var.vm_ips, count.index) #terraform.tfvars
      type        = "ssh"
      private_key = "${file("~/.ssh/id_rsa")}"
      port        = 22
      user        = "user"
      agent       = false
      timeout     = "1m"
    }
    inline = ["sudo hostnamectl set-hostname ${var.guest_name_prefix}-vm0${count.index + 1}"]
  }    
}

//create zabbix-server

resource "yandex_compute_instance" "vm-server" {
  name = "zabbix-server" 


  resources {
    cores     = 4
    memory    = 4
  
  }

  boot_disk {
    initialize_params {
      image_id = "fd8456n7d102l8p6ipgl" #Debian 11
      type     = "network-ssd"
      size     = "16"
    }
  }

    network_interface {
    subnet_id = "e9bf0qhr78eltofkhvbb"
    nat       = true
    ip_address     = "10.128.0.102"
    }

  
  metadata = {
    user-data = "${file("./meta.txt")}"
  }

  provisioner "remote-exec" {
    connection {
      host = "10.128.0.102"
      type        = "ssh"
      private_key = "${file("~/.ssh/id_rsa")}"
      port        = 22
      user        = "user"
      agent       = false
      timeout     = "1m"
    }
    inline = ["sudo hostnamectl set-hostname zabbix-server"]
  }
}

