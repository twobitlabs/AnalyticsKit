
#!/bin/bash
#
# Shell script to upload an iOS build's debug symbols to New Relic.
#
# usage:
# This script needs to be invoked during an XCode build
#
# 1. In XCode, select your project in the navigator, then click on the application target.
# 2. Select the Build Phases tab in the settings editor.
# 3. Click the + icon above Target Dependencies and choose New Run Script Build Phase.
# 4. Add the following two lines of code to the new phase,
#     removing the '#' at the start of each line and pasting in the
#     application token from your New Relic dashboard for the app in question.
#
#SCRIPT=`/usr/bin/find "${SRCROOT}" -name newrelic_postbuild.sh | head -n 1`
#/bin/sh "${SCRIPT}" "PUT_NEW_RELIC_APP_TOKEN_HERE"
#
# Optional:
# DSYM_UPLOAD_URL - define this environment variable to override the New Relic server hostname

not_in_xcode_env() {
	echo "New Relic: $0 must be run from an XCode build"
	exit -2
}

upload_dsym_archive_to_new_relic() {
	let RETRY_LIMIT=3
	let RETRY_COUNT=0

	if [ ! -f "${DSYM_ARCHIVE_PATH}" ]; then
		echo "New Relic: Failed to archive \"${DSYM_SRC}\" to \"${DSYM_ARCHIVE_PATH}\""
		exit -3
	fi

    PLIST_FILE="${SOURCE_ROOT}/${INFOPLIST_FILE}"

    VERSION=`defaults read "${PLIST_FILE}" CFBundleShortVersionString`

    if [ $? -eq 0 ]; then
        echo got version $VERSION
    else
        VERSION=`defaults read "${PLIST_FILE}" CFBundleVersion`
    fi

	while [ "$RETRY_COUNT" -lt "$RETRY_LIMIT" ]
	do
		let RETRY_COUNT=$RETRY_COUNT+1
		echo "dSYM archive upload attempt #${RETRY_COUNT} (of ${RETRY_LIMIT})"

		echo "curl --write-out %{http_code} --silent --output /dev/null -F dsym=@\"${DSYM_ARCHIVE_PATH}\" -F buildId=\"$DSYM_UUIDS\" -F appName=\"$EXECUTABLE_NAME\" -H \"X-APP-LICENSE-KEY: ${API_KEY}\" \"${DSYM_UPLOAD_URL}\""
		SERVER_RESPONSE=$(curl --write-out %{http_code} --silent --output /dev/null -F dsym=@"${DSYM_ARCHIVE_PATH}" -F buildId="$DSYM_UUIDS"  -F appName="$EXECUTABLE_NAME" H "X-NewRelic-App-Version: ${VERSION}" -H "X-App-License-Key: ${API_KEY}" -H "X-NewRelic-OS-Name: ${PLATFORM_DISPLAY_NAME}" "${DSYM_UPLOAD_URL}")

		if [ $SERVER_RESPONSE -eq 201 ]; then
		    echo "New Relic: Successfully uploaded debug symbols"
		    break
		else
		    if [ $SERVER_RESPONSE -eq 409 ]; then
		        echo "New Relic: dSYM \"${DSYM_UUIDS}\" already uploaded"
		        break
		    else
		        echo "New Relic: ERROR \"${SERVER_RESPONSE}\" while uploading \"${DSYM_ARCHIVE_PATH}\" to \"${DSYM_ARCHIVE_PATH}\""
		        # exit -4
		    fi
		fi
	done

	/bin/rm -f "${DSYM_ARCHIVE_PATH}"
}

if [ ! $1 ]; then
	echo "usage: $0 <NEW_RELIC_APP_TOKEN>"
	exit -1
fi

if [ ! "$DWARF_DSYM_FOLDER_PATH" -o ! "$DWARF_DSYM_FILE_NAME" -o ! "$INFOPLIST_FILE" ]; then
	not_in_xcode_env
fi

if [ ! "${DSYM_UPLOAD_URL}" ]; then
	DSYM_UPLOAD_URL="https://mobile-symbol-upload.newrelic.com/symbol"
fi

#save and set IFS to only trigger on \n\b
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for dSYM in `find ${DWARF_DSYM_FOLDER_PATH} -name '*.dSYM'`
do
  API_KEY=$1
  echo processing $dSYM
  DSYM_SRC="${dSYM}"

  echo generating dSYM UUIDs
  echo "DSYM_UUIDS='xcrun dwarfdump --uuid "$DSYM_SRC" | tr '[:upper:]' '[:lower:]' | tr -d '-'| awk '{print $2}' | xargs | sed 's/ /,/g''"
  DSYM_UUIDS=`xcrun dwarfdump --uuid "$DSYM_SRC" | tr '[:upper:]' '[:lower:]' | tr -d '-'| awk '{print $2}' | xargs | sed 's/ /,/g'`
  echo gathered UUID: $DSYM_UUIDS

  # TODO if DSYM_UUIDS contains 'unsupported' then DSYM_UUIDS=''

  # TODO: Add pid/timestamp to tmp file name
  DSYM_TIMESTAMP=`date +%s`
  DSYM_ARCHIVE_PATH="/tmp/${DSYM_SRC##*/}-${DSYM_TIMESTAMP}.zip"


  if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" -a ! "$ENABLE_SIMULATOR_DSYM_UPLOAD" ]; then
    echo "New Relic: Skipping automatic upload of simulator build symbols"
    exit 0
  fi

  # TODO: Convert to function and call in background

  # Loop until upload success or retry limit is exceeded

  echo "New Relic: Archiving \"${DSYM_SRC}\" to \"${DSYM_ARCHIVE_PATH}\""
  echo /usr/bin/zip --recurse-paths --quiet "${DSYM_ARCHIVE_PATH}" "${DSYM_SRC}"
  /usr/bin/zip --recurse-paths --quiet "${DSYM_ARCHIVE_PATH}" "${DSYM_SRC}"

  echo calling : upload_dsym_archive_to_new_relic
  upload_dsym_archive_to_new_relic

done

#revert IFS
IFS=$SAVEIFS

exit 0
