#!/bin/bash
# backs up Ghost blog content
# requires downtime, but attempts to keep it at a minimum
# created by Dave Snigier - https://davesnigier.com/backups-for-ghost-blogs

### ----- Configuration ----- ###

GHOST_HOME_DIRECTORY="/var/www/ghost"
GHOST_STOP_CMD="service ghost stop"
GHOST_START_CMD="service ghost start"
BACKUP_LOG="/var/log/ghost-backup.log"
BACKUP_DIRECTORY="/root/ghost-backup"
BACKUP_DAYS_TO_KEEP=30

### --------- Code ---------- ###

# log a line with datetime stamp and also send to stdout
log () {
	echo "${@}"
	echo $(date '+%Y-%m-%d %H:%M:%S') "${@}" >> "${BACKUP_LOG}"
}

log "[INFO] Started ghost backup script"

# create backup directory if it doesn't exist
output=$(mkdir -p "${BACKUP_DIRECTORY}" 2>&1)
if [[ $? != 0 ]]; then
	log "[ERROR] Cannot create backup directory: ${output}"
	exit 1
fi

# stop ghost so database doesn't get corrupted
output=$(${GHOST_STOP_CMD} 2>&1)
if [[ $? != 0 ]]; then
	log "[ERROR] Cannot stop Ghost. Call the ghostbusters?: ${output}"
	exit 1
fi
log "[INFO] Ghost stopped"

# bundle and compress all files in ghost install
backup_filename="ghost-backup_$(date '+%Y-%m-%dT%H%M%S').tar.gz"
backup_path="${BACKUP_DIRECTORY}/${backup_filename}"
cd "${GHOST_HOME_DIRECTORY}"
output=$(tar cfz "${backup_path}" "content" 2>&1)
if [[ $? != 0 ]]; then
	log "[ERROR] Cannot create backup file: ${output}"
else
	log "[INFO] Ghost backed up to ${backup_filename}"
fi

# start ghost back up again
output=$(${GHOST_START_CMD} 2>&1)
if [[ $? != 0 ]]; then
	log "[ERROR] Cannot start Ghost: ${output}"
	exit 1
fi
log "[INFO] Ghost started"


# remove old backups
log "[INFO] Deleting backups older than ${BACKUP_DAYS_TO_KEEP} days"
output=$(find "${BACKUP_DIRECTORY}" -iname 'ghost-backup_*.tar.gz' -mtime +${BACKUP_DAYS_TO_KEEP} -delete 2>&1)
if [[ $? != 0 ]]; then
	log "[ERROR] Unable to remove old backups: ${output}"
	exit 1
fi


log "[INFO] Script finished"
