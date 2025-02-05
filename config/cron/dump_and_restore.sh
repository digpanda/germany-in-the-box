#!/bin/sh
DIR=`date +%Y-%m-%d-%H_%M_%S`
BACKUP_DIR=/home/digpanda/dbbackup
LOG_DIR=$BACKUP_DIR/log

PROD_BACKUP_DIR=$BACKUP_DIR/prod_$DIR
STAGING_BACKUP_DIR=$BACKUP_DIR/staging_$DIR

mkdir -p $LOG_DIR
mkdir $PROD_BACKUP_DIR
mkdir $STAGING_BACKUP_DIR

#PROD_DB_HOST=207.226.141.12
PROD_DB_HOST=192.168.100.100
PROD_DB_PORT=27017
PROD_DB_NAME=a_chat_development
PROD_DB_USER=gitb
PROD_DB_PASSWORD=lyh2good

PROD_BACKUP_DIR_DB=$PROD_BACKUP_DIR/$PROD_DB_NAME

STAGING_DB_HOST=aws-eu-central-1-portal.1.dblayer.com
STAGING_DB_PORT=15202
STAGING_DB_NAME=a_chat_development
STAGING_DB_USER=gitb
STAGING_DB_PASSWORD=lyh2cool

#echo "mongodump --host $PROD_DB_HOST --port $PROD_DB_PORT --db $PROD_DB_NAME --username $PROD_DB_USER --password $PROD_DB_PASSWORD --out $PROD_BACKUP_DIR"
#mongodump --host $PROD_DB_HOST --port $PROD_DB_PORT --db $PROD_DB_NAME --username $PROD_DB_USER --password $PROD_DB_PASSWORD --out $PROD_BACKUP_DIR
CMD_DUMP_PROD="mongodump --host $PROD_DB_HOST --port $PROD_DB_PORT --db $PROD_DB_NAME --username $PROD_DB_USER --password $PROD_DB_PASSWORD --out $PROD_BACKUP_DIR"
CMD_DUMP_PROD_ECHO="echo CMD_DUMP_PROD: $CMD_DUMP_PROD"

#echo "mongodump --host $STAGING_DB_HOST --port $STAGING_DB_PORT --db $STAGING_DB_NAME --username $STAGING_DB_USER --password $STAGING_DB_PASSWORD --out $STAGING_BACKUP_DIR"
#mongodump --host $STAGING_DB_HOST --port $STAGING_DB_PORT --db $STAGING_DB_NAME --username $STAGING_DB_USER --password $STAGING_DB_PASSWORD --out $STAGING_BACKUP_DIR
CMD_DUMP_STAGING="mongodump --host $STAGING_DB_HOST --port $STAGING_DB_PORT --db $STAGING_DB_NAME --username $STAGING_DB_USER --password $STAGING_DB_PASSWORD --out $STAGING_BACKUP_DIR"
CMD_DUMP_STAGING_ECHO="echo CMD_DUMP_STAGING: $CMD_DUMP_STAGING"

#echo "mongorestore -h $STAGING_DB_HOST --port $STAGING_DB_PORT -u $STAGING_DB_USER -p $STAGING_DB_PASSWORD --authenticationDatabase $STAGING_DB_NAME --db $STAGING_DB_NAME --drop $PROD_BACKUP_DIR_DB"
#mongorestore -h $STAGING_DB_HOST --port $STAGING_DB_PORT -u $STAGING_DB_USER -p $STAGING_DB_PASSWORD --authenticationDatabase $STAGING_DB_NAME --db $STAGING_DB_NAME --drop $PROD_BACKUP_DIR_DB
CMD_RESTORE_STAGING_FROM_PROD="mongorestore -h $STAGING_DB_HOST --port $STAGING_DB_PORT -u $STAGING_DB_USER -p $STAGING_DB_PASSWORD --authenticationDatabase $STAGING_DB_NAME --db $STAGING_DB_NAME --drop $PROD_BACKUP_DIR_DB"
CMD_RESTORE_STAGING_FROM_PROD_ECHO="echo CMD_RESTORE_STAGING_FROM_PROD: $CMD_RESTORE_STAGING_FROM_PROD"

#$CMD_DUMP_PROD && $CMD_DUMP_STAGING && $CMD_RESTORE 2>&1 | tee -a "$LOG_DIR/$DIR.log"
$CMD_DUMP_PROD_ECHO 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_DUMP_PROD 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_DUMP_STAGING_ECHO 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_DUMP_STAGING 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_RESTORE_STAGING_FROM_PROD_ECHO 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_RESTORE_STAGING_FROM_PROD 2>&1 | tee -a "$LOG_DIR/$DIR.log"