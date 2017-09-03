package CTSMS::BulkProcessor::Projects::WebApps::Signup::Utils;
use strict;

## no critic
use JSON qw();
#use DateTime qw();
use MIME::Base64 qw(encode_base64); # decode_base64);
use utf8;
use Encode qw(encode_utf8);

use HTTP::Status qw();

use Storable qw(dclone);

use CTSMS::BulkProcessor::ConnectorPool qw(
    get_ctsms_restapi
);
use CTSMS::BulkProcessor::Globals qw(
    $ctsmsrestapi_path
);
use CTSMS::BulkProcessor::Projects::WebApps::Signup::Settings qw(
    get_ctsms_site_lang_restapi
    $ctsms_sites
    $default_site
    $decimal_point
    $google_maps_api_url
    $language_menu
    $ctsms_base_uri
    $google_site_verification
);
use CTSMS::BulkProcessor::Calendar qw(
    split_datetime
    split_date
    split_time
);

use CTSMS::BulkProcessor::Utils qw(
    zerofill
);

use CTSMS::BulkProcessor::Array qw(contains);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    json_response
    json_error
    to_json_safe
    to_json_base64
    save_params
    get_restapi
    get_ctsms_baseuri
    get_restapi_uri
    $restapi
    get_site
    get_site_options
    get_site_option
    get_template
    apply_lwp_file_response
    get_navigation_options
    set_error
    get_error
    clear_error
    date_ui_to_iso
    date_iso_to_ui
    time_ui_to_iso
    time_iso_to_ui
    datetime_ui_to_iso
    datetime_iso_to_ui
    get_paginated_response
    get_page_index
    check_done
    check_prev
    $id_separator_string
    sanitize_decimal
    sanitize_integer
);
#save_site
#    get_site_name
#    dancerdebug
#    dancerinfo
#    dancerwarning
#    dancererror
#api_to_date

use CTSMS::BulkProcessor::RestRequests::ctsms::trial::TrialService::Trial qw();

our $restapi = \&get_restapi;

#my $datepicker_dateformat = 'dd.mm.yy'; #jquery datepicker proprietary format; yy = four digit
#my $datepicker_altformat = 'yy-mm-dd';
#my $datetimeseparator = ' ';
#my $timepicker_timeseparator = ':';

our $id_separator_string = ',';

sub date_ui_to_iso {
    my $ui_date = shift;
    return undef if (not defined $ui_date or length($ui_date) == 0);
    my ($d,$M,$y) = split(/\./, $ui_date);
    return zerofill($y,4) . '-' . zerofill($M,2) . '-' . zerofill($d,2) . ' 00:00:00';
}
sub date_iso_to_ui {
    my $iso_date = shift;
    return '' if (not defined $iso_date or length($iso_date) == 0);
    my ($date,$time) = split_datetime($iso_date);
    my ($y,$M,$d) = split_date($date);
    return zerofill($d,2) . '.' . zerofill($M,2) . '.' . zerofill($y,4);
}

sub time_ui_to_iso {
    my $ui_time = shift;
    return undef if (not defined $ui_time or length($ui_time) == 0);
    my ($h,$m) = split(/:/, $ui_time);
    return '1970-01-01 ' . zerofill($h,2) . ':' . zerofill($m,2) . ':00';
}
sub time_iso_to_ui {
    my $iso_time = shift;
    return '' if (not defined $iso_time or length($iso_time) == 0);
    my ($date,$time) = split_datetime($iso_time);
    my ($h,$m,$s) = split_time($time);
    return zerofill($h,2) . ':' . zerofill($m,2);
}

sub datetime_ui_to_iso {
    my ($ui_date,$ui_time) = @_;
    return undef if (not defined $ui_date or length($ui_date) == 0);
    return undef if (not defined $ui_time or length($ui_time) == 0);
    my ($d,$M,$y) = split(/\./, $ui_date);
    my ($h,$m) = split(/:/, $ui_time);
    return zerofill($y,4) . '-' . zerofill($M,2) . '-' . zerofill($d,2) . ' ' . zerofill($h,2) . ':' . zerofill($m,2). ':00';
}
sub datetime_iso_to_ui {
    my $iso_datetime = shift;
    return ('','') if (not defined $iso_datetime or length($iso_datetime) == 0);
    my ($date,$time) = split_datetime($iso_datetime);
    my ($y,$M,$d) = split_date($date);
    my ($h,$m,$s) = split_time($time);
    return (zerofill($d,2) . '.' . zerofill($M,2) . '.' . zerofill($y,4), zerofill($h,2) . ':' . zerofill($m,2));
}

