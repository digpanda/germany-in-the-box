#!/bin/sh
DIR=`date +%Y-%m-%d-%H_%M_%S`
BACKUP_DIR=~/dbbackup
LOG_DIR=$BACKUP_DIR/log

STAGING_BACKUP_DIR=$BACKUP_DIR/staging_$DIR
LOCAL_BACKUP_DIR=$BACKUP_DIR/local_$DIR

mkdir $STAGING_BACKUP_DIR
mkdir $LOCAL_BACKUP_DIR

STAGING_DB_HOST=dogen.mongohq.com
STAGING_DB_PORT=10020
STAGING_DB_NAME=a_chat_development
STAGING_DB_USER=gitb
STAGING_DB_PASSWORD=lyh2cool

STAGING_BACKUP_DIR_DB=$STAGING_BACKUP_DIR/$STAGING_DB_NAME

LOCAL_DB_HOST=127.0.0.1
LOCAL_DB_PORT=27017
LOCAL_DB_NAME=digpanda
LOCAL_DB_USER=loschcode
LOCAL_DB_PASSWORD=achat2cool

#echo "mongodump --host $STAGING_DB_HOST --port $STAGING_DB_PORT --db $STAGING_DB_NAME --username $STAGING_DB_USER --password $STAGING_DB_PASSWORD --out $STAGING_BACKUP_DIR"
#mongodump --host $STAGING_DB_HOST --port $STAGING_DB_PORT --db $STAGING_DB_NAME --username $STAGING_DB_USER --password $STAGING_DB_PASSWORD --out $STAGING_BACKUP_DIR
CMD_DUMP_STAGING="mongodump --host $STAGING_DB_HOST --port $STAGING_DB_PORT --db $STAGING_DB_NAME --username $STAGING_DB_USER --password $STAGING_DB_PASSWORD --out $STAGING_BACKUP_DIR"
CMD_DUMP_STAGING_ECHO="echo CMD_DUMP_STAGING: $CMD_DUMP_STAGING"

#echo "mongodump --host $LOCAL_DB_HOST --port $LOCAL_DB_PORT --db $LOCAL_DB_NAME --username $LOCAL_DB_USER --password $LOCAL_DB_PASSWORD --out $LOCAL_BACKUP_DIR"
#mongodump --host $LOCAL_DB_HOST --port $LOCAL_DB_PORT --db $LOCAL_DB_NAME --username $LOCAL_DB_USER --password $LOCAL_DB_PASSWORD --out $LOCAL_BACKUP_DIR
CMD_DUMP_LOCAL="mongodump --host $LOCAL_DB_HOST --port $LOCAL_DB_PORT --db $LOCAL_DB_NAME --username $LOCAL_DB_USER --password $LOCAL_DB_PASSWORD --out $LOCAL_BACKUP_DIR"
CMD_DUMP_LOCAL_ECHO="echo CMD_DUMP_LOCAL: $CMD_DUMP_LOCAL"

#echo "mongorestore -h $LOCAL_DB_HOST --port $LOCAL_DB_PORT -u $LOCAL_DB_USER -p $LOCAL_DB_PASSWORD --authenticationDatabase $LOCAL_DB_NAME --db $LOCAL_DB_NAME --drop $STAGING_BACKUP_DIR_DB"
#mongorestore -h $LOCAL_DB_HOST --port $LOCAL_DB_PORT -u $LOCAL_DB_USER -p $LOCAL_DB_PASSWORD --authenticationDatabase $LOCAL_DB_NAME --db $LOCAL_DB_NAME --drop $STAGING_BACKUP_DIR_DB
CMD_RESTORE_LOCAL_FROM_STAGING="mongorestore -h $LOCAL_DB_HOST --port $LOCAL_DB_PORT -u $LOCAL_DB_USER -p $LOCAL_DB_PASSWORD --authenticationDatabase $LOCAL_DB_NAME --db $LOCAL_DB_NAME --drop $STAGING_BACKUP_DIR_DB"
CMD_RESTORE_LOCAL_FROM_STAGING_ECHO="echo CMD_RESTORE_LOCAL_FROM_STAGING: $CMD_RESTORE_LOCAL_FROM_STAGING"

#$CMD_DUMP_STAGING && $CMD_DUMP_LOCAL && $CMD_RESTORE 2>&1 | tee -a "$LOG_DIR/$DIR.log"
$CMD_DUMP_STAGING_ECHO 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_DUMP_STAGING 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_DUMP_LOCAL_ECHO 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_DUMP_LOCAL 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_RESTORE_LOCAL_FROM_STAGING_ECHO 2>&1 | tee -a "$LOG_DIR/$DIR.log" && $CMD_RESTORE_LOCAL_FROM_STAGING 2>&1 | tee -a "$LOG_DIR/$DIR.log"