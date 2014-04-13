%{
/*
 * AutoHyperlinks Framework (c) 2004-2008 by the following:
 *
 *   Colin Barrett, Graham Booker, Jorge Salvador Caffarena, Evan Schoenberg, Augie Fackler, Stephen Holt, Peter Hosey,
 *   Adam Iser, Jeffrey Melloy, Toby Peterson, Eric Richie, David Smith.
 *
 * License:
 *
 *   Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
 *   following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 *     disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
 *     following disclaimer in the documentation and/or other materials provided with the distribution.
 *   * Neither the name of the AutoHyperlinks Framework nor the names of its contributors may be used to endorse or
 *     promote products derived from this software without specific prior written permission.
 *
 *   THIS SOFTWARE IS PROVIDED BY ITS DEVELOPERS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 *   EVENT SHALL ITS DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 *   OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 *   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *   POSSIBILITY OF SUCH DAMAGE.
 *
 * Modifications by Tyler Berry.
 * Copyright (c) 2013 3James Software.
 */

/*
 *
 *	Options used:	noyywrap      : act as if yywrap always returns 1
 *					8bit                : always force 8-bit chars.
 *					caseless            : case insensitive lexer
 *					never-interactive   : prevents flex from including some calls to gettty() and such
 *										  -- gives a slight performace gain.
 *					prefix=...          : replace YY_whatever with prefix - avoids symbol collisions
 *					debug               : turns on debugging output (string + accepting rule)
 *										  -- only use while editing rules, and don't commit with this on
 *										     (it generates a lot of unnecessary output and kills performace.)
 *
 *	Variables used:		uint AHStringOffset : the position of the pointer, relative to the parent string
 *											  incremented by yyleng at each yylex() call.
 *	               		 int AHValidShift	: Used only in CANONICAL start state
 *											  ensures that yyleng reports whole length of the string,
 *											  without a costly call to yymore().
 */
#include "AHLinkLexer.h"
%}

/* This is all valid TLDs according to ICANN as of 17 March 2014, version 2014031700. */

ccTLD           (ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)
sTLD            (aero|asia|cat|coop|edu|int|jobs|mil|mobi|museum|tel|travel|xxx)
uTLD            (biz|com|gov|info|name|net|org|post|pro)
nsTLD           (academy|actor|agency|bar|bargains|berlin|best|bid|bike|blue|boutique|build|builders|buzz|cab|camera|camp|cards|careers|catering|center|ceo|cheap|christmas|cleaning|clothing|club|codes|coffee|community|company|computer|condos|construction|contractors|cool|cruises|dance|dating|democrat|diamonds|directory|dnp|domains|education|email|enterprises|equipment|estate|events|expert|exposed|farm|fish|flights|florist|foundation|futbol|gallery|gift|glass|graphics|guitars|guru|holdings|holiday|house|immobilien|industries|ink|institute|international|jetzt|kaufen|kim|kitchen|kiwi|koeln|kred|land|lighting|limo|link|luxury|maison|management|mango|marketing|menu|moda|monash|nagoya|neustar|ninja|okinawa|onl|partners|parts|photo|photography|photos|pics|pink|plumbing|productions|properties|pub|qpon|recipes|red|rentals|repair|report|reviews|rich|ruhr|sexy|shiksha|shoes|singles|social|solar|solutions|supplies|supply|support|systems|tattoo|technology|tienda|tips|today|tokyo|tools|training|uno|vacations|ventures|viajes|villas|vision|vote|voting|voto|voyage|wang|watch|wed|wien|wiki|works|xyz|zone)
inTLD           (xn--3bst00m|xn--3ds443g|xn--3e0b707e|xn--45brj9c|xn--55qw42g|xn--55qx5d|xn--6frz82g|xn--6qq986b3xl|xn--80ao21a|xn--80asehdb|xn--80aswg|xn--90a3ac|xn--c1avg|xn--cg4bki|xn--clchc0ea0b2g2a9gcd|xn--d1acj3b|xn--fiq228c5hs|xn--fiq64b|xn--fiqs8s|xn--fiqz9s|xn--fpcrj9c3d|xn--fzc2c9e2c|xn--gecrj9c|xn--h2brj9c|xn--i1b6b1a6a2e|xn--io0a7i|xn--j1amh|xn--j6w193g|xn--kprw13d|xn--kpry57d|xn--l1acc|xn--lgbbat1ad8j|xn--mgb9awbf|xn--mgba3a4f16a|xn--mgbaam7a8h|xn--mgbab2bd|xn--mgbayh7gpa|xn--mgbbh1a71e|xn--mgbc0a9azcg|xn--mgberp4a5d4ar|xn--mgbx4cd0ab|xn--ngbc5azd|xn--nqv7f|xn--nqv7fs00ema|xn--o3cw4h|xn--ogbpf8fl|xn--p1ai|xn--pgbs0dh|xn--q9jyb4c|xn--rhqv96g|xn--s9brj9c|xn--unup4y|xn--wgbh1c|xn--wgbl6a|xn--xkc2al3hye2a|xn--xkc2dl3a5ee0h|xn--yfro4i67o|xn--ygbi2ammx|xn--zfr164b)

