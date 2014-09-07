package;

import php.Web;

class Server{
	static var outputFile = 'browser-data.txt';
	static function main(){
		php.Web.setHeader('Access-Control-Allow-Origin', '*');
		php.Web.setHeader('Access-Control-Allow-Methods', 'POST');

		var json = haxe.Json.parse(Web.getPostData());
		if(json == null || json == {})return;

		Reflect.setField(json, 'ip', php.Web.getClientIP());

		var appendString = (sys.FileSystem.exists(outputFile) ? ',\n' : '') + haxe.Json.stringify(json);

		var fileStream = sys.io.File.append(outputFile, false);
		fileStream.writeString(appendString);
		fileStream.close();
	}
}