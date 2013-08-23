#!/usr/bin/perl
use warnings;
use strict;
use File::Basename;
use Getopt::Long;
use Pod::Usage;


my @files = ();
my $help = 0;
my $lines = 10000;
my $IN;
my $v13 = 0;
my $v15 = 0;
my $v18 = 0;
my $verbose = 0;


GetOptions(
    'help|h|?' => \$help,
    'lines|l=i' => \$lines,
    'verbose|v|?' => \$verbose,
    'f|files=f{1,}' => @files,
);
pod2usage(1) if $help;

# Push the rest of the files on the files array
map {push @files, $_ } @ARGV;

map { process($_) } @files;


sub process{
    $v13 = 0;
    $v15 = 0;
    $v18 = 0;
    my $file = shift;
    if ($file =~ /\.gz$/){
        open $IN, "zcat $file | head -n $lines|" || die "Cannot open gzip $file: $!\n";
    }
    elsif($file =~ /\.bz2$/){
        open $IN, "bzcat $file | head -n $lines|" || die "Cannot open bzip $file: $!\n";
    }
    elsif($file =~ /\-/){
        open $IN, "<&STDIN" || die "Cannot read from standard in: $!\n";
    }
    else{
        open $IN, "cat $file | head -n $lines|" || die "Cannot open $file: $!\n";
    }
    while(<$IN>){
        chomp;
        next if $. % 4 != 0;
        $v18++ if m/[!"#\$\%&'\(\)\*\+,-\.\/0123456789:;<=>\?]/ ; 
        $v15++ if m/[KLMNOPQRSTUVWXYZ\[\\\]\^\_\`abcdefgh]/; 
        $v13++ if m/[\@A]/;
    }
    if($verbose){
        print "V1.3: $v13 ** Only Detects differences between v1.3 and v1.5\n";
        print "V1.5: $v15\n";
        print "V1.8: $v18\n";
    }
    
    print "$file - ";
    
    if ( $v18 > 0 ){
        print "Version 1.8 Detected\n";
    }
    elsif($v13 > 0){
        print "Version 1.3 Detected\n";
    }
    else{
        print "Version 1.5 Detected\n";
    }
}
 





__END__

=head1 NAME

detectIlluminaQuality - Detects which version of illumina fastq files is being used

=head1 SYNOPSIS

convertIlluminaQuality [-h] [-f] [-o] [-i] [file ...]

 Options:
    -h or --help            brief help message
    -l or --lines           Number of Lines used for detection
    -v or --verbose         How much would you like to know?
    -f or --files           The files to detect
    -                       read from standard in


  SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS.....................................................
  ..........................XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX......................
  ...............................IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII......................
  .................................JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ......................
  LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL....................................................
  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
  |                         |    |        |                              |                     |
 33                        59   64       73                            104                   126
  0........................26...31.......40                                
                           -5....0........9.............................40 
                                 0........9.............................40 
                                    3.....9.............................40 
  0........................26...31........41                               

 S - Sanger        Phred+33,  raw reads typically (0, 40)
 X - Solexa        Solexa+64, raw reads typically (-5, 40)
 I - Illumina 1.3+ Phred+64,  raw reads typically (0, 40)
 J - Illumina 1.5+ Phred+64,  raw reads typically (3, 40)
     with 0=unused, 1=unused, 2=Read Segment Quality Control Indicator (bold) 
     (Note: See discussion above).
 L - Illumina 1.8+ Phred+33,  raw reads typically (0, 41)

=cut
