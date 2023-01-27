#!/bin/bash
BUILD_JAR=$(ls /home/ec2-user/build/target/*.jar)
JAR_NAME=$(basename $BUILD_JAR)
echo "> build 파일명: $JAR_NAME" >> /home/ec2-user/deploy.log

echo "> build 파일 복사" >> /home/ec2-user/deploy.log
DEPLOY_PATH=/home/ec2-user/
cp $BUILD_JAR $DEPLOY_PATH

echo "> 실행중인 Tomcat Process가 있는 경우 종료" >> /home/ec2-user/deploy.log
TOMCAT_HOME_PATH=$(sudo find / -name "apache-tomcat*" -type d)
if [ -z $TOMCAT_HOME_PATH ]
then
  echo "> TOMCAT이 발견되지 않았습니다." >> /home/ec2-user/deploy.log
else
  sudo sh $TOMCAT_HOME_PATH/bin/shutdown.sh >> /home/ec2-user/deploy.log 2>/home/ec2-user/deploy_err.log
  sleep 5
fi

sudo lsof -i tcp:8080 | awk 'NR!=1 {print $2}' | sudo xargs kill >> /home/ec2-user/deploy.log 2>/home/ec2-user/deploy_err.log

echo "> 현재 실행중인 애플리케이션 pid 확인" >> /home/ec2-user/deploy.log
CURRENT_PID=$(pgrep -f $JAR_NAME)

if [ -z $CURRENT_PID ]
then
  echo "> 현재 구동중인 애플리케이션이 없으므로 종료하지 않습니다." >> /home/ec2-user/deploy.log
else
  echo "> kill -15 $CURRENT_PID"
  kill -15 $CURRENT_PID
  sleep 5
fi

DEPLOY_JAR=$DEPLOY_PATH$JAR_NAME
echo "> DEPLOY_JAR 배포"    >> /home/ec2-user/deploy.log
nohup java -jar $DEPLOY_JAR >> /home/ec2-user/deploy.log 2>/home/ec2-user/deploy_err.log &
