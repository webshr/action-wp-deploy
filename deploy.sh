#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

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

# Set host if port is set
if [ -n "$PORT" ]; then
    HOST="$HOSTNAME:$PORT"
else 
    HOST="$HOSTNAME"
fi

# Set correct path for local directory
if [ -n "$SOURCE_DIR" ]; then
    SOURCE_DIR="$(pwd)${SOURCE_DIR#./}"
else
    SOURCE_DIR=$(pwd)/
fi

# Check if local directory has a leading slash and no trailing slash
if [[ "$SOURCE_DIR" != /* || "$SOURCE_DIR" == */ ]] && [[ "$SOURCE_DIR" != "/" ]]; then
    echo "⚠️ Error: ${SOURCE_DIR} must start with a leading slash and must not end with a trailing slash!"
    exit 1
fi

# Check if remote directory has a leading slash and no trailing slash
if [[ "$TARGET_DIR" != /* || "$TARGET_DIR" == */ ]] && [[ "$TARGET_DIR" != "/" ]]; then
    echo "⚠️ Error: ${TARGET_DIR} must start with a leading slash and must not end with a trailing slash!"
    exit 1
fi

# Set the method to be used
if [ "$MODE" = 'zip' ]; then
    METHOD="put"
    SOURCE="${SOURCE_DIR}/${ARCHIVE_NAME}.zip"
elif [ "$MODE" = 'file' ]; then
    METHOD="put"
    SOURCE="${SOURCE_DIR}/${FILE}"
elif [ "$MODE" = 'dir' ]; then
    METHOD="mirror"
    SOURCE="${SOURCE_DIR}"
else
    echo "⚠️ Error: Invalid MODE specified!"
    exit 1
fi

# Check if the SOURCE exists
if [ "$MODE" = 'zip' ] || [ "$MODE" = 'file' ]; then
    if [ ! -f "${SOURCE}" ]; then
        echo "⚠️ Error: ${SOURCE} not found!"
        exit 1
    fi
elif [ "$MODE" = 'dir' ]; then
    if [ ! -d "${SOURCE}" ]; then
        echo "⚠️ Error: ${SOURCE} directory not found!"
        exit 1
    fi
fi

# Clean up the remote directory if CLEAN_DIR is set
if [ "$CLEAN_DIR" = true ]; then
    CLEAN_DIR="rm -r $TARGET_DIR"
else
    CLEAN_DIR=""
fi

# Upload only new files if ONLY_NEWER is set
if [ "$ONLY_NEWER" = true ]; then
    ONLY_NEWER="-e --only-newer --ignore-time --delete-first"
else
    ONLY_NEWER=""
fi

# Check if the ignore file is specified
if [ -n "$IGNORE_FILE" ]; then
    # Check if the ignore file exists and is readable
    if [ -f "$IGNORE_FILE" ] && [ -r "$IGNORE_FILE" ]; then
        IGNORES=$(sed '/^!/d;s/#.*//;/^$/d' "${SOURCE_DIR}/$IGNORE_FILE" | awk '{printf "--exclude-glob %s ", $1}')
    else
        echo "⚠️ Error: Ignore file '$IGNORE_FILE' not found or not readable. Skipping..."
        IGNORES=""
    fi
else
    IGNORES=""
fi

# Set CHMOD
if [ "$CHMOD" = true ]; then
    CHMOD="chmod $CHMOD"
else
    CHMOD=""
fi

# Set debug mode if DEBUG is set to true
if [ "$DEBUG" = true ]; then
    DEBUG="-d"
    VERBOSE="--verbose"
else
    DEBUG=""
    VERBOSE=""
fi

# Set protocol-specific options
case "$PROTOCOL" in
ftp)
    PROTOCOL_OPTIONS=""
    ;;
ftps | https)
    PROTOCOL_OPTIONS="set ftp:ssl-allow true; \
                     set ftp:ssl-force $SSL_FORCE; \
                     set ftp:ssl-protect-data $SSL_PROTECT_DATA; \
                     set ssl:verify-certificate $SSL_VERIFY_CERT; \
                     set ssl:check-hostname $SSL_CHECK_HOST; \
                     set ssl:key-file $SSL_KEY_FILE;"
    ;;
sftp)
    PROTOCOL_OPTIONS="set sftp:auto-confirm $SFTP_AUTO_CONFIRM; \
                     set sftp:connect-program $SFTP_CONNECT_PROGRAM;"
    ;;
*)
    echo "⚠️ Error: Unsupported protocol specified!"
    exit 1
    ;;
esac

# Determine the command to be executed
if [ "$METHOD" = 'mirror' ]; then
    # Deploy directory
    COMMAND="mirror -R ${SOURCE} ${TARGET_DIR} $ONLY_NEWER $IGNORES $EXCLUDES $INCLUDES $VERBOSE $OPTIONS"
elif [ "$METHOD" = 'put' ]; then
    # Deploy single file/archive
    COMMAND="put -O ${TARGET_DIR} ${SOURCE} $OPTIONS"
fi

# Execute the deployment
echo "✨ Uploading '${SOURCE}' to '${HOSTNAME}${TARGET_DIR}'"

lftp $DEBUG -e "set xfer:log 1; \
  $PROTOCOL_OPTIONS \
  set net:max-retries $MAX_RETRIES; \
  mkdir -pf $TARGET_DIR; \
  $PRE_COMMANDS; \
  $CLEAN_DIR; \
  $COMMAND; \
  $CHMOD; \
  $POST_COMMANDS; \
  bye" \
    -u $USERNAME,$PASSWORD $HOST

echo "🎉 Files uploaded successfully."