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
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

cd /opt &>>$LOGFILE
VALIDATE $? "Moving to opt directory"

rm -rf prometheus* &>>$LOGFILE
VALIDATE $? "Removed existing prometheus"

wget https://github.com/prometheus/prometheus/releases/download/v2.54.0-rc.0/prometheus-2.54.0-rc.0.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Downloading the prometheus"

tar -xf prometheus-2.54.0-rc.0.linux-amd64.tar.gz &>>$LOGFILE
VALIDATE $? "Extracted prometheus"

mv prometheus-2.54.0-rc.0.linux-amd64 prometheus &>>$LOGFILE
VALIDATE $? "Renamed prometheus"

cp -r /home/ec2-user/prometheus/alert-rules /opt/prometheus/ &>>$LOGFILE 
VALIDATE $? "Copied alert rules"

cp /home/ec2-user/prometheus/prometheus.yml /opt/prometheus/prometheus.yml &>>$LOGFILE
VALIDATE $? "Copied prometheus configuration"

cp /home/ec2-user/prometheus/prometheus.service /etc/systemd/system/prometheus.service &>>$LOGFILE
VALIDATE $? "Created prometheus service"
 
systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable prometheus &>>$LOGFILE
VALIDATE $? "Enabling prometheus"

systemctl start prometheus &>>$LOGFILE
VALIDATE $? "Starting Prometheus"