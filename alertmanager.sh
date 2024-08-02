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
    echo "You are root user."
fi

cd /opt &>>$LOGFILE
VALIDATE $? "Moving to opt directory"

rm -rf alertmanager* &>>$LOGFILE
VALIDATE $? "Removing existing alertmanager"

wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Downloading alertmanager"

tar -xf alertmanager-0.27.0.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Extracting alertmanager"

mv alertmanager-0.27.0.linux-amd64 alertmanager &>>$LOGFILE
VALIDATE $? "Moving alertmanager"

cp /home/ec2-user/prometheus/alertmanager.service /etc/systemd/system/alertmanager.service &>>$LOGFILE
VALIDATE $? "Created alertmanager service"

cp /home/ec2-user/prometheus/alertmanager.yml /opt/alertmanager/alertmanager.yml &>>$LOGFILE
VALIDATE $? "Alertmanager configuration"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable alertmanager &>>$LOGFILE
VALIDATE $? "Enabling alertmanager"

systemctl start alertmanger &>>$LOGFILE
VALIDATE $?  "Starting alertmanager"