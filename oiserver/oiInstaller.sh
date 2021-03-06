#!/bin/bash

## oiInstaller.sh
## Script de instalación/actualización de oiServer

createDB(){

    set +e
    RES=$(echo "SHOW DATABASES;  " | mysql -h localhost -u $DBUSER -p$DBPWD 2>/dev/null )
    I=$(echo -e $RES |grep $DB )
    if [ -n "$I" ]
    then
        echo -e "\n${DB} exist and ${DBUSER} can access to it."
    else

      echo -e "\n${DB} not exist or ${DBUSER} can not access to it. I will try create ${DB} if not exist."
      CRE=$(echo "CREATE DATABASE ${DB} ;"  | mysql -h localhost -u $DBUSER -p$DBPWD 2>/dev/null )
      if [ $? != 0 ]
      then
        echo "${DBUSER} can't create ${DB} ."

        if [ -z "${ROOTUSER}" ]
        then
            rootUser
        fi

        RES=$(echo "SHOW DATABASES;  " | mysql -h localhost  -u $ROOTUSER -p$ROOTPWD 2>/dev/null )
        I=$(echo -e $RES |grep $DB )
        if [ -n "$I" ]
        then
            echo "${DB} exist !!"
        else
            CRE=$(echo "CREATE DATABASE ${DB} ;"  | mysql -h localhost -u $ROOTUSER -p$ROOTPWD )
            if [ $? != 0 ]
            then
                echo "${ROOTPWD} can't create Database."
                exit 1
            else
                echo "${DB} has been created succesfully."
            fi
        fi
      fi
    fi

    set -e
}

importDB(){

    set +e
echo "    mysql -h localhost -u ${DBUSER} -p${DBPWD} ${DB} < ${RPATH}/config/openirudiDB.sql"
    mysql -h localhost -u ${DBUSER} -p${DBPWD} ${DB} < ${RPATH}/config/openirudiDB.sql

    set -e
}

addCron(){
    CMD="* * * * * wget -O /dev/null http://localhost/oiserver/web/func/wakeUp.php &> /dev/null"
    cat <(crontab -l|grep -v wakeUp.php ) <(echo "${CMD}") | crontab -
}

addSudo(){

    if [ -f /tmp/sudoers.tmp ]
    then
        rm /tmp/sudoers.tmp
    fi

    cat /etc/sudoers | grep -v CMDOPENIRUDI | grep -v OpenIrudi > /tmp/sudoers.tmp

    echo "# OpenIrudi" >> /tmp/sudoers.tmp
    echo "Cmnd_Alias CMDOPENIRUDI = /var/www/oiserver/bin/oiserver.sh" >> /tmp/sudoers.tmp
    echo "www-data ALL = NOPASSWD: CMDOPENIRUDI" >> /tmp/sudoers.tmp

    visudo -c -f /tmp/sudoers.tmp
    if [ "$?" -eq 0 ];
    then
        cp /tmp/sudoers.tmp /etc/sudoers
    fi

    rm /tmp/sudoers.tmp

}


createDBUser(){

    set +e
    RES=$(echo "SHOW DATABASES;  " | mysql -h localhost -u $DBUSER -p$DBPWD 2>/dev/null )
    I=$(echo -e $RES |grep $DB )
    if [ -z "$I" ]
    then
        echo "${DBUSER} user can't access to ${DB} database. I will try to create ${DBUSER} if does not exist."

        if [ -z "${ROOTUSER}" ]
        then
            rootUser
        fi

        US=$(echo "use mysql; SELECT * FROM user WHERE user='${DBUSER}'" | mysql -h localhost -u $ROOTUSER -p$ROOTPWD )

        if [ -z "${US}" ]
        then
            US1=$(echo "CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPWD}';" | mysql -h localhost -u $ROOTUSER -p$ROOTPWD )
            US2=$(echo "GRANT USAGE ON * . * TO '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPWD}' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0 ;" | mysql -h localhost -u $ROOTUSER -p$ROOTPWD )
        fi

        US3=$(echo "GRANT ALL PRIVILEGES ON ${DB} . * TO '$DBUSER'@'localhost' WITH GRANT OPTION ;" | mysql -h localhost -u $ROOTUSER -p$ROOTPWD )


    fi

    set -e

}

