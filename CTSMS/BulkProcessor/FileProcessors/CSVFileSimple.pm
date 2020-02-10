package CTSMS::BulkProcessor::FileProcessors::CSVFileSimple;
use strict;

## no critic

use CTSMS::BulkProcessor::Logging qw(
    getlogger
);

use CTSMS::BulkProcessor::FileProcessor;

require Exporter;
our @ISA = qw(Exporter CTSMS::BulkProcessor::FileProcessor);
our @EXPORT_OK = qw();

my $default_lineseparator = '\\n\\r|\\r|\\n';
my $default_fieldseparator = ",";
my $default_encoding = 'UTF-8';

my $buffersize = 100 * 1024;
my $threadqueuelength = 10;
my $default_numofthreads = 3;

my $blocksize = 100;

sub new {

    my $class = shift;

    my $self = CTSMS::BulkProcessor::FileProcessor->new(@_);

    $self->{numofthreads} = shift // $default_numofthreads;
    $self->{line_separator} = shift // $default_lineseparator;
    $self->{field_separator} = shift // $default_fieldseparator;
    $self->{encoding} = shift // $default_encoding;
    $self->{buffersize} = $buffersize;
    $self->{threadqueuelength} = $threadqueuelength;

    $self->{blocksize} = $blocksize;

    bless($self,$class);

    return $self;

}

sub extractfields {
    my ($context,$line_ref) = @_;
    my $separator = $context->{instance}->{field_separator};
    my @fields = split(/$separator/,$$line_ref,-1);
    return \@fields;
}

1;
