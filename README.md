# pathoSPOT-compare

This is the comparative genomics pipeline for [PathoSPOT][pathospot], the **Patho**gen **S**equencing **P**hylogenomic **O**utbreak **T**oolkit.

The pipeline is run on sequenced pathogen genomes, for which metadata (dates, locations, etc.) are kept in a relational database (either SQLite or MySQL), and it produces output files that can be interactively visualized with [pathoSPOT-visualize][].

For example output and a live demo, please see the [PathoSPOT website][pathospot]. Below, we provide documentation on how to setup and run the pipeline on your own computing environment.

[pathoSPOT-visualize]: https://github.com/powerpak/pathospot-visualize
[pathospot]: https://pathospot.org

## Requirements

This pipeline runs on Linux; however, Mac and Windows users can use [Vagrant][] to rapidly build and launch a Linux virtual machine with the pipeline ready-to-use, either locally or on cloud providers (e.g., AWS). This bioinformatics pipeline requires ruby ≥2.2 with rake ≥10.5 and bundler, python 2.7 with the modules in `requirements.txt`, [MUMmer][] 3.23, the standard Linux build toolchain, and additional software that the pipeline will build and install itself. 

[MUMmer]: http://mummer.sourceforge.net/

### Using Vagrant

Download and install Vagrant using any of the [official installers][vagrant] for Mac, Windows, or Linux. Vagrant supports both local virtualization via VirtualBox and cloud hosts (e.g., AWS).

[vagrant]: https://www.vagrantup.com/downloads.html

The fastest way to get started with Vagrant is to [install VirtualBox][virtualbox]. Then, clone this repository to a directory, `cd` into it, and run the following:

    $ vagrant up

It will take a few minutes for Vagrant to download a vanilla [Debian 9 "Stretch"][deb] VM and configure it. Once it's done, to use your new VM, type

    $ vagrant ssh