#sub api_to_date {
#    my $api_date = shift;
#    return undef if (not defined $api_date or length($api_date) == 0);
#    my ($date,$time) = split_datetime($api_date);
#    return $date;
#}

sub json_response {
    my $data = shift;
    Dancer::content_type('application/json');
    Dancer::headers('Cache-Control', 'no-cache,no-store');
    return Dancer::to_json($data,{ allow_blessed => 1, convert_blessed => 1 });
}

sub json_error {
    Dancer::status(shift);
    my $forward = shift;
    my $respose_data = { msgs => set_error(@_), };
    if ($forward) {
        $respose_data->{forward} = Dancer::uri_for($forward);
    } else {
        clear_error();
    }
    return json_response($respose_data);
    #my $status_code = shift;
    #my $response = Dancer::SharedData->response; #->current();
    #$response->status($status_code // HTTP::Status::HTTP_NOT_FOUND);
    #$response->content((json_response(set_error(@_))));
    #return $response;
}

sub to_json_safe {
    my $data = shift;
    #return encode_utf8(Dancer::to_json($data,{ allow_blessed => 1, convert_blessed => 1, pretty => 0 }));
    return Dancer::to_json($data,{ allow_blessed => 1, convert_blessed => 1, pretty => 0 });
}

sub to_json_base64 {
    my $data = shift;
    my $json = to_json_safe($data);
    return encode_base64(utf8::is_utf8($json) ? encode_utf8($json) : $json,'');
}

#sub dancerdebug {
#    return Dancer::debug(@_);
#}
#sub dancerinfo {
#    return Dancer::info(@_);
#}
#sub dancerwarning {
#    return Dancer::warning(@_);
#}
#sub dancererror {
#    return Dancer::error(@_);
#}

sub _save_param {
    my ($result,$params,$param_name) = @_;
    if (not exists $result->{$param_name}) {
        Dancer::session($param_name,$params->{$param_name});
        $result->{$param_name} = $params->{$param_name};
    }
}

sub save_params {
    my @params_to_save = @_;
    my $params = Dancer::params();
    my $result = {};
    foreach my $param (@params_to_save) {
        if ('HASH' eq ref $param or 'Regexp' eq ref $param) {
            my $name_regexp;
            my $regexp_match_cb;
            if ('Regexp' eq ref $param) {
                $name_regexp = $param;
            } else {
                $name_regexp = $param->{regexp};
                $regexp_match_cb = $param->{match_cb};
            }
            foreach my $param_name (sort keys %$params) { #timesamp*d*ate before timestamp*t*ime
                if (my @captures = $param_name =~ $name_regexp) {
                    if ('CODE' eq ref $regexp_match_cb) {
                        if (&$regexp_match_cb($param_name,$params->{$param_name},@captures)) {
                            _save_param($result,$params,$param_name);
                        }
                    } else {
                        _save_param($result,$params,$param_name);
                    }
                }
            }
        } else {
            _save_param($result,$params,$param);
        }
    }
    #my $params = Dancer::params();
    #my $result = {};
    #foreach my $param (keys %$params) {
    #    if ($param ne 'site' and $param ne 'lang') {
    #        Dancer::session($param,$params->{$param});
    #        $result->{$param} = $params->{$param};
    #    }
    #}
    #Dancer::debug('params saved to session: ', $result);    
    return $result;
}

sub get_restapi {
    return get_ctsms_site_lang_restapi(_get_site_name(), _get_lang());
    #my $site = _get_site_name();
    #my $lang = _get_lang();
    #if (defined $site and length($site) > 0
    #    and defined $lang and length($lang) > 0) {
    #    return get_ctsms_site_lang_restapi($site, $lang);
    #} else {
    #    die('no site or no lang');
    #    return get_ctsms_restapi();
    #}
}

sub _get_site_name {
    my $site_name = Dancer::session('site');
    if ($site_name) {
        if (exists $ctsms_sites->{$site_name}) {
            #Dancer::debug('site: ', $site_name);
            return $site_name;
        #} else {
        #    Dancer::warning('unknown site: ', $site_name);
        }
    #} else {
    #    Dancer::debug('no site selected');
    }
    return $default_site;
}

