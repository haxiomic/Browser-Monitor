package browsermonitor;

import lime.app.Application;

class BrowserMonitor{
	public var browserName(default, null):String;
	public var userAgent(default, null):String;

	public var windowWidth(default, null):Int;
	public var windowHeight(default, null):Int;

	public var mouseClicks(default, null):Int = 0;

	public var consoleLog:Array<String>;
	public var consoleError:Array<String>;
	public var consoleWarn:Array<String>;

	public var userData:Dynamic = {};

	var recordConsoleOutput:Bool = false;
	var serverURL:String;

	public function new(?serverURL:String = null, recordConsoleOutput:Bool = false){
		#if js

		this.serverURL = serverURL;
		this.recordConsoleOutput = recordConsoleOutput;
		this.userAgent = js.Browser.navigator.userAgent; 
		this.browserName = js.Lib.eval("
			(function(){
			    var ua= navigator.userAgent, tem, 
			    M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\\/))\\/?\\s*(\\d+)/i) || [];
			    if(/trident/i.test(M[1])){
			        tem=  /\\brv[ :]+(\\d+)/g.exec(ua) || [];
			        return 'IE '+(tem[1] || '');
			    }
			    if(M[1]=== 'Chrome'){
			        tem= ua.match(/\\bOPR\\/(\\d+)/)
			        if(tem!= null) return 'Opera '+tem[1];
			    }
			    M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
			    if((tem= ua.match(/version\\/(\\d+)/i))!= null) M.splice(1, 1, tem[1]);
			    return M.join(' ');
			})();
		");

		this.windowWidth = js.Browser.window.innerWidth;
		this.windowHeight = js.Browser.window.innerHeight;

		lime.ui.MouseEventManager.onMouseUp.add(function(x:Float, y:Float, button:Int){
			mouseClicks++;
		});

		if(recordConsoleOutput){
			consoleLog = new Array<String>();
			consoleError = new Array<String>();
			consoleWarn = new Array<String>();
			untyped{
				(function(){
				    var oldLog = console.log;
				    var oldError = console.error;
				    var oldWarn = console.warn;
				    console.log = function (message) {
				    	consoleLog.push(message);
				        oldLog.apply(console, js.Lib.eval("arguments"));
				    };
				    console.error = function (message) {
				    	oldError.push(message);
				        oldError.apply(console, js.Lib.eval("arguments"));
				    };
				    console.warn = function (message) {
				    	oldWarn.push(message);
				        oldWarn.apply(console, js.Lib.eval("arguments"));
				    };
				})();
			}
		}

		#end
	}

	public function sendReportAfterTime(seconds:Int, ?onSendCallback:Dynamic->Void){
		haxe.Timer.delay(function(){
			var report = createReportJSON();
			if(onSendCallback != null) onSendCallback(report);
			sendReport(report);
		}, seconds * 1000 );
	}

	public function sendReport(report:Dynamic){
		#if js
		if(serverURL == null)return;
		var request = new js.html.XMLHttpRequest();
		request.open('POST', serverURL, true);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		request.send(haxe.Json.stringify(report));
		#end
	}

	public inline function isSafari():Bool return (~/Safari/i).match(browserName);
	public inline function isChrome():Bool return (~/Chrome/i).match(browserName);
	public inline function isFirefox():Bool return (~/Firefox/i).match(browserName);

	inline function createReportJSON(){
		var json = {
			browserName         : browserName,
			userAgent           : userAgent,
			windowWidth         : windowWidth,
			windowHeight        : windowHeight,
			mouseClicks         : mouseClicks,
			userData            : userData,
		};
		if(recordConsoleOutput) 
			Reflect.setField(json, 'console',{
				log   : consoleLog,
				error : consoleError,
				warn  : consoleWarn
			});
		return json;
	}
}