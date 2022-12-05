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
sudo su
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

```bash
# Добавьте репозиторий Zabbix
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bdebian11_all.deb
dpkg -i zabbix-release_6.0-4+debian11_all.deb
apt update
# Установите Zabbix Server и компоненты
sudo apt install zabbix-agent -y
# Запустите Zabbix Agent
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
```

То же самое сразу на 2 хоста через ansible:

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
  
  - name: Start enable zabbix-agent 
    systemd:
      name: zabbix-agent
      state: started
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