#sub save_site {
#    my $params = Dancer::params();
#    if (exists $params->{'site'}) {
#        Dancer::session('site',$params->{'site'});
#    }
#}
    
sub _get_lang {
    my $lang = Dancer::Plugin::I18N::localize('lang');
    if ($lang) {
        #Dancer::debug('selected lang: ', $lang);
        return $lang;
    } else {
        #Dancer::error('no selected lang');
        die('no or empty lang in .po');
    }
}

sub _get_lang_options {
    my $installed_languages = Dancer::Plugin::I18N::installed_languages();
    my $languages = Dancer::Plugin::I18N::languages();
    my @result = ();
    foreach my $langtag (sort keys %$installed_languages) {
        Dancer::Plugin::I18N::languages([$langtag]);
        my $lang = Dancer::Plugin::I18N::localize('lang');
        my $lang_label = Dancer::Plugin::I18N::localize('lang_label') || $installed_languages->{$langtag};
        push(@result,{ lang => $lang, lang_label => $lang_label });
    }
    Dancer::Plugin::I18N::languages($languages);
    return \@result;
}

sub get_site_options {
    my @result = map { get_site_option($_); } sort keys %$ctsms_sites;
    return \@result;
}

sub get_site_option {
    my $site_name = shift;
    
    my $lang = Dancer::Plugin::I18N::localize('lang');
    my $selected_site_name = _get_site_name();
    $site_name //= $selected_site_name;
    my $site = $ctsms_sites->{$site_name};
    
    #my $site_label = $site->{label}->{$lang} || $site_name;
    my $site_label = Dancer::Plugin::I18N::localize($site->{label}) || $site_name;
    my $description;
    $description = Dancer::Plugin::I18N::localize($site->{description}) if $site->{description};
    my $department_label = $site->{department}->{name}->{$lang} || $site->{department}->{nameL10nKey};
    my $trial_department_label = $site->{trial_department}->{name}->{$lang} || $site->{trial_department}->{nameL10nKey};
    my $trial_count;
    eval {
        my $p = { page_size => 0, };
        my $trials = CTSMS::BulkProcessor::RestRequests::ctsms::trial::TrialService::Trial::get_signup_list(
            $site->{trial_department} ? $site->{trial_department}->{id} : undef,
            $p,
            undef,
            undef,$restapi);
        $trial_count = $p->{total_count};
    };
    return {
        site => $site_name,
        default => ($site->{default} ? JSON::true : JSON::false),
        selected => ($selected_site_name eq $site_name ? JSON::true : JSON::false),
        label => $site_label,
        description => $description,
        departmentLabel => $department_label,
        departmentId => $site->{department}->{id},
        trialDepartmentLabel => $trial_department_label,
        trialCount => $trial_count,
        latitude => $site->{default_geolocation_latitude},
        longitude => $site->{default_geolocation_longitude},
        trialSignup => ($site->{trial_signup} ? JSON::true : JSON::false),
    };
    
}

sub get_site {
    return dclone($ctsms_sites->{_get_site_name()});
}

sub get_navigation_options {
    
    my ($label,$path,$previous_navigation_options,$next_navigation_options) = @_;
    my @result = ();
    if ('CODE' eq ref $previous_navigation_options) {
        $previous_navigation_options = &$previous_navigation_options();
    }
    if ('ARRAY' eq ref $previous_navigation_options) {
        foreach my $previous_navigation_options (@$previous_navigation_options) {
             push(@result,$previous_navigation_options);
        }
    }
    my $url;
    $url = (Dancer::uri_for($path) . '?ts=' . time()) if $path;
    push(@result,{ label => $label, url => $url });
    if ('CODE' eq ref $next_navigation_options) {
        $next_navigation_options = &$next_navigation_options();
    }
    if ('ARRAY' eq ref $next_navigation_options) {
        foreach my $next_navigation_options (@$next_navigation_options) {
             push(@result,$next_navigation_options);
        }
    }
    return \@result;
    
}

