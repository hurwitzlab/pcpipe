# PCPipe

To build Docker image:

* Build cd-hit into "bin"
* docker build -t pcpipe .

To run:

    $ docker run --rm pcpipe ...

# Methods

The input is a set of ORFs (e.g. peptides from Chesapeake Bay (CB))
plus a fasta file with already clustered ORFs (like the POV+TOV
clusters).  Here are the steps:

* Use cd-hit-2d to compare the input CB peptides to a fasta file of already cluster proteins (TOV + POV)

* You will get a file with the clusters (CB + POV + TOV), taking the remaining unclustered CB peptides and self cluster them (via cd-hit)

* Take a representative sequence from each new cluster (from CB), and use the blast pipeline to compare the representative ORFS to simap.

* Provide the user with new cluster file (POV+TOV_CB, and CB self clustered) and the annotation for the new clusters (based on the representative sequence).

## Example Inputs

### CB Peptides

http://data.ivirus.us/project/view/14  Note that the input should be a directory where you can have multiple peptide files, for a test you can use the Peptides and Read_pep from this dataset)

### TOV+POV peptides:

* /iplant/home/shared/ivirus/TOV_43_viromes/TOV_43_all_contigs_predicted_proteins.faa.gz
* /iplant/home/shared/imicrobe/pov/fasta/orfs/

### TOV+POV clusters:

* /iplant/home/shared/ivirus/TOV_43_viromes/TOV_43_PCs.clstr.gz

A couple gotchas: the clusters should have a minimum of two ORFs.  Use
the same percent identity and coverage as in the scripts, some of the
POV orfs in the *fa may not be in the TOV+POV clusters (this is
because they were not in clusters with at least 20 ORFs).  But, I
think Simon included all when we ran the clustering with TOV.  Just
something to watch for.