TLDs            ({ccTLD}|{sTLD}|{uTLD}|{nsTLD}|{inTLD}|arpa|local)

%{
/*The Unicode standard, version 4.1, table 3-6, says that the highest byte that will occur in a valid UTF-8 sequence is 0xF4.*/
%}
userAndPass     [^:@[:space:]]+(:[^:@[:space:]]+)?
singleDomain    [_[:alnum:]\x80-\xf4-]+

urlPath         \/[^[:space:]]*
urlQuery        \?.*
urlSpec         ({singleDomain}\.)+{TLDs}(:[0-9]+)?({urlPath}|{urlQuery})?
urlCSpec        {singleDomain}(\.{singleDomain})*(:[0-9]+)?({urlPath}|{urlQuery})?

ipv4address     ([0-9]{1,3}\.){3}([0-9]{1,3})
ipURL           {ipv4address}(:[0-9]+)?{urlPath}?

hex4            [0-9A-Fa-f]{1,4}
ipv6HexSeq      {hex4}?(::?{hex4}){1,7}
ipv6HexPart     ({ipv6HexSeq})|(::{ipv6HexSeq})
ipv6Address     {ipv6HexPart}({ipv4address})?
ipv6URL         \[{ipv6Address}](:[0-9]+)?{urlPath}?

userAtDomain	[^:@\/[:space:]]+\@{singleDomain}(\.{singleDomain})*
mailSpec        {userAtDomain}\.{TLDs}

%option noyywrap nounput noinput 8bit caseless align nodefault never-interactive reentrant warn prefix="AH"

%x CANONICAL TENTATIVE
%%

<CANONICAL>({userAndPass}@)?{urlCSpec}|{ipURL}|{ipv6URL} {yyleng += yyextra.urlLength;
                                                          BEGIN INITIAL;
                                                          return AH_URL_VALID;}

<CANONICAL>.*                                            {BEGIN INITIAL;
                                                          return AH_URL_INVALID;}

<TENTATIVE>[^[:space:]]+                                 {yyleng += yyextra.urlLength;
                                                          BEGIN INITIAL;
                                                          return AH_URL_TENTATIVE;}

<TENTATIVE>.*                                            {BEGIN INITIAL;
                                                          return AH_URL_INVALID;}

file:\/\/\/.*           {return AH_FILE_VALID;}


telnet:\/\/             |
daap:\/\/               |
itms:\/\/               |
smb:\/\/                |
afp:\/\/                |
s?ftp:\/\/              |
vnc:\/\/                |
webcal:\/\/             |
feeds?:\/\/             |
cifs:\/\/               |
help:\/\/               |
rtsp:\/\/               |
ssh:\/\/                |
https?:\/\/             {yyextra.urlLength = yyleng; yyextra.schemeLength = yyleng - 3; BEGIN CANONICAL;}

[[:alnum:]\-_]+:\/\/    {yyextra.urlLength = yyleng; yyextra.schemeLength = yyleng - 3; BEGIN TENTATIVE;}

mailto:{mailSpec}       {return AH_MAILTO_VALID;}
{mailSpec}              {return AH_MAILTO_DEGENERATE;}

[[:alnum:]\-_]+:        {yyextra.urlLength = yyleng; yyextra.schemeLength = yyleng - 1; BEGIN TENTATIVE;}

{urlSpec}               {return AH_URL_DEGENERATE;}

.                       {return AH_URL_INVALID;}
%%
