# ebuild-bumper.sh
Experimental script for version bumping groups of related ebuilds. The 
script can also clean out older versions of the same group of related 
ebuilds. It can clean as it goes, but that is not safe for groups, as 
it will break the depgraph and cause the script the exit after repoman 
fails.
