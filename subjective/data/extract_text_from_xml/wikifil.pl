#!/usr/bin/perl

# Program to filter Wikipedia XML dumps to "clean" text consisting only of lowercase
# letters (a-z, converted from A-Z), and spaces (never consecutive).  
# All other characters are converted to spaces.  Only text which normally appears 
# in the web browser is displayed.  Tables are removed.  Image captions are 
# preserved.  Links are converted to normal text. 

# Written by Matt Mahoney, June 10, 2006.  This program is released to the public domain.
$/=">";                     # input record separator
while (<>) {
  if (/<text /) {$text=1;}  # remove all but between <text> ... </text>
  if (/#redirect/i) {$text=0;}  # remove #REDIRECT
  if ($text) {

    # Remove any text not normally visible
    if (/<\/text>/) {$text=0;}
    s/<.*>//;               # remove xml tags
    s/&amp;/&/g;            # decode URL encoded chars
    s/&lt;/</g;
    s/&gt;/>/g;
    s/<ref[^<]*<\/ref>//g;  # remove references <ref...> ... </ref>
    s/<[^>]*>//g;           # remove xhtml tags
    s/\[http:[^] ]*/[/g;    # remove normal url, preserve visible text
    s/\|thumb//ig;          # remove images links, preserve caption
    s/\|left//ig;
    s/\|right//ig;
    s/\|\d+px//ig;
    s/\[\[image:[^\[\]]*\|//ig;
    s/\[\[category:([^|\]]*)[^]]*\]\]/[[$1]]/ig;  # show categories without markup
    s/\[\[[a-z\-]*:[^\]]*\]\]//g;  # remove links to other languages
    s/\[\[[^\|\]]*\|/[[/g;  # remove wiki url, preserve visible text
    s/{{[^}]*}}//g;         # remove {{icons}} and {tables}
    s/{[^}]*}//g;
    s/\[//g;                # remove [ and ]
    s/\]//g;
    s/&[^;]*;/ /g;          # remove URL encoded chars


    # convert to lowercase letters and spaces, spell digits and remove accents
    $_=" $_ ";
    tr/A-Z/a-z/;
    s/0//g;
    s/1//g;
    s/2//g;
    s/3//g;
    s/4//g;
    s/5//g;
    s/6//g;
    s/7//g;
    s/8//g;
    s/9//g;
    s/à/a/g;
    s/á/a/g;
    s/ã/a/g;
    s/â/a/g;
    s/é/e/g;
    s/ê/e/g;
    s/í/i/g;
    s/ó/o/g;
    s/õ/o/g;
    s/ô/o/g;
    s/ú/o/g;
    s/ç/c/g;
    tr/a-z/ /cs;
    chop;
    print $_;
  }
}