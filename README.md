MicroTardis-Harvest
===================

These shell scripts are useful for harvesting data upstream of a MyTardis instance, particularly in microscopy settings.

Here's the context: http://steveko.wordpress.com/2012/09/19/a-pattern-for-multi-instrument-data-harvesting-with-mytardis/

1. Harvester (these scripts) pulls data from instrument support PCs to a staging area
2. [Atom provider](https://github.com/stevage/atom-dataset-provider) creates an Atom feed from the staging area.
3. [MyTardis](https://github.com/mytardis/mytardis) ingests the Atom feed.

* harvest.sh: The main script. Change the settings up the top to match your situation. Collects a list of directories from 
each support PC, filters it, then pulls over those directories into a new structure. The instrument name forms one level of 
the folder hierarchy.
* domounts.sh: Currently, this just pings the support PCs, and writes the result to disk.
* set_status.sh: After pinging the machines, writes the status to disk, and emails an admin (me) if there's a problem.
A kind of jerry-built Nagios.
* make_status_html.sh: Writes a small HTML status file, suitable for embedding in the front page of a MyTardis installation 
using an IFRAME.
* statusbox.css: CSS file. Probably would be better to embed this in the HTML for simplicity.
