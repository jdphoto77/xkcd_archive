# Description
This repo contains codes that does either bulk ingestion of or incremental updating of XKCD comics.  

The bulk_ingest script takes a starting and ending number for an argument which corresponds to the XKCD comic number, the fetch_xkcd script goes out and checks for new XKCD comics and can be run in cron.

Comics are tracked in a MariaDB Database, keeping their comic id, title, description, permalink URL, as well as their path.  Some XKCD comics (currently 4 of over 2200) can't be straight donloaded as images as they aren't images and that is noted by a column as well. 

All scripts have brief descirptions of their function in their top comment block.

# Install/Use Instructions

## Prerequisites

- At least basic knowledge of bash scripting, helpful when tweaking anything necessary for this to fit in your environment
- Install the wget package if not installed
- MariaDB Installed and at least listening on localhost ( create a database called: xkcd )
- A read/write mount of the XKCD archive area, can be local or network mounted
- Patience :)

## Installation Steps

- Take care of above prerequisites
- Fill in the xkcd_config file with relevant information
- Create database table per command below, note the encoding...some descriptions use unicode characters
- If just starting with no exisitng XKCD comics downloaded, set the current comic_id to 0 in the status table
	```bash
	INSERT INTO status (last_downloaded_id, date) VALUES (0, YYYY-MM-DD);
	```
- Let'er rip, fire off the fetch_xkcd.sh script (probably by hand the first few times)
        -- There is a good amount of error catching in this code, but there are edge cases and some things I assume will just work

## Creating the tables

Create tables using the following commands:
```bash
CREATE TABLE `comics` (
  `comic_id` int(7) NOT NULL,
  `title` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `permalink` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `not_image` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`comic_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```

```bash
CREATE TABLE `status` (
  `last_downloaded_id` int(11) DEFAULT NULL,
  `last_run` date DEFAULT NULL,
  `run_number` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`run_number`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
```
