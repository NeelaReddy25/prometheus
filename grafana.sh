#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if no errors.
else
    echo "You are super user."
fi

cd /opt &>>$LOGFILE
VALIDATE $? "Moving to opt directory"

curl -o gpg.key https://rpm.grafana.com/gpg.key &>>$LOGFILE
VALIDATE $? "Downloading grafana"

cp /home/ec2-user/prometheus/grafana.repo /etc/yum.repos.d/grafana.repo &>>$LOGFILE
VALIDATE $? "Copied grafana repo"

dnf install grafana -y &>>$LOGFILE
VALIDATE $? "Installing grafana"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable grafana-server &>>$LOGFILE
VALIDATE $? "Enabling grafana server"

systemctl start grafana-server &>>$LOGFILE
VALIDATE $? "Starting grafana server"