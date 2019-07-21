#!C:\Perl\bin\perl.exe

use strict;

## no critic

use File::Basename;
use Cwd;
use lib Cwd::abs_path(File::Basename::dirname(__FILE__) . '/../../../../../');
#print qq(@INC);
use CTSMS::BulkProcessor::Globals qw(
    $logfile_path
    $system_abbreviation
);
#print qq(@INC);
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Settings qw(
    update_settings

    $dancer_sessions_path
    $dancer_environment
    $default_language_code
    $dancer_maketext_options

    $defaultsettings
    $defaultconfig
);
use CTSMS::BulkProcessor::Logging qw(
    init_log
);
use CTSMS::BulkProcessor::LogError qw();

use CTSMS::BulkProcessor::LoadConfig qw(
    load_config
    $SIMPLE_CONFIG_TYPE
    $YAML_CONFIG_TYPE
    $ANY_CONFIG_TYPE
);

use Dancer qw();

use CTSMS::BulkProcessor::Projects::WebApps::Signup::Utils qw(
    get_template
    get_error
);
#    get_site_options
#    get_navigation_options

use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::End;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Inquiry;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Trial;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Contact;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Proband;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Start;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::AutoComplete;
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::File;

#All you need to do is set up the following route as the last route:
Dancer::any(qr{.*},sub {
    #die();
    return get_template('404',
        script_names => '404',
        style_names => '404',
        js_model => {
            apiError => get_error(1),
            #probandCreated => (CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Proband::created() ? \1JSON::true : \0JSON::false),
            #probandDepartmentId => Dancer::session("proband_department_id"),
            #start_js_model(),
        },
    );
});

if (init()) {
    Dancer::start();
    #exit(0); don't, psgi/fcgi wont continue afterwards!
} else {
    #die();
    exit(1);
}

sub init {

    $CTSMS::BulkProcessor::LogError::cli = 0;
    #my $configfile = $defaultconfig;
    #my $settingsfile = $defaultsettings;
    #$CTSMS::BulkProcessor::Globals::is_perl_debug = 1;
    my $configfile = Cwd::abs_path(File::Basename::dirname(__FILE__) . '/' . $defaultconfig);
    my $settingsfile = Cwd::abs_path(File::Basename::dirname(__FILE__) . '/' . $defaultsettings);
    my $result = load_config($configfile);
    init_log();
    $result &= load_config($settingsfile,\&update_settings,$YAML_CONFIG_TYPE);
    Dancer::set('environment',$dancer_environment);
    #Dancer::set('show_errors' => $dancer_show_errors);
    Dancer::set('confdir', Cwd::abs_path(File::Basename::dirname(__FILE__))); # . '/../'));
    Dancer::set('envdir', Cwd::abs_path(File::Basename::dirname(__FILE__))); # . '/../'));
    Dancer::set('appdir', Cwd::abs_path(File::Basename::dirname(__FILE__))); # . '/../'));
    Dancer::set('views', Cwd::abs_path(File::Basename::dirname(__FILE__) . '/views/'));
    #Dancer::set('error_template', Cwd::abs_path(File::Basename::dirname(__FILE__) . '/views/error.tt'));
    Dancer::set('public', Cwd::abs_path(File::Basename::dirname(__FILE__) . '/public/'));
    Dancer::set('session_dir', $dancer_sessions_path); #Cwd::abs_path(File::Basename::dirname(__FILE__) . '/../sessions/'));
    Dancer::set('session_name', $system_abbreviation . '.session');
    #Dancer::set('session_domain', $session_domain);
    Dancer::set('log_path', $logfile_path); #Cwd::abs_path(File::Basename::dirname(__FILE__) . '/../logs/'));
    Dancer::set('logger', 'console'); #we dont see i18n init errors yet otherwise..

    Dancer::config->{plugins}->{I18N}->{directory} = 'i18n';
    Dancer::config->{plugins}->{I18N}->{lang_default} = $default_language_code;
    Dancer::config->{plugins}->{I18N}->{name_param} = 'lang';
    Dancer::config->{plugins}->{I18N}->{name_session} = 'lang';
    Dancer::config->{plugins}->{I18N}->{maketext_options} = $dancer_maketext_options;

    $result &= eval {
        require Dancer::Plugin::I18N;
        #Dancer::Plugin::I18N::languages($language_codes);
        return 1;
    };

    #Dancer::set('layouts', Cwd::abs_path(File::Basename::dirname(__FILE__) . '/../views/layouts/'));
    #Dancer::set('template' => 'template_toolkit');

    return $result;

}