sub apply_lwp_file_response {
    my ($lwp_response, $filename, $for_download) = @_;
    my $response = Dancer::SharedData->response;
    $response->status($lwp_response->code);        
    $response->content($lwp_response->content);
    $response->content_type($lwp_response->content_type);
    #my $filename = $lwp_response->header('Content-Disposition');
    #$filename =~ m/filename\s*=\s*"?([^"]*)"?/i;
    my $content_disposition = ($for_download ? 'attachment' : 'inline');
    if (defined $filename and length($filename) > 0) {
        $content_disposition .= '; filename="' . $filename . '"';
    }
    $response->header("Content-Disposition", $content_disposition);
    return $response;
}

sub get_template {
    
    my $view_name = shift @_;
    my %params = @_;
    
    my $js_vars = delete $params{js_model};
    $js_vars //= {};
    $js_vars //= {} unless 'HASH' eq ref $js_vars;
    $js_vars->{uriBase} = Dancer::request->uri_base;
    $js_vars->{lang} = _get_lang();
    $js_vars->{idSeparatorString} = $id_separator_string;
    $js_vars->{enableGeolocationServices} = $js_vars->{enableGeolocationServices} // JSON::false;
    $js_vars->{sessionTimeout} = Dancer::config->{session_expires};
    $js_vars->{sessionTimerPattern} = Dancer::Plugin::I18N::localize('session_timer_pattern');
    $js_vars->{enableSessionTimer} = (contains($view_name,[ 'start', '404', 'runtime_error' ]) ? JSON::false : JSON::true);
    #$js_vars->{datePickerDateFormat} = $datepicker_dateformat;
    #$js_vars->{datePickerAltFormat} = $datepicker_altformat;
    #$js_vars->{timePickerTimeSeparator} = $timepicker_timeseparator;
    #$js_vars->{timePickerHourText} = Dancer::Plugin::I18N::localize('hour_text');
    #$js_vars->{timePickerMinuteText} = Dancer::Plugin::I18N::localize('minute_text');
    #$js_vars->{session} = keys %Dancer::session;
    #$js_vars->{apiError} = "test'test'\"test\" / \\ ";
    my $js_context_json = _quote_js(to_json_safe($js_vars));
    #my $js_context_json = _quote_js(Dancer::to_json($js_vars,{ allow_blessed => 1, convert_blessed => 1, pretty => 0, }));
    
    my $script_names = delete $params{script_names};
    my $scripts;
    if ('ARRAY' eq ref $script_names) {
        $scripts = $script_names;
    } elsif ($script_names) {
        $scripts = [ $script_names ];
    } else {
        $scripts = [];
    }
    
    my $style_names = delete $params{style_names};
    my $styles;
    if ('ARRAY' eq ref $style_names) {
        $styles = $style_names;
    } elsif ($style_names) {
        $styles = [ $style_names ];
    } else {
        $styles = [];
    }
    
    my $navigation_options = delete $params{navigation_options};
    $navigation_options //= $CTSMS::BulkProcessor::Projects::WebApps::Signup::Controller::Start::navigation_options;
    if ('CODE' eq ref $navigation_options) {
        $navigation_options = &$navigation_options();
    }
    
    return Dancer::template($view_name,{
        head =>
            join("\n", map { '<script type="text/javascript" src="'. Dancer::request->uri_base .'/js/'.$_.'.js"></script>'; } @$scripts) . "\n" .
            join("\n", map { '<link rel="stylesheet" href="'. Dancer::request->uri_base .'/css/'.$_.'.css" />'; } @$styles) . "\n" .
            (($google_maps_api_url and $js_vars->{enableGeolocationServices}) ? '<script type="text/javascript" src="' . $google_maps_api_url . '"></script>' : ''),
        session => Dancer::session,
        ts => time(),
        js_context_json => $js_context_json,
        lang_options => _get_lang_options(),
        selected_lang => _get_lang(),
        site => get_site(), #logo..
        language_menu => $language_menu,
        navigation_options => $navigation_options,
        google_site_verification = $google_site_verification,
        #datepicker_dateformat => $datepicker_dateformat,
        #datepicker_altformat => $datepicker_altformat,
        %params,
    });
}

