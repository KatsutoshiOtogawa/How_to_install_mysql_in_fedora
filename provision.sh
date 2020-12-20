dnf -y update

# install firewalld. firewalld is rhel,centos default dynamic firewall.
dnf -y install firewalld

dnf -y install git 

# enabla firewalld.
systemctl enable firewalld
systemctl start firewalld


# port forwarding mysql port 3306.
firewall-cmd --add-port=3306/tcp --zone=public --permanent

# port forwarding mysql-shell port 33060
firewall-cmd --add-port=33060/tcp --zone=public --permanent

# reload firewall settings.
firewall-cmd --reload

# install expect and pexpect for silent install.
dnf install -y expect
pip3 install pexpect

# install mariadb
dnf -y install community-mysql-server

# this plugin is created from oracle. reference from [mysql shell downloand](https://dev.mysql.com/downloads/shell/).
# perhaps, this plugin doesnt work in mariadb environement. if this plugin doesnt work, you must use community mysql-server!
dnf install -y https://dev.mysql.com/get/Downloads/MySQL-Shell/mysql-shell-8.0.22-1.fc33.x86_64.rpm

systemctl enable mysqld
systemctl start mysqld

MYSQL_ROOT_PASSWORD="elg5nuZsbahm0,bpxixO"

python3 << END
import pexpect
password = "$MYSQL_ROOT_PASSWORD"
shell_cmd = "/usr/bin/mysql_secure_installation"
prc = pexpect.spawn('/bin/bash', ['-c', shell_cmd],timeout=120)
prc.expect("Enter current password for root")
prc.sendline("")

prc.expect("Switch to unix_socket authentication")
prc.sendline("Y")

prc.expect("Change the root password")
prc.sendline("Y")

prc.expect("New password")
prc.sendline(password)

prc.expect("Re-enter new password")
prc.sendline(password)

prc.expect("Remove anonymous users")
prc.sendline("Y")

prc.expect("Disallow root login remotely")
prc.sendline("Y")

prc.expect("Remove test database and access to it")
prc.sendline("Y")

prc.expect("Reload privilege tables now")
prc.sendline("Y")

prc.expect( pexpect.EOF )
END

# CREATE ROLE DBADMIN.
# this role has all priviledge except Server administration inpacting database system.
# see official document.[Mysql oracle document](https://dev.mysql.com/doc/refman/5.7/en/privileges-provided.html)
mysql << END
CREATE ROLE dbadmin;
GRANT ALL PRIVILEGES ON *.* TO dbadmin;
REVOKE CREATE TABLESPACE,CREATE USER,SHUTDOWN,SUPER,PROCESS,REPLICATION SLAVE,RELOAD ON *.* FROM dbadmin;
END

# CREATE USER connecting from local network.
MYSQL_USER=user1
MYSQL_USER_PASSWORD="28gwZmjjbfpMmzd@tigm"
mysql << END
-- if you are in production environement, you use username@host_ip/netmask. 
-- see official document [mysql oracle document](https://dev.mysql.com/doc/refman/8.0/en/account-names.html)
CREATE USER $MYSQL_USER IDENTIFIED BY '$MYSQL_USER_PASSWORD';
GRANT dbadmin TO $MYSQL_USER;
END



# # install postgresql dataafile and clustor to /var/lib/pgsql/data
# su - postgres -c 'pg_ctl initdb'

# # update postgresql use memory,postgresql_log,style
# sed -i 's/^shared_buffers.*$/shared_buffers = 1024MB                 # min 128kB/' /var/lib/pgsql/data/postgresql.conf
# sed -i "s/^log_filename.*$/log_filename = 'postgresql-%Y-%m-%d.log'    # log file name pattern,/" /var/lib/pgsql/data/postgresql.conf

# echo "===> you want to "

# echo "you CREATE DATABASE dependending your locale data, you use these options"
# echo "LC_COLLATE [=] lc_collate"
# echo "LC_CTYPE [=] lc_ctype" 

cat << END >> ~/.bash_profile
# reference from [postgrsql tutorial](https://www.postgresqltutorial.com/postgresql-sample-database/)
# if you need ER diagram,
# curl -o printable-postgresql-sample-database-diagram.pdf -L https://sp.postgresqltutorial.com/wp-content/uploads/2018/03/printable-postgresql-sample-database-diagram.pdf
function enable_sampledatabase () {
    mkdir \$HOME/sample
    local backdir=\$(pwd)
    cd \$HOME/sample

    curl -o world.sql.gz -L https://downloads.mysql.com/docs/world.sql.gz
    gzip -d world.sql.gz
    mysql < world.sql

    curl -o world_x-db.tar.gz -L https://downloads.mysql.com/docs/world_x-db.tar.gz
    tar zxvf world_x-db.tar.gz
    cd world_x-db
    # this sample doesnt load mariadb,but mysql is collect.
    # mysql is not supporting 'STORED NOT NULL'
    # reference from [](https://yakst.com/ja/posts/3836)
    mysql < world_x.sql
    cd ../

    curl -o sakila-db.tar.gz -L https://downloads.mysql.com/docs/sakila-db.tar.gz
    tar zxvf sakila-db.tar.gz
    cd sakila-db
    mysql < sakila-schema.sql
    mysql < sakila-data.sql
    cd ../

    curl -o menagerie-db.tar.gz -L https://downloads.mysql.com/docs/menagerie-db.tar.gz
    tar zxvf menagerie-db.tar.gz
    cd menagerie-db
    mysql -e 'CREATE DATABASE menagerie;'
    mysql menagerie < cr_pet_tbl.sql
    mysql menagerie < load_pet_tbl.sql
    mysqlimport --local menagerie pet.txt
    mysql menagerie < ins_puff_rec.sql
    mysql menagerie < cr_event_tbl.sql
    mysqlimport --local menagerie event.txt
    cd ../

    # install 
    git clone --depth 1 https://github.com/datacharmer/test_db.git
    cd test_db 
    mysql < employees.sql

    cd $backdir
    rm -rf \$HOME/sample

}

function disable_sampledatabase () {
    # drop dvd_rental database.
    mysql << EOF
    DROP DATABASE IF EXISTS employees;
    DROP DATABASE IF EXISTS menagerie;
    DROP DATABASE IF EXISTS sakila;
    DROP DATABASE IF EXISTS world;
EOF
}

END


# erase fragtation funciton. this function you use vagrant package.
cat << END >> ~/.bash_profile
# eraze fragtation.
function defrag () {
    dd if=/dev/zero of=/EMPTY bs=1M; rm -f /EMPTY
}
END

echo "finish install!"

reboot
