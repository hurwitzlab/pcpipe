#!/usr/bin/env python
# split_fa.py

"""
Split a directory full of fasta files into files with equal numbers of
sequences per file
"""

import argparse
import os
from subprocess import call
from Bio import SeqIO
import glob
import shutil
import subprocess

#from foundation import FoundationApi, FoundationJob, RegularQueue
#import FeatureApi

BLASTDBS = '/scratch/projects/tacc/iplant/SIMAP/fileshare.csb.univie.ac.at/' \
           'simap/sequences.fa'


def split_fasta(infile, outdir, files_wanted, total_sequences, file_counter):
    """
    Split fasta file into x number of files
    """
    seq_per_file = (total_sequences / files_wanted) + 1
    current_seq_count = 0
    total_seq_count = 0
    outfile = open(outdir + '/query' + str(file_counter), 'w')
    for record in SeqIO.parse(infile, 'fasta'):
        current_seq_count += 1
        total_seq_count += 1
        SeqIO.write(record, outfile, 'fasta')
        if total_seq_count == total_sequences:
            break
        if current_seq_count == seq_per_file:
            current_seq_count = 0
            file_counter += 1
            outfile.close()
            outfile = open(outdir + '/query' + str(file_counter), 'w')
    return file_counter


def upload_split_fasta(path, outdir):
    env = os.environ.copy()
    env['irodsEnvFile'] = '/var/lib/condor/.irods/.irodsEnv.imicrobe'
    call('/usr/local/icommands/iput -r ' + outdir +
         ' /iplant/home/imicrobe/scratch/' + path, shell=True, env=env)


def download_job_output(path, outdir):
    env = os.environ.copy()
    env['irodsEnvFile'] = '/var/lib/condor/.irods/.irodsEnv.imicrobe'
    call('/usr/local/icommands/iget -r /iplant/home' + path + ' '
         + outdir, shell=True, env=env)