sub get_ctsms_baseuri {
    if (defined $ctsms_base_uri and length($ctsms_base_uri) > 0) {
        my $path = $ctsms_base_uri;
        $path .= '/' if $path !~ m!/$!;
        return $path;
    }
    my $site = $ctsms_sites->{_get_site_name()};
    if (defined $site and exists $site->{ctsms_base_uri} and defined $site->{ctsms_base_uri} and length($site->{ctsms_base_uri}) > 0) {
        my $path = $site->{ctsms_base_uri};
        $path .= '/' if $path !~ m!/$!;
        return $path;
    } else {
        my $api = get_restapi();
        my $path = $api->path // '';
        $path =~ s!/*$ctsmsrestapi_path/*$!!;
        #if (length($path) > 0) {
            $path .= '/' if $path !~ m!/$!;
        #}
        my $uri = $api->baseuri;
        $uri->path_query($path);
        return $uri->as_string();
    }    
}

sub get_restapi_uri {
    my $api = get_restapi();
    my $path = $api->path // '';
    my $uri = $api->baseuri;
    $uri->path_query($path);
    return $uri->as_string();
}

sub set_error {
    my @errors = @_;
    my @error_msgs = ();
    my $prompt = Dancer::Plugin::I18N::localize('error_summary');
    foreach my $error (@errors) {
        if ('HASH' eq ref $error) {
            my $has_data = 0;
            foreach my $inquiry_id (keys %{$error->{data}}) {
                push(@error_msgs,{ summary => $prompt, detail => $error->{data}->{$inquiry_id}, messageId => $inquiry_id, });
                $has_data = 1;
            }
            push(@error_msgs,{ summary => $prompt, detail => $error->{message}, }) unless $has_data;
        } else {
            push(@error_msgs,{ summary => $prompt, detail => $error, });
        }
    }
    Dancer::session('api_error',\@error_msgs);
    return \@error_msgs;
}

sub clear_error {
    Dancer::session('api_error',undef);
}

sub get_error {
    my $clear = shift;
    my $error = Dancer::session('api_error');
    clear_error() if $clear;
    return $error;
    #if ($clear) {
    #    #return delete Dancer::session->{'api_error'};#code
    #} else {
    #    return Dancer::session('api_error');
    #}
}

sub _quote_js {
   my $s = shift;
   $s =~ s/\\/\\\\/g;
   $s =~ s/'/\\'/g;
   return qq{'$s'};
}

#sub get_p {
#    my $params = shift;
#    return { page_size => $params->{s} , page_num => $params->{p}, total_count => undef };
#}

sub get_page_index {
    my $params = shift;
    return int($params->{first} / $params->{rows});
}

sub get_paginated_response {
    my ($params,$get_rows) = @_;
    my $p = { page_size => $params->{rows}, page_num => get_page_index($params) + 1, total_count => undef };
    my $rows = &$get_rows($p);
    my $response;
    if ('ARRAY' eq ref $rows) {
        $response = { rows => $rows };
    } else {
        $response = { %{$rows} };
    }
    #not updated by api call:
    $p->{first} = ((delete $p->{page_num}) - 1) * $p->{page_size};
    $p->{rows} = delete $p->{page_size};
    $response->{paginator} = $p;
    return json_response($response);
}

sub check_done {
    my $forward = shift;
    my $params = Dancer::params();
    if ($params->{done}) {
        #Dancer::session->destroy();
        Dancer::forward('/end', undef, { method => 'GET' });
        #return get_template('finish',
        #    script_names => 'finish',
        #    style_names => 'finish',
        #    js_model => {
        #        apiError => get_error(1),            
        #        siteOptions => get_site_options(),
        #    },
        #);
    } else {
        &$forward() if 'CODE' eq ref $forward;
    }
}

sub check_prev {
    my ($forward,$backward) = @_;
    my $params = Dancer::params();
    if ($params->{prev}) {
        #Dancer::session->destroy();
        &$backward() if 'CODE' eq ref $backward;
        #return get_template('finish',
        #    script_names => 'finish',
        #    style_names => 'finish',
        #    js_model => {
        #        apiError => get_error(1),            
        #        siteOptions => get_site_options(),
        #    },
        #);
    } else {
        &$forward() if 'CODE' eq ref $forward;
    }
}

sub sanitize_decimal {
    
    my ($decimal) = @_;
    return undef if (not defined $decimal or length($decimal) == 0);
    $decimal =~ s/\s+//g;
    $decimal =~ s/[,.]/$decimal_point/; #g;
    return $decimal;
    
}

sub sanitize_integer {
    
    my ($integer) = @_;
    return undef if (not defined $integer or length($integer) == 0);
    #$decimal =~ s/\s+//g;
    #$decimal =~ s/[,.]/$decimal_point/g;
    return $integer;
    
}

1;