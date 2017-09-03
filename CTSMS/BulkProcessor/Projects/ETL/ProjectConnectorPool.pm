package CTSMS::BulkProcessor::Projects::ETL::ProjectConnectorPool;
use strict;

## no critic

use CTSMS::BulkProcessor::Projects::ETL::Settings qw(
    $sqlite_db_file
    $csv_dir
);

use CTSMS::BulkProcessor::ConnectorPool qw(
    get_connectorinstancename
);

#use CTSMS::BulkProcessor::SqlConnectors::MySQLDB;
#use CTSMS::BulkProcessor::SqlConnectors::OracleDB;
#use CTSMS::BulkProcessor::SqlConnectors::PostgreSQLDB;
use CTSMS::BulkProcessor::SqlConnectors::SQLiteDB qw(
    $staticdbfilemode
);
#cleanupdbfiles
use CTSMS::BulkProcessor::SqlConnectors::CSVDB;
#use CTSMS::BulkProcessor::SqlConnectors::SQLServerDB;
#use CTSMS::BulkProcessor::RestConnectors::CTSMSRestApi;

use CTSMS::BulkProcessor::SqlProcessor qw(cleartableinfo);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    get_sqlite_db
    sqlite_db_tableidentifier
    
    get_csv_db
    csv_db_tableidentifier

    destroy_dbs
    destroy_all_dbs
);

# thread connector pools:
my $sqlite_dbs = {};
my $csv_dbs = {};

sub get_csv_db {

    my ($instance_name,$reconnect) = @_;
    my $name = get_connectorinstancename($instance_name); #threadid(); #shift;
    if (not defined $csv_dbs->{$name}) {
        $csv_dbs->{$name} = CTSMS::BulkProcessor::SqlConnectors::CSVDB->new($instance_name); #$name);
        if (not defined $reconnect) {
            $reconnect = 1;
        }
    }
    if ($reconnect) {
        $csv_dbs->{$name}->db_connect($csv_dir);
    }
    return $csv_dbs->{$name};
      
}

sub csv_db_tableidentifier {
    
    my ($get_target_db,$tablename) = @_;
    my $target_db = (ref $get_target_db eq 'CODE') ? &$get_target_db() : $get_target_db;
    return $target_db->getsafetablename(CTSMS::BulkProcessor::SqlConnectors::CSVDB::get_tableidentifier($tablename,$csv_dir));
    
}

sub get_sqlite_db {

    my ($instance_name,$reconnect) = @_;
    my $name = get_connectorinstancename($instance_name); #threadid(); #shift;

    if (not defined $sqlite_dbs->{$name}) {
        $sqlite_dbs->{$name} = CTSMS::BulkProcessor::SqlConnectors::SQLiteDB->new($instance_name); #$name);
        if (not defined $reconnect) {
            $reconnect = 1;
        }
    }
    if ($reconnect) {
        $sqlite_dbs->{$name}->db_connect($staticdbfilemode,$sqlite_db_file);
    }

    return $sqlite_dbs->{$name};

}

sub sqlite_db_tableidentifier {

    my ($get_target_db,$tablename) = @_;
    my $target_db = (ref $get_target_db eq 'CODE') ? &$get_target_db() : $get_target_db;
    return $target_db->getsafetablename(CTSMS::BulkProcessor::SqlConnectors::SQLiteDB::get_tableidentifier($tablename,$staticdbfilemode,$sqlite_db_file));

}




sub destroy_dbs {



    foreach my $name (keys %$sqlite_dbs) {
        cleartableinfo($sqlite_dbs->{$name});
        undef $sqlite_dbs->{$name};
        delete $sqlite_dbs->{$name};
    }
    
    foreach my $name (keys %$csv_dbs) {
        cleartableinfo($csv_dbs->{$name});
        undef $csv_dbs->{$name};
        delete $csv_dbs->{$name};
    }

}

sub destroy_all_dbs() {
    destroy_dbs();
    CTSMS::BulkProcessor::ConnectorPool::destroy_dbs();
}

1;