def main():
    # Parse the command line arguments
    parser = argparse.ArgumentParser(description='Split fasta file into \
                                                  smaller pieces')
    parser.add_argument('--indir', help='Input directory')
    parser.add_argument('--inclusters', help='Input directory')
    #parser.add_argument('--j', type=int, help='Number of jobs')
    # Gets passed from DE -> imicrobe_adaptor -> this script
    parser.add_argument('--ipoutput', required=True,
                        help='iPlant archive directory')
    args = parser.parse_args()
    indir = args.indir
    inclusters = args.inclusters

    env = os.environ.copy()
    call('/usr/local/bin/imicrobe_compile.pl '+ indir +'  '+
         'compiled_proteins.fa', shell=True, env=env)

    # run cdhit to current clusters
    cdhit2doutdir = 'cdhit-2d-outdir'
    if not os.path.exists(cdhit2doutdir):
        os.mkdir(cdhit2doutdir)

    call('/usr/local/bin/pcpipe/run_cdhit-2d.sh '+ inclusters +' '+
         'compiled_proteins.fa '+ cdhit2doutdir, shell=True, env=env)

    # run cdhit to self cluster the remainder 
    cdhitoutdir = 'cdhit-outdir'
    if not os.path.exists(cdhitoutdir):
        os.mkdir(cdhitoutdir)

    call('/usr/local/bin/pcpipe/run_cdhit.sh '+ cdhit2doutdir + ' '+
         cdhitoutdir, shell=True, env=env)

    outdir = 'blast-in'
    if not os.path.exists(outdir):
        os.mkdir(outdir)
    '''if args.j:
        jobs = args.j
    else:
        jobs = 500
    '''

    jobs = 1

    file_counter = 1

    for f in glob.glob(cdhitoutdir + '/*.fa'):
        total_sequences = 0
        infile = open(f, 'rU')
        for line in infile:
            if line.startswith('>'):
                total_sequences += 1
        print total_sequences
        infile.seek(0)
	# jobs per 1000 seqs
	jobs = total_sequences/1000 + 1
        file_counter = split_fasta(infile, outdir, jobs,
                                   total_sequences, file_counter)
        print file_counter
        infile.close()
    fapi = FoundationApi.FoundationApi()
    fapi.authenticate_imicrobe()
    print 'Make directory scratch/' + args.ipoutput
    results = fapi.make_directory(args.ipoutput)
    print results
    results = fapi.make_directory(args.ipoutput + '/' + outdir)
    print results
    upload_split_fasta(args.ipoutput, outdir)
    counter = 0
    jobs = []
    # create a job queue that submits and monitors fapi jobs
    queue = RegularQueue.RegularQueue(fapi, interval=10, failures=1,
                                      verbose=True)
    for filename in os.listdir(outdir):
        inputs = {'inputSeqs': '/imicrobe/scratch/' + args.ipoutput + '/' +
                  filename}
        parameters = {'output': 'blastout.' + str(counter),
                      'processorCount': 12,
                      'blastdbs': BLASTDBS,
                      'type': 'blastx', 'descriptions': '10',
                      'eval': '1', 'aln': '10',
                      'requestedTime': '12:00:00',
                      'archivePath': '/imicrobe/scratch/jobs/job-' +
                      args.ipoutput + str(counter)}
        blast_job = FoundationJob.FoundationJob(fapi, 'blast-lonestar-2.2.25',
                                                'iMicrobe Blast 2.2.25 SIMAP',
                                                archive='true', inputs=inputs,
                                                parameters=parameters)
        queue.put_job(blast_job)
	counter = counter+1
    queue.run_queue()
    finished_jobs = queue.finished_jobs
    jobsout = 'jobs-out'
    blastout = 'blast-out'
    if not os.path.exists(jobsout):
        os.mkdir(jobsout)
    if not os.path.exists(blastout):
        os.mkdir(blastout)
    for job in finished_jobs:
        remote_folder = job.job_status['result']['archivePath']
        download_job_output(remote_folder, jobsout)
    parseout = 'parse-out'
    tophitout = 'tophit-out'
    finalout = 'final-out'
    # Copy all blastout.* files into one directory
    for blastdir in os.listdir(jobsout):
        output_folder = blastdir
        dirname = jobsout + '/' + output_folder
        print dirname
        blastout_in = glob.glob(dirname + '/blastout.*')
        if blastout_in:
            shutil.copy(blastout_in[0], blastout)
    if not os.path.exists(parseout):
        os.mkdir(parseout)
    if not os.path.exists(tophitout):
        os.mkdir(tophitout)
    for blastfile in os.listdir(blastout):
        f = blastout + '/' + blastfile
        filename, extention = os.path.splitext(blastfile)
        s = subprocess.Popen(['/usr/local/bin/imicrobe_parse_blastout.pl',
                             f], stdout=subprocess.PIPE)
        out, err = s.communicate()
        parse_file = open(parseout + '/parse' + extention, 'w')
        parse_file.write(out)
        parse_file.close()
        s2 = subprocess.Popen(['/usr/local/bin/imicrobe_parse_blastout2.pl',
                              f], stdout=subprocess.PIPE)
        top_hit, err = s2.communicate()
        tophit_file = open(tophitout + '/tophit' + extention, 'w')
        tophit_file.write(top_hit)
        tophit_file.close()
    if not os.path.exists(finalout):
        os.mkdir(finalout)
	
    env = os.environ.copy()
    call('/usr/local/bin/imicrobe_compile.pl '+ tophitout +'  '+finalout+
         '/all_tophit', shell=True, env=env)

    '''s = subprocess.Popen(['/usr/local/bin/imicrobe_compile.pl', tophitout,
                         finalout + '/all_tophit'], stdout=subprocess.PIPE)
    '''
    api = FeatureApi.FeatureApi()
    api.feature_annotate(finalout + '/all_tophit')

if __name__ == "__main__":
    main()
