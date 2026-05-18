---
- name: Installer MongoDB avec shell
  hosts: web
  become: yes
  tasks:
    - name: Installer MongoDB (commande shell)
      shell: |
        # Créer le dépôt MongoDB
        sudo tee /etc/yum.repos.d/mongodb-org-4.2.repo << 'REPO'
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
REPO
        
        # Installer MongoDB
        sudo yum install -y mongodb-org
        
        # Démarrer et activer
        sudo systemctl start mongod
        sudo systemctl enable mongod
        
        # Vérifier
        sudo systemctl status mongod --no-pager
      register: mongo_output

    - name: Afficher résultat
      debug:
        msg: "MongoDB installé avec succès"

    - name: Vérifier la version
      command: mongo --eval "db.version()"
      register: mongo_version
      ignore_errors: yes

    - name: Afficher version
      debug:
        msg: "Version MongoDB: {{ mongo_version.stdout }}"
