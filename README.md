nexus-sh
========

Nexus release/snapshot retriever. This script shroud not be using maven metadata, which is cache dependent FWICU.

Install
-------

sudo apt-get install -y curl wget
chmod +x download-artifact.sh

Usage
-----

./download-artifact.sh -u < nexus url > -g < groupId > -i < artifactId > -t < artifactType > -e < extension >

Will retrieve snapshots artifacts by default, use "-m releases" to download releases.
