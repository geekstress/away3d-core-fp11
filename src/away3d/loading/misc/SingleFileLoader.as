﻿package away3d.loading.misc{	import away3d.events.AssetEvent;	import away3d.events.LoadingEvent;	import away3d.events.LoadingEvent;	import away3d.loading.parsers.ImageParser;	import away3d.loading.parsers.ParserBase;	import away3d.loading.parsers.ParserDataFormat;		import flash.events.Event;	import flash.events.EventDispatcher;	import flash.events.IOErrorEvent;	import flash.net.URLLoader;	import flash.net.URLLoaderDataFormat;	import flash.net.URLRequest;	import flash.utils.ByteArray;
		/**	 * The SingleFileLoader is used to load a single file, as part of a resource.	 *	 * While SingleFileLoader can be used directly, e.g. to create a third-party asset 	 * management system, it's recommended to use any of the classes Loader3D, AssetLoader	 * and AssetLibrary instead in most cases.	 *	 * @see away3d.loading.Loader3D	 * @see away3d.loading.AssetLoader	 * @see away3d.loading.AssetLibrary	 */	public class SingleFileLoader extends EventDispatcher	{		private var _parser : ParserBase;		private var _req : URLRequest;		private var _fileExtension : String;		private var _fileName : String;				// Image parser only parser that is added by default, to save file size.		private static var _parsers : Vector.<Class> = Vector.<Class>([ ImageParser ]);						/**		 * Creates a new AssetLoader object.		 */		public function SingleFileLoader()		{		}						public function get url() : String		{			return _req? _req.url : '';		}						public static function enableParser(parser : Class) : void		{			if (_parsers.indexOf(parser) < 0)				_parsers.push(parser);		}						public static function enableParsers(parsers : Vector.<Class>) : void		{			var pc : Class;			for each (pc in parsers) {				enableParser(pc);			}		}						/**		 * Load a resource from a file.		 * @param urlRequest The URLRequest object containing the URL of the object to be loaded.		 * @param parser An optional parser object that will translate the loaded data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.		 */		public function load(urlRequest : URLRequest, parser : ParserBase = null) : void		{			var urlLoader : URLLoader;			var dataFormat : String;						_req = urlRequest;			decomposeFilename(_req.url);						if (parser) _parser = parser;						if (!_parser) _parser = getParserFromSuffix();						if (!_parser){								if(hasEventListener(LoadingEvent.LOAD_ERROR))					this.dispatchEvent(new LoadingEvent(LoadingEvent.LOAD_ERROR, _req.url, "Unsupported file type:"+_fileName));							} else {								if (_parser) {					switch (_parser.dataFormat) {						case ParserDataFormat.BINARY:							dataFormat = URLLoaderDataFormat.BINARY;							break;						case ParserDataFormat.PLAIN_TEXT:							dataFormat = URLLoaderDataFormat.TEXT;							break;					}									} else {					// Always use BINARY for unknown file formats. The thorough					// file type check will determine format after load, and if					// binary, a text load will have broken the file data.					dataFormat = URLLoaderDataFormat.BINARY;				}								urlLoader = new URLLoader();				urlLoader.dataFormat = dataFormat;				urlLoader.addEventListener(Event.COMPLETE, handleUrlLoaderComplete);				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);				urlLoader.load(urlRequest);			}		}				/**		 * Loads a resource from already loaded data.		 * @param data The data to be parsed. Depending on the parser type, this can be a ByteArray, String or XML.		 * @param uri The identifier (url or id) of the object to be loaded, mainly used for resource management.		 * @param parser An optional parser object that will translate the data into a usable resource. If not provided, AssetLoader will attempt to auto-detect the file type.		 */		public function parseData(data : *, parser : ParserBase = null) : void		{			if (data is Class)				data = new data();						// todo: guess parser from header/content using guessTypeThorough			if (parser) _parser = parser;			_parser ||= getParserFromData(data);			parse(data);		}				/**		 * A reference to the parser that will translate the loaded data into a usable resource.		 */		public function get parser() : ParserBase		{			return _parser;		}				/**		 * A list of dependencies that need to be loaded and resolved for the loaded object.		 */		public function get dependencies() : Vector.<ResourceDependency>		{			return _parser.dependencies;		}				/**		 * Splits a url string into base and extension.		 * @param url The url to be decomposed.		 */		private function decomposeFilename(url : String) : void		{			var base : String;			var i : int = url.lastIndexOf('.');						// Get rid of query string if any and extract suffix			base = (url.indexOf('?')>0)? url.split('?')[0] : url;			_fileExtension = base.substr(i + 1).toLowerCase();			_fileName = base.substr(0, i);		}				/**		 * Guesses the parser to be used based on the file extension.		 * @return An instance of the guessed parser.		 */		private function getParserFromSuffix() : ParserBase		{			var len : uint = _parsers.length;						// go in reverse order to allow application override of default parser added in Away3D proper			for (var i : int = len-1; i >= 0; i--)				if (_parsers[i].supportsType(_fileExtension)) return new _parsers[i]();						return null;		}				/**		 * Guesses the parser to be used based on the file contents.		 * @param data The data to be parsed.		 * @param uri The url or id of the object to be parsed.		 * @return An instance of the guessed parser.		 */		private function getParserFromData(data : *) : ParserBase		{			var len : uint = _parsers.length;						// go in reverse order to allow application override of default parser added in Away3D proper			for (var i : int = len-1; i >= 0; i--)				if (_parsers[i].supportsData(data))					return new _parsers[i]();						return null;		}				/**		 * Cleanups		 */		private function removeListeners(urlLoader:URLLoader) : void		{			urlLoader.removeEventListener(Event.COMPLETE, handleUrlLoaderComplete);			urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, handleUrlLoaderError);		}				/**		 * Called when loading of a file has failed		 */		private function handleUrlLoaderError(event:IOErrorEvent) : void		{			var urlLoader : URLLoader = URLLoader(event.currentTarget);			removeListeners(urlLoader);						if(hasEventListener(LoadingEvent.LOAD_ERROR))				dispatchEvent(new LoadingEvent(LoadingEvent.LOAD_ERROR, _req.url, event.text));						// if flash.net.URLLoader failed to load requested asset, then attempt to parse whatever data we got back anyway.			// do not do this for jpg or png files			/*var urlFile:String = _url.toLowerCase();			if(urlFile.indexOf("jpg") == -1 && urlFile.indexOf("png") == -1){				if (!_parser)					_parser = getParserFromData(urlLoader.data, _fileName);								parse(urlLoader.data);			}    */		}				/**		 * Called when loading of a file is complete		 */		private function handleUrlLoaderComplete(event : Event) : void		{			var urlLoader : URLLoader = URLLoader(event.currentTarget);			removeListeners(urlLoader);						// if AssetLoader hasn't already cached a parser, try to figure it out from loaded data			if (!_parser)				_parser = getParserFromData(urlLoader.data);						parse(urlLoader.data);		}				/**		 * Initiates parsing of the loaded data.		 * @param data The data to be parsed.		 */		private function parse(data : *) : void		{			if(_parser){				_parser.addEventListener(LoadingEvent.DATA_PARSED, handleParserParseComplete);				_parser.addEventListener(AssetEvent.ASSET_COMPLETE, handleParserAssetRetrieved);				switch (_parser.dataFormat) {					case ParserDataFormat.BINARY:						_parser.parseBytesAsync( ByteArray(data) );						break;					case ParserDataFormat.PLAIN_TEXT:						_parser.parseTextAsync( String(data) );						break;				}			} else{				var msg:String = "No parser defined. If embedded 3dfile, pass parser to constructor\nResourceManager.instance.parseData(new EmbeddedFile(), \"myurl/\", false, Max3DSParser);";				if(hasEventListener(LoadingEvent.LOAD_ERROR)){					this.dispatchEvent(new LoadingEvent(LoadingEvent.LOAD_ERROR, "", msg) );				} else{					throw new Error(msg);				}			}		}						private function handleParserAssetRetrieved(event : AssetEvent) : void		{			this.dispatchEvent(new AssetEvent(AssetEvent.ASSET_COMPLETE, event.asset));		}				/**		 * Called when parsing is complete.		 */		private function handleParserParseComplete(event : LoadingEvent) : void		{			_parser.removeEventListener(LoadingEvent.DATA_PARSED, handleParserParseComplete);			_parser.removeEventListener(AssetEvent.ASSET_COMPLETE, handleParserAssetRetrieved);			this.dispatchEvent(new LoadingEvent(LoadingEvent.DATA_LOADED, this.url));		}	}}