#!/bin/bash

echo
echo "arte.tv+7 downloader"
echo "From Oliver Prygotzki"
echo "Updated and Forked by Sylvain Doignon"
echo "ORIGNAL : https://github.com/NoNoNo/shellscripts-arte_download"
echo "FORK : https://github.com/sd65/shellscripts-arte_download"
echo

if [ "$1" == "" ]; then
  echo "Downloads a video from arte.tv+7"
  echo "Usage: artedl [URL] [Language]"
  echo "Example: artedl http://www.arte.tv/guide/fr/045907-006/l-orient-extreme-de-berlin-a-tokyo-6-10 fr"
  echo "[Language] can be set at 'fr' or 'de'"
  echo "If [Language] parameter is not set, French is given by default"
  exit
fi

# Asking for the language
echo
if [ "$2" == "" ]; then
	echo "Language not specified, using French"
	ARTEDL_LANG="fr"
else
  if [ "$2" == "fr" ]; then
	echo "Language set at : French"
	ARTEDL_LANG="fr"
  elif [ "$2" == "de" ]; then
	echo "Language set at : German"
	ARTEDL_LANG="de"
  else
	echo "Incorrect Language specified, using French"
	ARTEDL_LANG="fr"
  fi
fi
echo

# Save the page to a tmp location
curl -so /tmp/artedl1.html "$1"
echo

#Arte Player can now be static
ARTEDL_PLAYER="https://www-secure.arte.tv/playerv2/jwplayer5/mediaplayer.5.7.1894.swf"

# Find the associated JSON info file
ARTEDL_JSON_META=$(grep -m 1 .json /tmp/artedl1.html | cut -f 8 -d \")

if [ "$ARTEDL_JSON_META" == "" ]; then
  echo "Meta-JSON-URL not found"
  exit
fi

# Save (and add new lines on ",") this JSON file to a tmp location
curl -s "$ARTEDL_JSON_META" | sed 's/,/\n/g' > /tmp/artedl2.json

# Grep the HD stream
if [ "$ARTEDL_LANG" == "fr" ]; then
  ARTEDL_RTMP_HD_STREAM=$(grep -A 7 "RTMP_SQ_1" /tmp/artedl2.json | grep url | cut -d \" -f 4)
else
  ARTEDL_RTMP_HD_STREAM=$(grep -A 7 "RTMP_SQ_2" /tmp/artedl2.json | grep url | cut -d \" -f 4)
fi

if [ "$ARTEDL_RTMP_HD_STREAM" == "" ]; then
  echo "Stream HD not found"
  exit
fi

# Find the title of the video
ARTEDL_TITLE=$(grep VTI /tmp/artedl2.json | cut -d \" -f 4 | iconv -t ascii//TRANSLIT | sed -e 's/[\$/^*]/-/g')

if [ "$ARTEDL_TITLE" == "" ]; then
  echo "Warning: Title not found"
  exit
fi

# Some output
echo "Video found, starting download of : $ARTEDL_TITLE"
echo
echo
echo "Command: rtmpdump --resume -r rtmp://artestras.fcod.llnwd.net/a3903/o35/mp4:$ARTEDL_RTMP_HD_STREAM --swfVfy $ARTEDL_PLAYER -o arte.tv - $ARTEDL_TITLE.mp4"
echo

# Launch the download
rtmpdump --resume -r "rtmp://artestras.fcod.llnwd.net/a3903/o35/mp4:$ARTEDL_RTMP_HD_STREAM" --swfVfy "$ARTEDL_PLAYER" -o "$ARTEDL_TITLE - arte.tv.mp4"

# Check errors
if [ "$?" -ne "0" ]; then
  echo
  echo "rtmpdump failed..."
  echo
  exit
fi
