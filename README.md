# modsec-sdbm-util-fuzzing
```
# git clone --recursive https://github.com/bostrt/modsec-sdbm-util-fuzzing.git
# cd modsec-sdbm-util-fuzzing
# ./run.sh -d /path/to/mod_security/default_SESSION
Cleaning up any old data
Running tests...
Complete
Found 1 Segmentation faults
Found 0 Address Sanitizer (libasan) messages
Check ./results/fuzzing.log
```
*If you are on Linux distribution with systemd, try `./show-zero-frame.sh 1`*

## Troubleshooting
```
Building modsec-sdbm-util
Error while building modsec-sdbm-util. Please investigate why build could not complete.
```
- Go into the `modsec-sdbm-util-fuzzing/modsec-sdbm-util` directory attempt building manually. Build steps are inside of the `modsec-sdbm-util/README.md`.
<hr/>
```
Starter data is required. Please create database in ./data/data.{pag,dir}
```
- Make sure you specify the `-d` flag and specify a valid database for the fuzzing to get started with. The file specified in `-d` will not have any changes made to it.
