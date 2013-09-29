package PerlMonksFlairApp;
use Dancer ':syntax';
use WWW::Mechanize;
use HTML::TokeParser;
use GD;

set logger => 'file';
set log => info;

our $VERSION = '0.1';

get '/' => sub {
    return template 'index';
};
get qr{/([\w -.]+)\.jpg}  => sub {
    
    my ($req_username) = splat;
    info("User => $req_username");
    my $xp = 0;#experience
    my $wr = 0;#writeups
    my $lvl = "";#level
    my $agent = WWW::Mechanize->new();

    $agent->get("http://www.perlmonks.org/?node=$req_username&type=user");
#    debug $agent->{content}; # bah dummy. You're always looking at a logged out version of the page from code!
    my $stream = HTML::TokeParser->new(\$agent->{content});
    my $username = "-none-";

    if ($stream->get_tag('title')) {
	$username = $stream->get_trimmed_text;
    }
    #if the title is Super Search then username supplied is incorrect.

    while(my $tag = $stream->get_tag('td'))
    {
	# $tag will contain this array => [$tag, $attr, $attrseq, $text]
	if($stream->get_trimmed_text("/td") eq "Experience:") {
	    $stream->get_tag('td');
	    $xp = $stream->get_trimmed_text("/td");
	    #debug "Set xp";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Level:") {
	    $stream->get_tag('td');
	    $lvl = $stream->get_trimmed_text("/td");
	    #debug "set lvl";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Writeups:") {
	    $stream->get_tag('td');
	    $wr = $stream->get_trimmed_text("/td");
	    #debug "set witeups";
	    $stream->get_tag("td");
	}
    }
    $lvl =~ m/(\d+)/;
    my $l = $1;#just moved to another variable for feeling's sake.
    #debug "$username => Xp: $xp\n $wr level = $lvl L =$l";
#    my $to_print = "$username\nLevel: $lvl\nExperience: $xp";
    my $im = undef;
    
    eval {
	$im = newFromJpeg GD::Image(join('/', setting('public'), "/badges/$l.jpg")) ;
    };
    $im->trueColor(1);
    my $white = $im->colorResolve(255,255,255);
    my $black = $im->colorResolve(0,0,0);
    #debug "color is: $black";

    my $xp_color = $white;
    if($xp =~ /none/)
    {
	    $xp = 0;
    }
    if($xp >= 250 and $xp < 400)
    {
	$xp_color = $black;
    }
    $im->stringFT($black, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'),10 , 0, 110,  40, $username);
    $im->stringFT($black, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'), 9, 0, 110,  60, $lvl);
    $im->stringFT($xp_color, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'), 9 , 0, 110,  75, "Experience ".$xp);
    #debug "Error opening image: $@" if $@;
    content_type 'image/jpeg';
    return $im->jpeg;
};

true;
