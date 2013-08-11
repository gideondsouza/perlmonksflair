package PerlMonksFlairApp;
use Dancer ':syntax';
use WWW::Mechanize;
use HTML::TokeParser;
use GD;

#set logger => 'file';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

#template for regex route match
#get qr{/(\w+)\.jpg} => sub {
#    my ($uname) = splat;
#    return $uname;
#};

get '/scrape' => sub {
    my $xp = 0;
    my $wr = 0;
    my $lvl = "";
    my $agent = WWW::Mechanize->new();

    $agent->get("http://www.perlmonks.org/?node=gideondsouza");
    
    debug $agent->{content}; # bah dummy. You're always looking at a logged out version of the page from code!
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
	    debug "Set xp";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Level:") {
	    $stream->get_tag('td');
	    $lvl = $stream->get_trimmed_text("/td");
	    debug "set lvl";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Writeups:") {
	    $stream->get_tag('td');
	    $wr = $stream->get_trimmed_text("/td");
	    debug "set witeups";
	    $stream->get_tag("td");
	}
    }
    $lvl =~ m/(\d+)/;
    my $l = $1;
    return "$username => Xp: $xp\n $wr level = $lvl L =$l";

};

get qr{/(\w+)\.jpg}  => sub {
    
    my ($req_username) = splat;
    my $xp = 0;
    my $wr = 0;
    my $lvl = "";
    my $agent = WWW::Mechanize->new();

    $agent->get("http://www.perlmonks.org/?node=$req_username");
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
	    debug "Set xp";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Level:") {
	    $stream->get_tag('td');
	    $lvl = $stream->get_trimmed_text("/td");
	    debug "set lvl";
	    $stream->get_tag("td");
	}
	if($stream->get_trimmed_text("/td") eq "Writeups:") {
	    $stream->get_tag('td');
	    $wr = $stream->get_trimmed_text("/td");
	    debug "set witeups";
	    $stream->get_tag("td");
	}
    }
    $lvl =~ m/(\d+)/;
    my $l = $1;#just moved to another variable for feeling's sake.
#    if($l > 10) { $l = 11;}
    debug "$username => Xp: $xp\n $wr level = $lvl L =$l";
    my $to_print = "$username\nLevel: $lvl\nExperience: $xp";
    my $im = undef;
    
    eval {
	$im = newFromJpeg GD::Image(join('/', setting('public'), "/badges/$l.jpg")) ;
    };
    $im->trueColor(1);
    my $white = $im->colorResolve(255,255,255);
    my $black = $im->colorResolve(0,0,0);
    debug "color is: $black";
    $im->stringFT($black, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'),10 , 0, 110,  40, $username);
    $im->stringFT($black, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'), 14, 0, 108,  60, "Level ".$1);
    $im->stringFT($white, join('/', setting('public'), '/Open_Sans/OpenSans-Bold.ttf'), 9 , 0, 110,  75, "Experience ".$xp);
    debug "Error opening image: $@" if $@;
    content_type 'image/jpeg';
    return $im->jpeg;
};


get '/flair' => sub {
    # create a new image
    my $im = undef;
    eval {
	$im = new GD::Image(100,100);
	# allocate some colors
	my $white = $im->colorAllocate(255,255,255);
	my $black = $im->colorAllocate(0,0,0);      
	my $red = $im->colorAllocate(255,0,0);     
	my $blue = $im->colorAllocate(0,0,255);
	# make the background transparent and interlaced
	$im->transparent($white);
	$im->interlaced('true');
	# Put a black frame around the picture
	$im->rectangle(0,0,99,99,$black);
	# Draw a blue oval
	$im->arc(50,50,95,75,0,360,$blue);
	# And fill it with red
	$im->fill(50,50,$red);

	content_type 'image/png';
	binmode STDOUT;
    };
    debug "Sanity";
    debug "Thee was an error: $@" if $@;
    return $im->png;
#    template 'flair.png'
};

true;
