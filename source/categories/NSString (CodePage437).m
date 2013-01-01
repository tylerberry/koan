//
// NSString (CodePage437).m
//
// Copyright (c) 2013 3James Software.
//

#import "Cocoa/Cocoa.h"
#import "NSString (CodePage437).h"

@implementation NSString (CodePage437)

- (NSString *) stringWithCodePage437Substitutions
{
  unichar characters[self.length];
  
  [self getCharacters: characters range: NSMakeRange (0, self.length)];
  
  for (unsigned i = 0; i < self.length; i++)
  {
    switch (characters[i])
    {
      case 0x0001:
        characters[i] = 0x263a;
        break;
        
        /*
      case 0x0002: // ASCII Start-of-Text
        characters[i] = 0x263b;
        break;
        */
        
      case 0x0003:
        characters[i] = 0x2665;
        break;
        
      case 0x0004:
        characters[i] = 0x2666;
        break;
        
      case 0x0005:
        characters[i] = 0x2663;
        break;
        
      case 0x0006:
        characters[i] = 0x2660;
        break;
        
        /*
      case 0x0007: // ASCII Bell
        characters[i] = 0x2022;
        break;
        
      case 0x0008: // ASCII Backspace
        characters[i] = 0x25d8;
        break;
        
      case 0x0009: // ASCII Horizontal Tab
        characters[i] = 0x25cb;
        break;
        
      case 0x000a: // ASCII Line Feed
        characters[i] = 0x25d9;
        break;
        
      case 0x000b: // ASCII Vertical Tab
        characters[i] = 0x2642;
        break;
        
      case 0x000c: // ASCII Form Feed
        characters[i] = 0x2640;
        break;
        
      case 0x000d: // ASCII Carriage Return
        characters[i] = 0x266a;
        break;
        */
        
      case 0x000e:
        characters[i] = 0x266b;
        break;
        
      case 0x000f:
        characters[i] = 0x263c;
        break;
        
      case 0x0010:
        characters[i] = 0x25ba;
        break;
        
      case 0x0011:
        characters[i] = 0x25c4;
        break;
        
      case 0x0012:
        characters[i] = 0x2195;
        break;
        
      case 0x0013:
        characters[i] = 0x203c;
        break;
        
      case 0x0014:
        characters[i] = 0x00b6;
        break;
        
      case 0x0015:
        characters[i] = 0x00a7;
        break;
        
      case 0x0016:
        characters[i] = 0x25ac;
        break;
        
      case 0x0017:
        characters[i] = 0x21a8;
        break;
        
      case 0x0018:
        characters[i] = 0x2191;
        break;
        
      case 0x0019:
        characters[i] = 0x2193;
        break;
        
      case 0x001a:
        characters[i] = 0x2192;
        break;
        
        /*
      case 0x001b: // ASCII ESC.
        characters[i] = 0x2190;
        break;
        */
        
      case 0x001c:
        characters[i] = 0x221f;
        break;
        
      case 0x001d:
        characters[i] = 0x2194;
        break;
        
      case 0x001e:
        characters[i] = 0x25b2;
        break;
        
      case 0x001f:
        characters[i] = 0x25bc;
        break;
        
      case 0x007f:
        characters[i] = 0x2302;
        break;
        
      case 0x0080:
        characters[i] = 0x00c7;
        break;
        
      case 0x0081:
        characters[i] = 0x00fc;
        break;
        
      case 0x0082:
        characters[i] = 0x00e9;
        break;
        
      case 0x0083:
        characters[i] = 0x00e2;
        break;
        
      case 0x0084:
        characters[i] = 0x00e4;
        break;
        
      case 0x0085:
        characters[i] = 0x00e0;
        break;
        
      case 0x0086:
        characters[i] = 0x00e5;
        break;
        
      case 0x0087:
        characters[i] = 0x00e7;
        break;
        
      case 0x0088:
        characters[i] = 0x00ea;
        break;
        
      case 0x0089:
        characters[i] = 0x00eb;
        break;
        
      case 0x008a:
        characters[i] = 0x00e8;
        break;
        
      case 0x008b:
        characters[i] = 0x00ef;
        break;
        
      case 0x008c:
        characters[i] = 0x00ee;
        break;
        
      case 0x008d:
        characters[i] = 0x00ec;
        break;
        
      case 0x008e:
        characters[i] = 0x00c4;
        break;
        
      case 0x008f:
        characters[i] = 0x00c5;
        break;
        
      case 0x0090:
        characters[i] = 0x00c9;
        break;
        
      case 0x0091:
        characters[i] = 0x00e6;
        break;
        
      case 0x0092:
        characters[i] = 0x00c6;
        break;
        
      case 0x0093:
        characters[i] = 0x00f4;
        break;
        
      case 0x0094:
        characters[i] = 0x00f6;
        break;
        
      case 0x0095:
        characters[i] = 0x00f2;
        break;
        
      case 0x0096:
        characters[i] = 0x00fb;
        break;
        
      case 0x0097:
        characters[i] = 0x00f9;
        break;
        
      case 0x0098:
        characters[i] = 0x00ff;
        break;
        
      case 0x0099:
        characters[i] = 0x00d6;
        break;
        
      case 0x009a:
        characters[i] = 0x00dc;
        break;
        
      case 0x009b:
        characters[i] = 0x00a2;
        break;
        
      case 0x009c:
        characters[i] = 0x00a3;
        break;
        
      case 0x009d:
        characters[i] = 0x00a5;
        break;
        
      case 0x009e:
        characters[i] = 0x20a7;
        break;
        
      case 0x009f:
        characters[i] = 0x0192;
        break;
        
      case 0x00a0:
        characters[i] = 0x00e1;
        break;
        
      case 0x00a1:
        characters[i] = 0x00ed;
        break;
        
      case 0x00a2:
        characters[i] = 0x00f3;
        break;
        
      case 0x00a3:
        characters[i] = 0x00fa;
        break;
        
      case 0x00a4:
        characters[i] = 0x00f1;
        break;
        
      case 0x00a5:
        characters[i] = 0x00d1;
        break;
        
      case 0x00a6:
        characters[i] = 0x00aa;
        break;
        
      case 0x00a7:
        characters[i] = 0x00ba;
        break;
        
      case 0x00a8:
        characters[i] = 0x00bf;
        break;
        
      case 0x00a9:
        characters[i] = 0x2310;
        break;
        
      case 0x00aa:
        characters[i] = 0x00ac;
        break;
        
      case 0x00ab:
        characters[i] = 0x00bd;
        break;
        
      case 0x00ac:
        characters[i] = 0x00bc;
        break;
        
      case 0x00ad:
        characters[i] = 0x00a1;
        break;
        
      case 0x00ae:
        characters[i] = 0x00ab;
        break;
        
      case 0x00af:
        characters[i] = 0x00bb;
        break;
        
      case 0x00b0:
        characters[i] = 0x2591;
        break;
        
      case 0x00b1:
        characters[i] = 0x2592;
        break;
        
      case 0x00b2:
        characters[i] = 0x2593;
        break;
        
      case 0x00b3:
        characters[i] = 0x2502;
        break;
        
      case 0x00b4:
        characters[i] = 0x2524;
        break;
        
      case 0x00b5:
        characters[i] = 0x2561;
        break;
        
      case 0x00b6:
        characters[i] = 0x2562;
        break;
        
      case 0x00b7:
        characters[i] = 0x2556;
        break;
        
      case 0x00b8:
        characters[i] = 0x2555;
        break;
        
      case 0x00b9:
        characters[i] = 0x2563;
        break;
        
      case 0x00ba:
        characters[i] = 0x2551;
        break;
        
      case 0x00bb:
        characters[i] = 0x2557;
        break;
        
      case 0x00bc:
        characters[i] = 0x255d;
        break;
        
      case 0x00bd:
        characters[i] = 0x255c;
        break;
        
      case 0x00be:
        characters[i] = 0x255b;
        break;
        
      case 0x00bf:
        characters[i] = 0x2510;
        break;
        
      case 0x00c0:
        characters[i] = 0x2514;
        break;
        
      case 0x00c1:
        characters[i] = 0x2534;
        break;
        
      case 0x00c2:
        characters[i] = 0x252c;
        break;
        
      case 0x00c3:
        characters[i] = 0x251c;
        break;
        
      case 0x00c4:
        characters[i] = 0x2500;
        break;
        
      case 0x00c5:
        characters[i] = 0x253c;
        break;
        
      case 0x00c6:
        characters[i] = 0x255e;
        break;
        
      case 0x00c7:
        characters[i] = 0x255f;
        break;
        
      case 0x00c8:
        characters[i] = 0x255a;
        break;
        
      case 0x00c9:
        characters[i] = 0x2554;
        break;
        
      case 0x00ca:
        characters[i] = 0x2569;
        break;
        
      case 0x00cb:
        characters[i] = 0x2566;
        break;
        
      case 0x00cc:
        characters[i] = 0x2560;
        break;
        
      case 0x00cd:
        characters[i] = 0x2550;
        break;
        
      case 0x00ce:
        characters[i] = 0x256c;
        break;
        
      case 0x00cf:
        characters[i] = 0x2567;
        break;
        
      case 0x00d0:
        characters[i] = 0x2568;
        break;
        
      case 0x00d1:
        characters[i] = 0x2564;
        break;
        
      case 0x00d2:
        characters[i] = 0x2565;
        break;
        
      case 0x00d3:
        characters[i] = 0x2559;
        break;
        
      case 0x00d4:
        characters[i] = 0x2558;
        break;
        
      case 0x00d5:
        characters[i] = 0x2552;
        break;
        
      case 0x00d6:
        characters[i] = 0x2553;
        break;
        
      case 0x00d7:
        characters[i] = 0x256b;
        break;
        
      case 0x00d8:
        characters[i] = 0x256a;
        break;
        
      case 0x00d9:
        characters[i] = 0x2518;
        break;
        
      case 0x00da:
        characters[i] = 0x250c;
        break;
        
      case 0x00db:
        characters[i] = 0x2588;
        break;
        
      case 0x00dc:
        characters[i] = 0x2584;
        break;
        
      case 0x00dd:
        characters[i] = 0x258c;
        break;
        
      case 0x00de:
        characters[i] = 0x2590;
        break;
        
      case 0x00df:
        characters[i] = 0x2580;
        break;
        
      case 0x00e0:
        characters[i] = 0x03b1;
        break;
        
      case 0x00e1:
        characters[i] = 0x00df;
        break;
        
      case 0x00e2:
        characters[i] = 0x0393;
        break;
        
      case 0x00e3:
        characters[i] = 0x03c0;
        break;
        
      case 0x00e4:
        characters[i] = 0x03a3;
        break;
        
      case 0x00e5:
        characters[i] = 0x03c3;
        break;
        
      case 0x00e6:
        characters[i] = 0x00b5;
        break;
        
      case 0x00e7:
        characters[i] = 0x03c4;
        break;
        
      case 0x00e8:
        characters[i] = 0x03a6;
        break;
        
      case 0x00e9:
        characters[i] = 0x0398;
        break;
        
      case 0x00ea:
        characters[i] = 0x03a9;
        break;
        
      case 0x00eb:
        characters[i] = 0x03b4;
        break;
        
      case 0x00ec:
        characters[i] = 0x221e;
        break;
        
      case 0x00ed:
        characters[i] = 0x03c6;
        break;
        
      case 0x00ee:
        characters[i] = 0x03b5;
        break;
        
      case 0x00ef:
        characters[i] = 0x2229;
        break;
        
      case 0x00f0:
        characters[i] = 0x2261;
        break;
        
      case 0x00f1:
        characters[i] = 0x00b1;
        break;
        
      case 0x00f2:
        characters[i] = 0x2265;
        break;
        
      case 0x00f3:
        characters[i] = 0x2264;
        break;
        
      case 0x00f4:
        characters[i] = 0x2320;
        break;
        
      case 0x00f5:
        characters[i] = 0x2321;
        break;
        
      case 0x00f6:
        characters[i] = 0x00f7;
        break;
        
      case 0x00f7:
        characters[i] = 0x2248;
        break;
        
      case 0x00f8:
        characters[i] = 0x00b0;
        break;
        
      case 0x00f9:
        characters[i] = 0x2219;
        break;
        
      case 0x00fa:
        characters[i] = 0x00b7;
        break;
        
      case 0x00fb:
        characters[i] = 0x221a;
        break;
        
      case 0x00fc:
        characters[i] = 0x207f;
        break;
        
      case 0x00fd:
        characters[i] = 0x00b2;
        break;
        
      case 0x00fe:
        characters[i] = 0x25a0;
        break;
        
      case 0x00ff:
        characters[i] = 0x00a0;
        break;
        
      default:
        break;
    }
  }
  
  return [NSString stringWithCharacters: characters length: self.length];
}

@end
