# Домашнее задание к занятию "9.2. Zabbix. Часть 1" - `Елена Махота`

---

### Задание 1 

Установите Zabbix Server с веб-интерфейсом.

*Приложите скриншот авторизации в админке.*
*Приложите текст использованных команд в GitHub.*

### *Ответ к Заданию 1*

```bash
# Установка PostgreSQL
sudo apt install postgresql

# Добавление репозитория Zabbix
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb
dpkg -i zabbix-release_6.0-4+debian11_all.deb
apt update
```

![img1](https://github.com/Litande85/9.2-hw/blob/main/img1)

```bash
# Установка Zabbix Server
sudo apt install zabbix-server-pgsql zabbix-frontend-php php7.4-pgsql zabbix-apache-conf zabbix-sql-scripts nano -y 

# Создание пользователя с помощью psql из под root
su - postgres -c 'psql --command "CREATE USER zabbix WITH PASSWORD '\'123456789\'';"'
su - postgres -c 'psql --command "CREATE DATABASE zabbix OWNER zabbix;"'

# Импорт скачанной схемы
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# Установка пароля в DBPassword
sed -i 's/# DBPassword=/DBPassword=123456789/g' /etc/zabbix/zabbix_server.conf
```

![img2](https://github.com/Litande85/9.2-hw/blob/main/img2)

```bash
# Запуск Zabbix Server и web-сервер
sudo systemctl restart zabbix-server apache2 
sudo systemctl enable zabbix-server apache2 
```
Настройка web-сервера по адресу 
http://<ip_сервера>/zabbix

![img3](https://github.com/Litande85/9.2-hw/blob/main/img3.png)


---

### Задание 2 

Установите Zabbix Agent на два хоста.

*Приложите скриншот раздела Configuration > Hosts, где видно, что агенты подключены к серверу.*
*Приложите скриншот лога zabbix agent, где видно, что он работает с сервером.*
*Приложите скриншот раздела Monitoring > Latest data для обоих хостов, где видны поступающие от агентов данные.*
*Приложите текст использованных команд в GitHub.*

### *Ответ к Заданию 2*
Создание двух хостов с помощью terraform в yandex cloud.

variables.tf

```HCL
variable "OAuthTocken" {
  default = "....."
}

variable "vm_ips" {
  type        = map(any)
  description = "List of IPs used for the Vms"
}

variable "guest_name_prefix" {
  default = "makhota-test"
}
```

terraform.tfvars

```HCL
vm_ips = {
  "0" = "10.128.0.10"
  "1" = "10.128.0.11"
  "2" = "10.128.0.12"
}
```

meta.txt

```yaml
#cloud-config
users:
 - name: user
   groups: sudo
   shell: /bin/bash
   sudo: ['ALL=(ALL) NOPASSWD:ALL']
   ssh-authorized-keys:
     - ssh-rsa  ..... user@makhotaev
```
main.tf

```HCL
// Create several similar vm

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


  
//создание vm

resource "yandex_compute_instance" "vm" {
  name = "${var.guest_name_prefix}-vm0${count.index + 1}"
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
}
```

Установка zabbix-agent


```bash
# Добавление репозитория Zabbix
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb
dpkg -i zabbix-release_6.0-4+debian11_all.deb
apt update
# Установка Zabbix Server и компонентов
sudo apt install zabbix-agent -y
# Запуск Zabbix Agent
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
```

Либо то же самое сразу на 2 хоста через ansible:

hosts

```bash
10.128.0.10 ansible_ssh_private_key_file=/home/user/.ssh/id_rsa ansible_user=user ansible_python_interpreter=/usr/bin/python3
10.128.0.11 ansible_ssh_private_key_file=/home/user/.ssh/id_rsa ansible_user=user ansible_python_interpreter=/usr/bin/python3
```

ansible-playbook playbook2.yml

```yaml
- name: Play1 Add repo
  hosts: all
  become: yes
  tasks:

  - name: Download repo Zabbix
    shell: wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb
  
  - name: install repo
    shell: dpkg -i zabbix-release_6.0-4+debian11_all.deb

  - name: Update apt packages
    become: true
    apt:
      update_cache: yes

- name: Play2 Install Zabbix-agent
  hosts: all
  become: yes
  tasks:

  - name: install zabbix-agent 
    apt:
      name:
        - zabbix-agent
      state: present
  
  - name: restart and enable zabbix-agent 
    systemd:
      name: zabbix-agent
      state: restarted
      enabled: yes


  - name: zabbix-agent status
    shell:  service zabbix-agent status
    register: zabbixtxt


  
  - name: "Print the file content to a console"
    debug:
      msg: "{{ zabbixtxt.stdout }}"
      
```

---
## Дополнительное задание (со звездочкой*)

Это задание дополнительное (необязательное к выполнению) и никак не повлияют на получение вами зачета по этому домашнему заданию. Вы можете его выполнить, если хотите глубже и/или шире разобраться в материале.

### Задание 3* 

Установите Zabbix Agent на Windows компьютер и подключите его к серверу Zabbix.

*Приложите скриншот раздела Latest Data, где видно свободное место на диске C:*

### *Ответ к Заданию 3*