rootUser(){
    ROOTUSER='root'
    echo -e "Username of user with admin privileges in a database: [${ROOTUSER}]"
    read BUF
    if [ -n "$BUF" ]
    then
      ROOTUSER="$BUF"
    fi

    ROOTPWD=''
    echo -e "${ROOTUSER} Password:"

    trap "stty echo ; exit" 1 2 15
    stty -echo
    read BUF
    stty echo
    trap "" 1 2 15

    if [ -n "$BUF" ]
    then
      ROOTPWD="$BUF"
    fi


    RES=$(echo "SHOW DATABASES;  " | mysql -h localhost -u $ROOTUSER -p$ROOTPWD 2>/dev/null  )
    if [ $? != 0 ]
    then
      echo
      echo "Introduced data is incorrect, please retry with a different user or password, ${ROOTUSER} has not privileges."
      echo "Proccess Stopped"
      exit 1
    fi


}

downloadLastClient(){
    APPYML="${WPATH}/apps/backend/config/app.yml"
    if [ ! -f $APPYML ]
    then
        echo "I could not open config file ${APPYML}"
        exit 1
    fi

    LASTURL=$(cat $APPYML |grep lastClient: |grep -v '#' |awk '{print $2}' |tr -d "'" )
    LASTCLIENTV="$(wget -O /tmp/last.txt $LASTURL &>/dev/null )"
    if [ $? != 0 ]
    then
        echo "We can't connect and download Openirudi client from ${LASTURL}"
        exit 1
    fi
    LASTCLIENT="$(cat /tmp/last.txt |grep -v '#'|awk 'BEGIN { FS = "@@@" } ; {print $2}' )"

    ISOPATH=" ${WPATH}/$(cat $APPYML |grep isopath: |awk '{print $2}' |tr -d "'" )"
    CLIENTPATH=" ${WPATH}/$(cat $APPYML |grep clientpath: |awk '{print $2}' |tr -d "'")"

    ${WPATH}/bin/oiserver.sh update $LASTCLIENT $CLIENTPATH $ISOPATH
}


moveFiles(){
    echo "cp -a ${RPATH}  ${WPATH}"

    cp -a ${RPATH}  ${WPATH}
    parseDBuser
    symfonyInit


}

