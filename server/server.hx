package;

import haxe.web.Dispatch;
import php.Web;

class Server{
	static var outputFile = 'browser-data.txt';
	static function main(){
		php.Web.setHeader('Access-Control-Allow-Origin', '*');
		php.Web.setHeader('Access-Control-Allow-Methods', 'POST');

		var json = haxe.Json.parse(Web.getPostData());
		if(json == null || json == {})return;

		Reflect.setField(json, 'ip', php.Web.getClientIP());
		Reflect.setField(json, 'timestamp', haxe.Timer.stamp());

		var appendString = (sys.FileSystem.exists(outputFile) ? ',\n' : '') + haxe.Json.stringify(json);

		var fileStream = sys.io.File.append(outputFile, false);
		fileStream.writeString(appendString);
		fileStream.close();
	}

	inline function getDispatchUri() : String {
        #if php
        //Get the index file location
        var src : String = untyped __var__('_SERVER', 'SCRIPT_NAME');
        //Remove server subfolders from URI
        return StringTools.replace(Web.getURI(), src.substr(0, src.length - "/index.php".length), "");
        #elseif neko
        return Web.getURI();
        #end
    }
}