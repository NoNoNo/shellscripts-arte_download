**Downloads a video from [arte+7](http://videos.arte.tv/de/videos)**

* Usage: `artedl [URL]`
  Where URL is the URL of the page with contains the Flash video
* Example: `artedl http://videos.arte.tv/de/videos/FOO_BAR-123456.html`

Requires: 

* [`RTMPDump`](http://rtmpdump.mplayerhq.hu/)

(Optional post-processing)

* [`xattr`](http://en.wikipedia.org/wiki/Extended_file_attributes#Mac_OS_X)
  Sets the *'Where From'* Spotlight metadata
* `flv2m4v` transcribes `FLV` to `M4V`

Install:

```shell
sudo mv arte_download.sh /usr/local/bin/artedl
sudo chmod 755 /usr/local/bin/artedl
```

TODO

* Set additional metadata
