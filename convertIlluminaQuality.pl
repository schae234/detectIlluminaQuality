#!/usr/bin/perl5.14.2
use warnings;
use strict;
use Getopt::Long;
use File::Basename;
use Pod::Usage;
use lib '/project/csbio/schaefer/lib/BioPerl-1.6.901/' ;
use Bio::SeqIO;
use Bio::Seq::Quality;
use IO::Compress::Gzip qw(gzip $GzipError);
use File::Copy;

my $inline = 0;
my $verbose = 0;
my $gzip = 0;
my $dry_run = 0;
my $compress_output = 1;

GetOptions(
    "help|h|?" => \&usage,
    "inline|i" => \$inline,
    "verbose|v+" => \$verbose,
    "dry-run|?" => \$dry_run,
    "compress!" => \$compress_output,
);


# The rest of the arguments should be file names
main(@ARGV);
exit 1;

sub main{
    my @files = @_; 
    map{
        convert_file($_)
    } @files;
    exit;
}

sub usage{
    pod2usage(1);    
    exit;
}

# This is a long running computation
sub convert_file{
    my $file = shift;
    print "DRY RUN!\n" if $dry_run and $verbose;
    print "Working on $file\n" if $verbose;
    my $outfile = dirname($file) . "/.phred33_" . basename($file);

    # Handle Inputs and Outputs
    my $input = $file; 
    if($file =~ m/(\.gz|\.gzip)$/){
        $input = "zcat $file |";
        $outfile =~ s/(\.gz|\.gzip)$//;
    }
    print "printing to $outfile\n" if $verbose;

    # Create Bio::Seq Objects to convert File    
    print "Converting $file\n" if $verbose; 
    my $IN = Bio::SeqIO->new(-file => "$input", -format => 'fastq-illumina' );
    my $OUT = Bio::SeqIO->new(-file => ">$outfile", -format => 'fastq' );

    while(my $data = $IN->next_seq and not $dry_run){
        $OUT->write_seq($data);
    } 
   
    # Compress the output 
    if($compress_output){
        print "Compressing $outfile\n" if $verbose; 
        gzip $outfile => $outfile.".gz"
            or die "Zip failed: $GzipError\n";
        unlink($outfile);
        $outfile = $outfile.".gz";
    }

    # Perform convertion inline
    if($inline){
        print "Replacing Old file ( $file ) with new file ($outfile)\n" if $verbose;
        move($outfile,$file) if not $dry_run;
    }
    print "----------------------------------------\n";
}


__END__

=head1 NAME

convertIlluminaQuality - Converts older versions of illumina base qualities to 1.8+ version (Phred33)

=head1 SYNOPSIS

convertIlluminaQuality [-h] [-f] [-o] [-i] [file ...]

 Options:
    -h or --help            brief help message
    -o or --out             output directory (defaults to same directory as input file)
    -i or --inline          Should we edit the input files inline?
    -v or --verbose         How much would you like to know?

=cut