moveUpdateFiles(){
    
    BWPATH="${WPATH}_old"
    echo
    echo "Creating backup in ${BWPATH}"
    echo

    mv -b ${WPATH} ${BWPATH}
    if [ $? != 0 ]
    then
        echo "ERROR: There was a problem creating the backup!"
        exit 1
    fi
    cp -a ${RPATH}  ${WPATH}

    cp ${BWPATH}/config/databases.yml  ${WPATH}/config/databases.yml
    cp ${BWPATH}/apps/backend/config/factories.yml  ${WPATH}/apps/backend/config/factories.yml
    cp ${BWPATH}/web/func/dbcon.php  ${WPATH}/web/func/dbcon.php

    if [ -d ${BWPATH}/client/rootcd ]
    then
        cp -a ${BWPATH}/client/*  ${WPATH}/client/
    fi

    if [ -f ${BWPATH}/web/func/root/openirudi.iso ]
    then
        cp ${BWPATH}/web/func/root/openirudi.iso ${WPATH}/web/func/root/openirudi.iso
        cp ${BWPATH}/web/func/root/boot/* ${WPATH}/web/func/root/boot/
    fi

    symfonyInit

}

symfonyInit(){

    $WPATH/symfony cc
    $WPATH/symfony project:permissions
    chmod +x $WPATH/bin/*.sh


}

parseDBuser(){

    if [ -f /tmp/d1.yml ]
    then
      rm /tmp/d1.yml
    fi

    #${WPATH}/config/databases.yml
    #dsn: 'mysql:dbname=drivers;host=localhost;unix_socket=/var/run/mysqld/mysqld.sock'
    #username: openirudi
    #password: openirudi

    cat ${WPATH}/config/databases.yml |sed "s/dsn\:.*$/dsn\: mysql:dbname=${DB};host=localhost;unix_socket=\/var\/run\/mysqld\/mysqld\.sock/" > /tmp/d1.yml
    mv /tmp/d1.yml ${WPATH}/config/databases.yml

    cat ${WPATH}/config/databases.yml |sed "s/username\:.*$/username\: ${DBUSER}/" | sed "s/password\:.*$/password\: ${DBPWD}/"  > /tmp/d1.yml
    mv /tmp/d1.yml ${WPATH}/config/databases.yml

    if [ -f /tmp/d1.yml ]
    then
      rm /tmp/d1.yml
    fi


    #$WPATH/apps/backend/config/
    #  database: mysql://openirudi:openirudi@localhost/drivers

    cat ${WPATH}/apps/backend/config/factories.yml |sed "s/mysql\:\/\/.*$/mysql\:\/\/${DBUSER}:${DBPWD}@localhost\/${DB}/" > /tmp/d1.yml

    mv /tmp/d1.yml ${WPATH}/apps/backend/config/factories.yml

    if [ -f /tmp/d1.yml ]
    then
      rm /tmp/d1.yml
    fi


    #$WPATH/oiserver/web/func/dbcon.php
    #define('DB','openirudiDB');
    #define('DBUSER','openiridi');
    #define('DBPWD','openirudi');

    cat ${WPATH}/web/func/dbcon.php | sed "s/\$DB=.*$/\$DB=\'$DB\';/" |sed "s/\$DBUSER=.*$/\$DBUSER=\'$DBUSER\';/" | sed "s/\$DBPWD=.*$/\$DBPWD=\'$DBPWD\';/" > /tmp/d1.yml
    mv /tmp/d1.yml ${WPATH}/web/func/dbcon.php

    if [ -f /tmp/d1.yml ]
    then
      rm /tmp/d1.yml
    fi

}

createUser(){

    echo "Creating an ssh user on the server, please wait... we need this user for uploading/downloading images"
    set +e
    if [ -z "$(id openirudi| grep "uid=" )" ] || [ ! -d /home/openirudi ]
    then
        R=$(useradd  -m -c "Openirudi client user" openirudi)
        if [ $? != 0 ]
        then
          WARNING_USER='
          
          ERROR !! We have problems creating a openirudi user in your system. Execute next command to create it:
          "useradd  -m -c \"Openirudi client user\" openirudi"
          
          ';
           
        fi
    fi
    set -e

}


######################################################
#
#       MAIN
#
#######################################################


set +e

RPATH="./oiserver"
WARNING_USER=''

echo -e "\nOPENIRUDI SERVER NEW INSTALLATION OR UPDATE\n"
echo "Would you like to continue? ( yes/[NO] )"
read CONTINUE

if [ "$CONTINUE" != "yes" ]
then
  echo "Abort Openirudi Installation"
  echo "Agur benur eta jan yogurth..."
  echo
  exit
fi

INSTALLER=$0
IPATH=$(dirname "${INSTALLER}");
if [ "$(pwd )" != "${IPATH}" ]
then
    cd $IPATH
fi


ROOTUSER=''
ROOTPWD=''

#echo "*which genisoimage?"
GENISOIMAGE=$(which genisoimage)
if [ $? != 0 ]
then
  echo -e "\ngenisoimage not present!"
  echo
  exit 1
fi

#echo "which mysql?"
GENISOIMAGE=$(which mysql)
if [ $? != 0 ]
then
  echo -e "\nmysql client not present!"
  echo
  exit 1
fi

#echo "which sudo?"
SUDO=$(which sudo)
if [ $? != 0 ]
then
  echo -e "\nOpenIrudi's server needs \"sudo\" to execute oiserver.sh. Install "sudo" and run installer again!"
  echo
  exit 1
fi


#echo "which php?"
PHP=$(which php)
if [ $? != 0 ]
then
  echo "php not present!"
  echo "You need php5-cli and php-mcrypt"
  echo
  exit 1
fi

#echo "which apache?"
R=$( netstat -lnpt |grep :80 )
if [ $? != 0 ] || [ -z "$R" ]
then
  echo "ERROR: Web server not present!"
  echo "We couldn't find http://localhost in your server"
  echo
  exit 1
fi

WPATH='/var/www/'
echo -e "\nInstallation path: [${WPATH}]"
echo "We'll check for a previous installation, in this case we'll update it"
read BUF
if [ -n "$BUF" ]
then
  WPATH="$BUF"
fi

if [ ! -d "$WPATH" ]
then
    echo "$WPATH doesn't exist or you don't have permissions?"
    echo "Abort Openirudi Installation"
    exit 1
fi

WPATH=$(echo "${WPATH}/oiserver" |tr -s '/' )

UPDATE='NO'
if [ -d "${WPATH}" ]
then
    echo
    echo
    echo "We found oiserver installed:"
    echo "Do you want to update it? [${UPDATE}]/yes"
    read BUF
    if [ -n "$BUF" ]
    then
      UPDATE="$BUF"
    fi

    if [ "$UPDATE" != "yes" ]
    then
      echo "If you want new \"oiserver\" installation, move \"oiserver\" from ${WPATH}"
      echo "Abort Openirudi Installation"
      echo "Agur benur eta jan yogurth..."
      echo
      exit
    fi

fi


 if [ "$UPDATE" = "yes" ]
then
echo
        echo "*Add new entry in sudoers file"
        addSudo

        echo
        echo "*Add new job to crontab"
        addCron

        echo
        echo "*Create system user"
        createUser

        echo
        echo "*Move new files"
        moveUpdateFiles


else

        DB='openirudiDB'
        echo -e "\nDatabase name: [${DB}]"
        read BUF
        if [ -n "$BUF" ]
        then
          DB="$BUF"
        fi

        DBUSER='openirudi'
        echo -e "${DB} database username: [${DBUSER}]"
        read BUF
        if [ -n "$BUF" ]
        then
          DBUSER="$BUF"
        fi

        DBPWD='openirudi'
        echo -e "${DBUSER} user password for ${DB}?"

        trap "stty echo ; exit" 1 2 15
        stty -echo
        read BUF
        stty echo
        trap "" 1 2 15

        if [ -n "$BUF" ]
        then
          DBPWD="$BUF"
        fi

        set +e
        RES=$(echo "SHOW DATABASES;  " | mysql -h localhost -u$DBUSER -p$DBPWD &>/dev/null )
        if [ $? != 0 ]
        then
          echo -e "\nI can't query DB. May be \"${DBUSER}\" not exists yet."
        fi
        set -e

        echo
        echo "*Create database"
        createDB

        echo
        echo "*Create database user"
        createDBUser

        echo
        echo "*Create system user"
        createUser

        echo
        echo "*Import database content"
        importDB

        echo
        echo "*Add new entry in sudoers file"
        addSudo

        echo
        echo "*Add new job to crontab"
        addCron

        echo
        echo "*Move files"
        moveFiles

        echo
        echo "*Downloading lastest Openirudi client"
        downloadLastClient


        

        echo -e "\n\n\n"
        echo "*** Important: You need SSH and TFTP servers running to enjoy properly from Openirudi. ***"

        echo "Checking if ssh server is present."
        if [ -z "$(netstat -lnpt 2>&1 |grep tcp|grep ':22' )" ]
        then
            echo "You don't have SSH sever installed or is not running."
            echo "(Debian or Ubuntu) install it with the following command \"apt-get install ssh\""
        else
            echo "ssh sever is running"
        fi


        echo -e "\n\n\n"

        echo "Checking if tftp server is present."
        if [ -z "$(netstat -lnpu 2>&1 |grep udp|grep ':69' )" ]
        then
            echo "You don't have tftp sever installed, runnig or you didn't configure properly."
            echo "(Debian or Ubuntu) install it with the following command \"apt-get install atftpd\""
        else
            echo "tftp sever is running"
        fi

        echo "*** Remember to configure \"${WPATH}/web/func/root\"  as tftp server path. ****"

        echo -e "\n\n\n"



        echo "Openirudi's server is sucesfully installed. Don't forget to configure your tftp server"

        echo "You can start managing Openirudi via web from: http://localhost/oiserver
        user: admin
        pass: admin"
fi

echo "$WARNING_USER"
echo
echo
echo "Enjoy!"
echo