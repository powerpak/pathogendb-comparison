#!/bin/bash

module unload ruby
module load ruby

# You need to configure this with a connection string for PathogenDB's MySQL database
export PATHOGENDB_MYSQL_URI="mysql2://user:pass@host/database"

# Defaults will probably work for these
export PERL5LIB="/usr/bin/perl5.10.1"
export TMP="/sc/orga/scratch/$USER/tmp"

# Ensures that the required module files are in MODULEPATH
if [[ ":$MODULEPATH:" != *":/hpc/packages/minerva-mothra/modulefiles:"* ]]; then
    export MODULEPATH="${MODULEPATH:+"$MODULEPATH:"}/hpc/packages/minerva-mothra/modulefiles"
fi
