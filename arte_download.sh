#!/bin/bash

echo
echo "arte+7 download 1.2/22.5.2011 by Oliver Prygotzki"
echo "https://github.com/NoNoNo/shellscripts-arte_download"
echo

if [ "$1" == "" ]; then
  echo "Downloads a video from arte+7"
  echo "Usage: artedl URL [of page with embedded Flash video]" 
  echo "Example: artedl http://videos.arte.tv/de/videos/FOO_BAR-123456.html"
  echo 
  exit
fi

# http://videos.arte.tv/de/videos/flaschenwahn_statt_wasserhahn-3775760.html

curl -o /tmp/artedl1.html "$1"
echo 

ARTEDL_PLAYER=$(grep "url_player" /tmp/artedl1.html | sed -E 's/^.* = "(.*)".*$/\1/')

if [ "$ARTEDL_PLAYER" == "" ]; then
  echo "Player not found"
  echo "Failed: grep \"url_player\" /tmp/artedl1.html"
  exit
fi

ARTEDL_FLVREF_META=$(grep "vars_player.videorefFileUrl" /tmp/artedl1.html | sed -E 's/^.* = "(.*)".*$/\1/')

if [ "$ARTEDL_FLVREF_META" == "" ]; then
  echo "Meta-URL not found"
  echo "Failed: grep \"vars_player.videorefFileUrl\" /tmp/artedl1.html"
  exit
fi

# <video lang="de" ref="http://videos.arte.tv/de/do_delegate/videos/flaschenwahn_statt_wasserhahn-3775762,view,asPlayerXml.xml"/>

curl "$ARTEDL_FLVREF_META" > /tmp/artedl2.xml
ARTEDL_FLVREF_DE=$(grep "video lang=.de." /tmp/artedl2.xml | sed -E 's/^.* ref="(.*)".*$/\1/')

if [ "$ARTEDL_FLVREF_DE" == "" ]; then
  echo "FlvRefDe not found"
  echo "Failed: curl \"$ARTEDL_FLVREF_META\" > /tmp/artedl2.xml | sed -E 's/^.* ref=\"(.*)\".*$/\1/'"
  exit
fi

echo 

# <url quality="hd">rtmp://artestras.fcod.llnwd.net/a3903/o35/MP4:geo/videothek/EUR_DE_FR/arteprod/A7_SGT_ENC_04_043100-000-A_PG_HQ_DE?h=7b30331f2062bebf776f0666d6972d25</url>

curl "$ARTEDL_FLVREF_DE" > /tmp/artedl3.xml
ARTEDL_FLVREF_DE_HD=$(grep "quality=.hd" /tmp/artedl3.xml | sed -E 's/^.*(rtmp.*)<.*$/\1/')

if [ "$ARTEDL_FLVREF_DE_HD" == "" ]; then
  echo "Stream not found (FLV_HD_DE)"
  echo "Failed: curl \"$ARTEDL_FLVREF_DE\" > /tmp/artedl3.xml | grep \"quality=.hd\""
  exit
fi

LANG_ARTEDL=$LANG
LANG="de_DE.ISO-8859-1"
# sed haengt sich bei UTF8-Zeichen auf
ARTEDL_TITLE=$(grep "<title>" /tmp/artedl1.html | sed -E 's/^.*<title>(.*)( - videos.arte.tv)<\/title>/\1/')
LANG=$LANG_ARTEDL
LANG_ARTEDL=''

# rtmpdump kann keine Dateien mit Umlauten anlegen :-/
# ARTEDL_TITLE=$(echo $ARTEDL_TITLE | perl -pe 's/(\P{ASCII})/sprintf("%02X", ord("$1"))/eg')

ARTEDL_TITLE=$(echo $ARTEDL_TITLE | sed -E 's/\//=/')

if [ "$ARTEDL_TITLE" == "" ]; then
  echo "Warning: Title not found"
  echo "Failed: grep \"<title>\" /tmp/artedl1.html"
  exit
fi

echo
echo "   Title: $ARTEDL_TITLE"
echo "    Meta: $ARTEDL_FLVREF_META"
echo "  FlvRef: $ARTEDL_FLVREF_DE"
echo "FlvRefHd: $ARTEDL_FLVREF_DE_HD"
echo "  Player: $ARTEDL_PLAYER"
echo "   Debug: /tmp/artedl1.html, /tmp/artedl2.xml, /tmp/artedl3.xml"
echo " Command: rtmpdump --resume --rtmp \"$ARTEDL_FLVREF_DE_HD\" --flv \"arte.tv - $ARTEDL_TITLE.flv\" --swfVfy \"$ARTEDL_PLAYER\""
echo

rtmpdump --resume --rtmp "$ARTEDL_FLVREF_DE_HD" --flv "arte.tv - $ARTEDL_TITLE.flv" --swfVfy "$ARTEDL_PLAYER"

if [ "$?" -ne "0" ]; then
  echo
  echo "rtmpdump failed..."
  echo
  exit
fi

ARTEDL_FINAL="arte.tv - $ARTEDL_TITLE.flv"

# MacOS X: Adding 'Where From' Spotlight Metadata
which xattr > /dev/null
if [ "$?" -eq "0" ]; then
  xattr -w com.apple.metadata:kMDItemWhereFroms "$1" "$ARTEDL_FINAL"
fi

which flv2m4v > /dev/null
if [ "$?" -eq "0" ]; then
  flv2m4v "$ARTEDL_FINAL"
  
  # MacOS X: Adding 'Where From' Spotlight Metadata
  which xattr > /dev/null
  if [ "$?" -eq "0" ]; then
    xattr -w com.apple.metadata:kMDItemWhereFroms "$1" "$ARTEDL_FINAL.m4v"
  fi
fi
