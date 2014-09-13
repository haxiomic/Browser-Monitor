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

	public var onSendCallback:Dynamic->Void;

	var recordConsoleOutput:Bool = false;
	var serverURL:String;

	var startTime:Float;

	public function new(?serverURL:String = null, recordConsoleOutput:Bool = false, ?onSendCallback:Dynamic->Void){
		#if js
		this.serverURL = serverURL;
		this.recordConsoleOutput = recordConsoleOutput;
		this.onSendCallback = onSendCallback;
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

		this.startTime = haxe.Timer.stamp();
		#end
	}

	public function sendReportAfterTime(seconds:Int) 
		haxe.Timer.delay(function() sendReport(), seconds * 1000 );


	//Be cautious of using this method! It introduces a syncronous request which prevents the window from closing
	public function sendReportOnExit(?timeout_ms:Int = 500){
		js.Browser.window.onbeforeunload = function(e:Dynamic){
			var timeOnPage = haxe.Timer.stamp() - startTime;
			var report = createReportJSON();
			Reflect.setField(report, 'timeOnPage', timeOnPage);
			sendReport(report, false, timeout_ms);
		}
	}

	public function sendReport(?report:Dynamic, async:Bool = true, ?timeout_ms:Int){
		#if !js return #end
		if(serverURL == null)return;
		if(report == null)report = createReportJSON();
		if(Reflect.isFunction(onSendCallback)) onSendCallback(report);
		var request = new js.html.XMLHttpRequest();
		request.open('POST', serverURL, async);
		request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
		request.send(haxe.Json.stringify(report));

		if(timeout_ms != null){
			haxe.Timer.delay(function(){
				request.abort();
			}, timeout_ms);
		}
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