package CTSMS::BulkProcessor::RestRequests::ctsms::shared::ToolsService::CompleteCountryName;
use strict;

## no critic

use CTSMS::BulkProcessor::ConnectorPool qw(
    get_ctsms_restapi

);

use CTSMS::BulkProcessor::RestProcessor qw(
    copy_row
    get_query_string
);

use CTSMS::BulkProcessor::RestConnectors::CtsmsRestApi qw(_get_api);
use CTSMS::BulkProcessor::RestItem qw();

require Exporter;
our @ISA = qw(Exporter CTSMS::BulkProcessor::RestItem);
our @EXPORT_OK = qw(
    complete_country_name
);

my $default_restapi = \&get_ctsms_restapi;
my $get_complete_path_query = sub {
    my ($country_name_infix, $limit) = @_;
    my %params = ();
    $params{countryNameInfix} = $country_name_infix if defined $country_name_infix;
    $params{limit} = $limit if defined $limit;
    return 'tools/complete/countryname/' . get_query_string(\%params);
};

my $fieldnames = [
    'countryname',
];

sub new {

    my $class = shift;
    my $self = CTSMS::BulkProcessor::RestItem->new($class,$fieldnames);

    copy_row($self,shift,$fieldnames);

    return $self;

}

sub complete_country_name {

    my ($country_name_infix, $limit, $load_recursive,$restapi,$headers) = @_;
    my $api = _get_api($restapi,$default_restapi);
    return builditems_fromrows($api->get(&$get_complete_path_query($country_name_infix, $limit),$headers),$load_recursive,$restapi);

}

sub builditems_fromrows {

    my ($rows,$load_recursive,$restapi) = @_;

    my $item;

    if (defined $rows and ref $rows eq 'ARRAY') {
        my @items = ();
        foreach my $row (@$rows) {
            $item = __PACKAGE__->new($row);

            # transformations go here ...

            push @items,$item;
        }
        return \@items;
    } elsif (defined $rows and ref $rows eq 'HASH') {
        $item = __PACKAGE__->new($rows);
        return $item;
    }
    return undef;

}

sub TO_JSON {
    
    my $self = shift;

    return {
        value => $self->{countryname},
        label => $self->{countryname},
    };

}

1;
