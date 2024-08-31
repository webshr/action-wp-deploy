#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Determine the mode
if [ "$MODE" = 'zip' ]; then
  METHOD="put"
  SOURCE="${ARCHIVE_NAME}.zip"
elif [ "$MODE" = 'file' ]; then
  METHOD="put"
  SOURCE="${FILE_NAME}"
elif [ "$MODE" = 'dir' ]; then
  METHOD="mirror"
  SOURCE="${LOCAL_DIR}"
else
  echo "⚠️ Error: Invalid MODE specified!"
  exit 1
fi

# Check if the SOURCE exists
if [ "$MODE" = 'zip' ]; then
  if [ ! -f "${ARCHIVE_NAME}.zip" ]; then
    echo "⚠️ Error: ${ARCHIVE_NAME}.zip not found!"
    exit 1
  fi
elif [ "$MODE" = 'file' ]; then
  if [ ! -f "${FILE_NAME}" ]; then
    echo "⚠️ Error: ${FILE_NAME} not found!"
    exit 1
  fi
elif [ "$MODE" = 'dir' ]; then
  if [ ! -d "${LOCAL_DIR}" ]; then
    echo "⚠️ Error: ${LOCAL_DIR} directory not found!"
    exit 1
  fi
fi

# Check if hostname is set
if [ -z "$HOSTNAME" ]; then
  echo "⚠️ Error: HOSTNAME is not set!"
  exit 1
fi

# Check if username is set
if [ -z "$USERNAME" ]; then
  echo "⚠️ Error: USERNAME is not set!"
  exit 1
fi

# Check if local directory has a leading slash and no trailing slash
if [[ "$LOCAL_DIR" != /* || "$LOCAL_DIR" == */ ]] && [[ "$LOCAL_DIR" != "/" ]]; then
  echo "⚠️ Error: ${LOCAL_DIR} must start with a leading slash and must not end with a trailing slash!"
  exit 1
fi

# Check if remote directory has a leading slash and no trailing slash
if [[ "$REMOTE_DIR" != /* || "$REMOTE_DIR" == */ ]] && [[ "$REMOTE_DIR" != "/" ]]; then
  echo "⚠️ Error: ${REMOTE_DIR} must start with a leading slash and must not end with a trailing slash!"
  exit 1
fi

# Clean up the remote directory if CLEAN_DIR is set
if [ "$CLEAN_DIR" = true ]; then
    CLEAN_DIR="rm -r $REMOTE_DIR"
else
    CLEAN_DIR=""
fi

# Upload only new files if ONLY_NEWER is set
if [ "$ONLY_NEWER" = true ]; then
    ONLY_NEWER="-e -n --ignore-time"
else
    ONLY_NEWER=""
fi

# Read the .distignore file and construct the exclude list
if [ "$IGNORE" = true ] && [ -f "${LOCAL_DIR}/.distignore" ]; then
    EXCLUDES=$(sed 's/#.*//;/^$/d' "${LOCAL_DIR}/.distignore" | awk -v local_dir="${LOCAL_DIR}" '{printf "--exclude-glob %s/%s ", local_dir, $1}')
else
    EXCLUDES=""
fi

# Set CHMOD
if [ "$CHMOD" = false ]; then
    CHMOD=""
else
    CHMOD="chmod $CHMOD"
fi

# Set debug mode if DEBUG is set
if [ -z "$DEBUG" ]; then
    DEBUG=""
else
    DEBUG="-d"
fi

# Determine the command to be executed
if [ "$METHOD" = 'mirror' ]; then
    COMMAND="mirror --verbose -R $ONLY_NEWER $EXCLUDES $(pwd)$SOURCE ${REMOTE_DIR}"
else
    COMMAND="put -O ${REMOTE_DIR} ${SOURCE}"
fi

# Deploy the SOURCE to the server
echo "✨ Deploying ${SOURCE} to ${HOSTNAME}/${REMOTE_DIR} using ${METHOD}..."

lftp $DEBUG -e "set xfer:log 1; \
  set ftp:ssl-allow $SECURE; \
  set ftp:ssl-force $SECURE; \
  set ftp:ssl-protect-data $SECURE; \
  set sftp:auto-confirm $AUTO_CONFIRM; \
  set ssl:verify-certificate $VERIFY; \
  set ssl:check-hostname $VERIFY; \
  set net:max-retries 3; \
  $PRE_COMMANDS; \
  $CLEAN_DIR; \
  $COMMAND; \
  $CHMOD; \
  $POST_COMMANDS; \
  bye" \
  -u $USERNAME,$PASSWORD $HOSTNAME

echo "🎉 Successfully deployed."