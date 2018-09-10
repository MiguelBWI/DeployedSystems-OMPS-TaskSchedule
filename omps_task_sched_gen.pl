# This script reads, stores, then writes data file (XML) for MM schedule ingest
# Copy .xml output to \\[mma/mmb/cma]conas\sidata\ops\common\mms\ingest\event and then load them into MM
#
# Inputs
#   Input folder name - must contain one CSM file to process (text format)
#
# Ouputs
#   Task Request file for OMPS (XML format)
# 
# History
#   Ver.    Date	Implementor	Description
#   v1 				MGonzalez 	Outline only (non-operational) using similar outline used RFI_event_generator.pl
#   v2 
use strict;
use warnings;
use feature 'say';
use File::Find;
use DateTime;
use XML::LibXML;
#use XML::LibXSLT;                              # need to install LibXSLT
use XML::XSLT;									# use this until LibXSLT is installed

my $timestamp;                                  # to identify source file creation time
#my $time_fmt = "%m-%d-%Y  %H:%M:%S";           # not used
my $timeonly_fmt = "%H:%M:%S";                  # timeonly format (to be deleted)
my $MM_12_hr_fmt = "%b %d, %Y %I:%M:%S %p";     # primary 12hr format for output
# my $MM_12_hr_fmt = "%B %d, %I:%M:%S %p";      # alternate 12hr form

# regular expression formats
my $creationDate_re = qr/^\w+\s\w+\s\w+\/Time\s+=\s(\d{2}-\w+-\d{4}\s\d{2}:\d{2}:\d{2})/;
#                   Data#  Orbit   OrbDy    Year    DOY    Month/Day
#                            1        2       3       4
my $data_re = qr/^\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+\/\d+\s+/;      # add remaining elements to capture needed data

my $inputDir = shift @ARGV;                     # input directory
my @csm_files;                                  # array of CSM text files 
my $fCSM;                                       # name of a CSM file 
my $fhcsm;                                      # file handle for CSM file
my $ompsTaskRequest = 'OMPS_events';
my $tempFile = 'allCSM_Events';
my $intermedFile = 'omps_intermediate';
my @omps_events = ();                           # array to hold event data
my $TRANSFORM = 'OMPS_event_generator.xslt';
#my $xslt = XML::LibXSLT->new;                   # this will fail until LibXSLT is installed
my $xslt = XML::XSLT->new;
my $stylesheet = $xslt->parse_stylesheet_file($TRANSFORM);

############################################################################################
# get and read the CSM file
###########################################################################################
find (sub {
	return unless -f;  		                  # must be a file
	return unless /\.text/i;                  # must have 'text' extension
	push @csm_files, $File::Find::name
}, $inputDir);
if (@csm_files == 1) {
	$fCSM = $csm_files[0];  				# expecting only 1 xml file in the folder, for now
	say "Opening $fCSM....";
	open($fhcsm, '<', $fCSM) or die "Can't open CSM file, \"$fCSM\": $!";
} else {
	warn "Required: ONE CSM text file (see Usage Notes)\n";
	usage();
}

while (<$fhcsm>) {
    if ($_ =~ $creationDate_re) {
        say "Found creation Date $1";
        $timestamp = $1;
        $tempFile = $tempFile . "_" . $timestamp . ".txt";              # adding the creation timestamp to temp file name
        $intermedFile = $intermedFile . "_" . $timestamp . ".xml";      #
        $ompsTaskRequest = $ompsTaskRequest."_".$timestamp.".xml";      # adding original creation timestamp to the OMPS events XML filename
        
    } elsif ($_ =~ $data_re) {
        say "Found data line with $1\t$2\t$3\t$4";
        push(@omps_events, "$1|$2|$3|$4");              # use this method for saving the necessary (TBD) OMPS CSM data to create the task request file
                                                        # - save order should follow what was done for RFI event gen (for sorting)
    }
}
close $fhcsm;
die "Still working on parsing the CSM input file for the necessary data";
############################################################################################
# Use the @omps_events array to create the OMPS events file
############################################################################################
# read sub format_data in RFI_event_generator to see how the temp file is utilized as intermediate file before getting OMPS events file
open(my $fhIntermed, '>', $intermedFile) or die "can't create $intermedFile $!";
print $fhIntermed "<?xml version='1.0' encoding='UTF-8'?>\n";
print $fhIntermed "<?xml-stylesheet href=\"OMPS_event_generator.xslt\" type=\"text/xsl\"?>\n";
print $fhIntermed "<Root>\n";

# filter for desired events
foreach my $ev (sort @omps_events){
    my $data = format_data($ev);                #  <-- currently an undefined sub in this script
    print $fhIntermed $data;
}
print $fhIntermed "</Root>\n";
close($fhIntermed);

# then transform temp file to get the necessary OMPS events file that will be used for MM schedule ingest
my $transformed = $stylesheet->transform_file($tempFile);   # stylesheet is undefined since LibXSLT is not installed on laptop
open(my $fhOut, '>', $tempFile) or die "can't create $tempFile $!";
my $out_str = $transformed->toString();
$out_str =~ s/\n//;                             # removing all the line returns (maybe necessary for MM ingest)
print $fhOut $out_str,"\n";                     # over-writing the 
close($fhOut);

sub usage {
	say "\n   Usage:";
	say "\tperl [path if script not discoverable in PATH\\]omps_csm_events_generator.pl <dirname>\n";
	say "\t\t -h or -help for this message\n";
	say "\tScript input required:";
	say "\t\t 1. \'dirname\' \t- \t[folder for where \\]the CSM file (text format) exists\'";
	say "\n\tScript output:";
	say "\t\t 1. OMPS_events_<CSM_creation_date>       ~ OMPS events task request (.XML) file for MM schedule ingest\n";
	die "\t>> Please provide [path/]<InputFolderName>!\n\n";
}