You should see the bash prompt `vagrant@stretch:/vagrant$`, and may proceed to [**Usage**](#usage) below.

The next time you want to use the pipeline in this VM, you won't need to start all over again; simply `logout` of your VM and `vagrant suspend` to save its state, and `vagrant resume; vagrant ssh` to pick up where you left off.

[virtualbox]: https://www.virtualbox.org/wiki/Downloads
[deb]: https://www.debian.org/releases/stretch/

### Hosted on AWS

Vagrant can also run this pipeline on the AWS cloud using your AWS credentials. See [README-vagrant-aws.md](https://github.com/powerpak/pathospot-compare/blob/master/README-vagrant-aws.md).

### Minerva/Chimera (Mount Sinai users only)

Mount Sinai users getting started on the [Minerva computing environment][minerva] can use an included script to setup an appropriate environment on a Chimera node (Vagrant is unnecessary); for more information see [README-minerva.md](https://github.com/powerpak/pathospot-compare/blob/master/README-minerva.md).

[minerva]: https://labs.icahn.mssm.edu/minervalab/

### Installing directly on Linux (advanced users)

You may be able to install prerequisites directly on a Linux machine by editing `scripts/bootstrap.debian-stretch.sh` to fit your distro's needs. As the name suggests, this script was designed for [Debian 9 "Stretch"][deb], but will likely run with minor changes on most Debian-based distros, including Ubuntu and Mint. Note that this script must be run as root, expects the pipeline will be run by `$DEFAULT_USER` i.e. `UID=1000`, and assumes this repo is already checked out into `/vagrant`.

## Usage

Rake, aka [Ruby Make][rake], is used to kick off the pipeline. Some tasks require certain parameters, which are provided as environment variables (and detailed more below). A quick primer on how to use Rake:

    $ rake -T                    # list the available tasks
    $ rake $TASK_1 $TASK_2       # run the tasks named $TASK_1 and $TASK_2
    $ FOO="bar" rake $TASK_1     # run $TASK_1 with variable FOO set to "bar"

**Important:** If you are not using Vagrant, whenever firing up the pipeline in a new shell, you must always run `source scripts/env.sh` _before_ running `rake`. The Vagrant environment does this automatically via `~/.profile`.

[rake]: https://github.com/ruby/rake

### Quickstart

If you used Vagrant to get started, it automatically downloads an [example dataset (tar.gz)][mrsa.tar.gz] for MRSA isolates at Mount Sinai. The genomes are saved at `example/igb` and their metadata is in `example/mrsa.db`. Default environment variables in `scripts/env.sh` are configured so that the pipeline will run on the example data.

To run the full analysis, run the following, which invokes the three main tasks (`parsnp`, `epi`, and `encounters`, explained more below).

    $ rake all

When the analysis finishes, there will be four output files saved into `out/`, which include a YYYY-MM-DD formatted date in the filename and have the following extensions:

- `.parsnp.heatmap.json` → made by `parsnp`; contains the genomic SNP distance matrix
- `.parsnp.vcfs.npz` → made by `parsnp`; contains SNP variant data for each genome
- `.encounters.tsv` → made by `encounters`; contains spatiotemporal data for patients
- `.epi.heatmap.json` → made by `epi`; contains culture test data (positives and negatives)

These outputs can be visualized using [pathoSPOT-visualize][], which the Vagrant environment automatically installs and sets up for you. If you used VirtualBox, simply go to <http://localhost:8888>, which forwards to the virtual machine. For AWS, navigate instead to your public IPv4 address, which you can obtain by running the following within the EC2 instance:

	$ curl http://169.254.169.254/latest/meta-data/public-ipv4

[mrsa.tar.gz]: https://pathospot.org/data/mrsa.tar.gz
[pathoSPOT-visualize]: https://github.com/powerpak/pathospot-visualize

### Rake tasks

#### parsnp

`rake parsnp` uses [Parsnp][] from [HarvestTools][] to create intraspecific genome alignments (on assembly sequences in FASTA files, with optional gene annotations in BED format). An optional (but recommended) preclustering step is performed with [Mash][] to only align clusters of genomes that appear closely related, allowing these alignments to include a larger core genome and increase confidence that SNP counts will accurately reflect genetic divergence.

<img src="https://pathospot.org/images/pathospot-compare-diagram.svg" width="250px"/>

This task requires you to set the `IGB_DIR`, `PATHOGENDB_URI`, and `IN_QUERY` environment variables. When using the [example environment][], these variables are set for you and run a full analysis on the example dataset.

- `IGB_DIR`: The full path to a directory containing the genome assemblies, in [FASTA format][fasta]. Each of these files should be in its own subdirectory named identically minus the `.fa` or `.fasta` extension. Each subdirectory may also contain a [BED file][bed] with gene annotations. See the `igb` directory in the [example dataset (tar.gz)][mrsa.tar.gz].
- `PATHOGENDB_URI`: A [URI to the database][sequeluri] containing metadata on the genome assemblies; for SQLite, it is `sqlite://` followed by a relative path to the file, and for MySQL the format is `mysql2://user:password@host/db_name`.
- `IN_QUERY`: An `SQL WHERE` clause that can filter which assemblies in the database are included in the analysis. For our [example][], `1=1` is used, which simply uses all of the assemblies. For your own database, it is likely useful to filter by species and/or location.

You may optionally specify two additional environment variables `MASH_CUTOFF` and `MAX_CLUSTER_SIZE`, which tune the [Mash][] preclustering step. 

- `MASH_CUTOFF`: The maximum diameter, in Mash units, of the clusters. Mash units approximate average nucleotide identity (ANI). The default is 0.02, approximating 98% ANI among all genomes within each cluster. To disable Mash preclustering, use a value of 1.
- `MAX_CLUSTER_SIZE`: The maximum number of assemblies to allow in each cluster before forcing a split. To disable Mash preclustering, use a number larger than the number of assemblies in your dataset.

[HarvestTools]: https://harvest.readthedocs.io/en/latest/
[Parsnp]: https://harvest.readthedocs.io/en/latest/content/parsnp.html
[Mash]: https://mash.readthedocs.io/en/latest/
[example]: https://github.com/powerpak/pathospot-compare/blob/master/scripts/example.env.sh
[fasta]: https://en.wikipedia.org/wiki/FASTA_format
[bed]: https://genome.ucsc.edu/FAQ/FAQformat.html#format1
[sequeluri]: https://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html

#### encounters

FIXME: `rake encounters` ... should be documented.

#### epi

FIXME: `rake epi` ... should be documented.

## Exporting data from Vagrant

If you want to copy the final outputs outside of the Vagrant environment, e.g. to serve them with [pathoSPOT-visualize][] from a different machine, use [vagrant-scp][] as follows from the _host_ machine:

	$ vagrant plugin install vagrant-scp
	$ vagrant scp default:/vagrant/out/*.json /destination/on/host
	$ vagrant scp default:/vagrant/out/*.npz /destination/on/host
	$ vagrant scp default:/vagrant/out/*.encounters.tsv /destination/on/host

[vagrant-scp]: https://github.com/invernizzi/vagrant-scp

## Other notes

This pipeline downloads and installs the appropriate versions of Mash and HarvestTools into `vendor/`.
