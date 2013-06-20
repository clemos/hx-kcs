#### A [Kansas-City standard](http://en.wikipedia.org/wiki/Kansas_City_standard) decoder written in [Haxe](http://www.haxe.org)

Largely ported from [py-kcs](http://www.dabeaz.com/py-kcs/index.html)

### Features

* **Target agnostic** (tested mostly with Flash, but should work on any target)
* **UTF-8 support**
* No unit tests ;)

### Usage

```haxe

import kcs.Decoder;
import flash.media.Microphone;

class Test {
  static function main(){
    var mic = Microphone.get();
    var kcs = new Decoder();
    
    mic.addEventListener( SampleEventData.SAMPLE_EVENT , readMic );
  }
  
  static function readMic( e : SampleEventData ){
    var output : BytesData = kcs.decode( e.data );
    var str : String = output.toString();
    trace(str);
  }
}

```

### Notes

The decoder keeps data that couldn't be decoded 
after every `decode()` call (incomplete bytes, unterminated UTF-8 characters, etc).
You can flush these remaining data using the decoder's `init()` method.

### See also

* https://github.com/clemos/log-for-data-decoder
* https://github.com/davidonet/LogForData2013
