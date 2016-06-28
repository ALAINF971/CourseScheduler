



        <script>
            var qs = {};
            qs.// This function extracts key value data from the selected querystring obj
// Input parameters:
// obj_to_add = the desired object to add the querystring object into
// initial_QS the querystring value

setQueryString = function(obj_to_add,initial_QS){
    obj_to_add.qsObj={};
    initial_QS.replace(
        new RegExp("([^?=&]+)(=([^&]*))?", "g"),
        function($0, $1, $2, $3)
        {
            if ($1 === 'ctid')
            {
	            $1 = 'CTID';
            }

	        obj_to_add.qsObj[$1] = decodeURIComponent($3);
        }
    );
}

            qs.setQueryString(qs, window.location.href);
            window.userStorage = function() {
    var debug = false;
    var defaultAppPath = '';
    var lastUpdatedKey = 'SF_UPDATED_TS';
    var flashBugFix = '_1_flashBugFix'; //used to skip this key when syncing from flash engine
    var lastUpdatedExpMilliSec = 999*24*60*60*1000;
    var callerOnReady = function(){};
    var callerOnError = function(){};
    var engineStates = {ready: 'ready', initiating: 'initiating', error: 'error'};
    var engines = {};
    var failSafeTimer;
    var wasStarted = false;

	var getSize = function(obj) { //using getSize() to get engines array size, since it's actually an array-like object
        var size = 0, key;
            for (key in obj) {
                if (key != 'size' && obj.hasOwnProperty(key)) 
                    size++;
            }
        return size;
    };
    
    //This function returns the was started value which indicates if the utility got a request to start working.
    function getWasStarted(){
        return wasStarted;
    }

    /*
    each engine must register itself with registerEngine().
    init() will iterate thru registered engines and call their init() functions, passing ready and error handlers.
    the ready/error handlers set the engine state, and call _checkStates().
    _checkStates() checks if all engines are initiated, and if so - calls syncEngines, then calls the external onReady callback.

     */       
    function init(config) {
        //wasStarted = true;
        
        if(typeof config == 'undefined') config = {};
        debug = config.debug || debug;
	    // debug = true;	

        if(typeof config.onReady == 'function') 
            callerOnReady = config.onReady;
            
        if(typeof config.onError == 'function') 
            callerOnError = config.onError;

        for(var name in engines) {
            initEngine(name, config); //keep this as a separate function call to keep "name" value in closure. If we don't then when callbacks fire "name" will = value at last iteration.
        }
        failSafeTimer = setTimeout(_allEnginesInitiated, 2000);
    }
	
    //init engine and bind callbacks
    function initEngine(name, config) {
        try {
            engines[name].engine.init({
                debug: debug,
                appPath: config.appPath,
                onReady: function() {_onEngineReady(name)},
                onError: function() {_onEngineError(name)}
            });
        }
        catch(ex){
            log('error initializing engine: '+name+". "+ex.message);
            userStorageUtil.reportError('initEngine', 'error initializing engine '+name+'. '+ex.message);
        }
    }

    function registerEngine(engine) {
        log('registering '+engine.name);
        engines[engine.name] = {'state': engineStates.initiating, 'engine': engine};
    }

    function _onEngineReady(name) {
        log('_onEngineReady: '+name);
        engines[name].state = engineStates.ready;        
        _checkStates();
    }

    function _onEngineError(name) { 
        log('_onEngineError: '+name);
        engines[name].state = engineStates.error;     
        _checkStates();
    }

    //check if all engines are initiated (having either 'ready' or 'error' state) 
    function _checkStates(){ 
        var enginesStates = 0;
        var logMsg= '_checkStates: ';
        for(var name in engines) {
            //logMsg += name +' = '+engines[name].state + '. ';
            if(engines[name].state != engineStates.initiating) {
                enginesStates++;
            }
        }
        //log(logMsg);

        if(enginesStates == getSize(engines))
            _allEnginesInitiated();
    }

    //if 2 or more engines are ready - synchronize, then Trigger callerOnReady.
    function _allEnginesInitiated(){
        var lastUpdated = 0, doSync = false; //used to check if sync is needed
        clearTimeout(failSafeTimer);
        failSafeTimer = null;

        var readyEngines = []; 
        for(var name in engines) {
            if(engines[name].state == engineStates.ready) {
                readyEngines.push(engines[name].engine);
                /*if(!doSync) {
                    if(readyEngines.length > 1 && lastUpdated > 0 && lastUpdated != +engines[name].engine.get(lastUpdatedKey)) 
                        doSync = true;
                    else
                        lastUpdated = +engines[name].engine.get(lastUpdatedKey);
                } */
            }
        }

        // if (doSync)
//        if (readyEngines.length > 1)
//        {
//	        //syncEngines(readyEngines);
//        }

        if (readyEngines.length > 0){
            wasStarted = true;
            callerOnReady();
        }else
            callerOnError();
    }
    
    //synchronize data across engines
    function syncEngines(engines)
    {
            var source = false, target = false, lastUpdated = 0, iLastUpdated = 0;
            for(var i=0;i< engines.length;i++)
            {
                iLastUpdated = engines[i].get(lastUpdatedKey);
                if(iLastUpdated == null) { // cookie does not exists
                    iLastUpdated = 0;
                }
                log('syngEngines: engine = '+engines[i].name+', iLastUpdated = '+iLastUpdated+', lastUpdated='+lastUpdated);
                if(iLastUpdated > lastUpdated) {
                    source = engines[i];
                    lastUpdated = iLastUpdated;
                }
            }
            log('syncEngines: source = '+source.name+', lastUpdated = '+lastUpdated);
            if(!source) {
                log('syncEngines - no source engine - skipping sync.');
                return;
            }

            log('syncEngines: begin sync. Source engine = '+source.name);

            var data = null;			
			try{	
				data = source.getAll();
			}
			catch(ex){
            	log('error getting source engine data: ' + source.name + ". " + ex.message);
            	userStorageUtil.reportError('syncEngines', 'error getting source engine data: ' + source.name + ". " + ex.message);
				data = null;
        	}

			if (data == null)
				return;

            var expMilliSec, value, trimmedKey;
            
            for(var i=0; i< engines.length; i++)
            {
                target = engines[i];

                if(target.name == source.name)
                {
                    continue;
                }

				try
				{
	                target.clearAll();

                    var Errors = '', counter=0;

					for (var name in data)
					{
						if (data.hasOwnProperty(name))
						{
							try
							{
								trimmedKey = userStorageUtil.trim(name); //For some reason flash adds a space to the key so trim before comparing
								if(trimmedKey == lastUpdatedKey || trimmedKey == flashBugFix)
								{
									continue;
								}

								expMilliSec = userStorageUtil.extractExpiration(data[name]) || -1;
								value = userStorageUtil.extractValue(name, data[name]);

								target.set(name, value, expMilliSec, true); //4th param true for using existing expiration timestamp (from value);
							}
							catch(err)
							{
								Errors += counter+1 + ". Unable to sync cookies - " + err.message + " **** "  ;
							}

							counter++;
						}
					}

                    if(Errors != '')
                    {
	                    userStorageUtil.reportError('syncEngines', Errors );
                    }
                
                	setLastUpdated(target, lastUpdated);
				}
				catch(ex)
				{
					log('error syncing target: ' + target.name + ". " + ex.message);
                	userStorageUtil.reportError('syncEngines', 'error syncing target: ' + target.name + ". " + ex.message);
				}
            }
            log('syncEngines: done.');
    }

    //returns a specific engine (if ready), or the first engine that is ready.
    function getReadyEngine(engineName) {
        if(typeof engineName == 'string' && engineName.length > 0) {
            if(engines[engineName].state == engineStates.ready) {
                log('Return Cookie from - ' + engineName);
                return engines[engineName].engine;
            }
        }
        else {
            for(var name in engines) {
                if(engines[name].state == engineStates.ready) {
                    log('Return Cookie from - ' + name);
                    return engines[name].engine;
                }
            }
        }
    }

    function setLastUpdated(engine, timestamp) {
        timestamp = timestamp ? timestamp : new Date().getTime();
        try {
            log('setLastUpdate: '+engine.name+', ts='+timestamp);
            engine.set(lastUpdatedKey, timestamp, lastUpdatedExpMilliSec);
        }
        catch(ex) {
            log('setLastUpdated error: engine = ' + engine.name ? engine.name : 'n/a. ' + ex.message);
            userStorageUtil.reportError('setLastUpdated','engine: '+engine.name+'. '+ex.message);
        }
    }

    //replace spaces with underscores because escaped spaces breaks our flash engine data (JSON format).
    function validateKey(key) {
        if (key) {
            return key.replace(/ /g,"_");
        }
        return "";
    }

    function get(key, engineName) {
        if (!wasStarted)
            return null;

        var value = null;
        key = validateKey(key);
        try {
            value = getReadyEngine(engineName).get(key);
            if (value != null)
                value = unescape(value);
        }
        catch(ex) {
            log('error getting key ' + key + ' from engine: ' + engineName);
            userStorageUtil.reportError('get', 'engine: ' + engineName + '. ' + ex.message);
			value = null;
        }

        return value;
    }

    function refresh() {
        if (!wasStarted)
          return;

        for(var name in engines) {
            try {
                if(engines[name].state == engineStates.ready) {
                    engines[name].engine.refresh();
                    log('Refreshing data engine('+name+')');
                    var updateTimestamp = new Date().getTime(); //make sure all 'ready' engines have exactly same update timestamp
                    setLastUpdated(engines[name].engine, updateTimestamp);
                }
            }
            catch(ex) {
                log('error on refresh ');
                userStorageUtil.reportError('refresh', 'engine: '+name+'. '+ex.message);
            }
        }
    }

    function getAll(engineName) {
        if (!wasStarted)
            return null;
		var returnValue = null;
        try{
            returnValue = getReadyEngine(engineName).getAll();
        }
        catch(ex) {
            log('error getAll from engine: '+engineName);
            userStorageUtil.reportError('getAll', 'engine: '+engineName+'. '+ex.message);   
			returnValue = null;
        }
		
		return returnValue;
    }

    function set(key, value, expMilliSec) {
        if (!wasStarted)
          return false;

	    value = escape(value);
        key = validateKey(key);
        var updateTimestamp = new Date().getTime(); //make sure all 'ready' engines have exactly same update timestamp
        var success = false; // boolean
		
        for(var name in engines) {
            try {
                if(engines[name].state == engineStates.ready) {
                    engines[name].engine.set(key, value, expMilliSec);
                    log('setting engine('+name+')'+key+'='+value);
                    setLastUpdated(engines[name].engine, updateTimestamp);
                    success = true;
                }
            }
            catch(ex) {
                log('error setting key '+key);
                userStorageUtil.reportError('set', 'engine: '+name+'. '+ex.message);
            }
        }

        return success;
    }

    function clear(key) {
        if (!wasStarted)
          return;

        key = validateKey(key);
        for(var name in engines) {
            try {
                if(engines[name].state == engineStates.ready) {
                    engines[name].engine.clear(key);
                    log('clearing engine('+name+') '+key);

                    setLastUpdated(engines[name].engine);
                }
            }
            catch(ex) {
                log('error clearing key '+key+' engine = '+name);
                userStorageUtil.reportError('clear', 'engine: '+name+'. '+ex.message);   
            }
        }
    }

    function log(msg) {
        if(debug && window.console && (typeof window.console.log == 'function' || typeof window.console['info'] == 'function')) {
           var dDate = new Date();
           if(typeof(console['info']) !== "undefined"){
                window.console['info']('userStorage : ' + dDate.getTime() + " - " + msg);
            } else {
                window.console.log('userStorage : ' + dDate.getTime() + " - "  + msg);
            }
        }
    }

    function isReady(){
        if (!wasStarted)
            return false;

        var enginesStates = 0;
        var engineReady = false;

        for(var name in engines) {
            if(engines[name].state != engineStates.initiating) {
                enginesStates++;
            }

            if (engines[name].state == engineStates.ready)
                engineReady = true;
        }

        if(enginesStates == getSize(engines) && engineReady)
            return true;
        else
            return false;

    }

    userStorageUtil = function () {
    var expirationDelimiter = '_SF_EXP_TS_';
    var delimiterLength = expirationDelimiter.length;
    var sessionCookieExpValue = -1;

    function reportError(source, message){
        if(Math.floor(Math.random() * 10) == 1) {
			if (typeof message == 'string' && message.length > 1000){
				message = message.substring(0,1000);
			}

			message = source ? source : '' +' - '+message;
            try{
                var url = similarproducts.b.site + "trackSession.action?userid=user_storage&sessionid=user_storage&CD_CTID=null&action=usr_storage_err&err_message=" + message  + "&rnd=" + Math.random();
                var img = new Image();
                img.src = url;
            }
            catch(e){
                console.log(" *** exception in func_storage_util.js in reportOnError ");
            }
        }
    }

    function _extractExpiration(value) {
        if(typeof value == 'string' && value.length > 0 && value.indexOf(expirationDelimiter) > 0) {
            var expiration = +value.substr(value.indexOf(expirationDelimiter)+delimiterLength);
            return expiration;
        }
        return undefined;
    }

    function _extractValue(name, value) {
        if(userStorageUtil.isExpired(name, value))
            return null;
        
        if(typeof value == 'string' && value.length > 0) {
            if(value.indexOf(expirationDelimiter) > 0) {
                var extractedValue = value.substr(0, value.indexOf(expirationDelimiter));
                return extractedValue;
            }
            else{
                return value;
            }
        }
        return null;
    }

    function _addExpiration(value, expMilliSec, useCallerExp) {
        value = value.toString() + expirationDelimiter;

        if(expMilliSec == undefined || isNaN(expMilliSec) || expMilliSec < 1)
            return value + sessionCookieExpValue.toString();

        if(useCallerExp) {
            value += expMilliSec;
        } 
        else {
            value += (new Date().getTime() + parseInt(expMilliSec, 10));
        }

        return value;
    }

    function _isExpired(name, value) {
        var expMilliSec = _extractExpiration(value);
        var nowMilliSec = new Date().getTime();
        if(expMilliSec != sessionCookieExpValue && expMilliSec < nowMilliSec) {
            return true;
        }
        else 
            return false;
    }

    function trim(str) {
        return str.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    }

    return {
        extractExpiration: _extractExpiration,
        extractValue: _extractValue,
        addExpiration: _addExpiration,
        isExpired: _isExpired,
        trim: trim,
        getExpiredSessionKey: function(){return sessionCookieExpValue;},
        getExpirationDelimiter: function(){return expirationDelimiter;},
        reportError: reportError
    };
}();

    
    /* storage engines: */
	var localStorageEngine = (function()
{
	function init(config)
	{
		if (!config)
		{
			return; // What if we don't want to config? What ever, keep it uniform with the other engines
		}

		if(!window.localStorage)
		{
			if(typeof config.onError == 'function')
			{
				config.onError();
			}
		}
		else
		{
			if (localStorage.getItem("clearedBeforeWork") == null){
				localStorage.clear();
				localStorage.setItem("clearedBeforeWork","1");
			}

			if(typeof config.onReady == 'function')
			{
				config.onReady();
			}
		}
	}

	function get(key)
	{
		var expirationTimestamp = parseInt(localStorage.getItem('__expiration:'+key)) || 0; // Because 'null' actually evaluates to NaN
		var timestamp = new Date().getTime();
		var value = localStorage.getItem(key);
		var result = null;

		if (value)
		{
			if (timestamp < expirationTimestamp) //
			{
				result = unescape(value);
			}
			else // We do not want to keep spoiled goods indefinitely, so we delete our item and it's helper
			{
				localStorage.removeItem(key);
				localStorage.removeItem('__expiration:'+key);
			}
		}

		return result;
	}

	function getAll()
	{
		var timestamp = new Date().getTime();
		var result = {};
		var expiration;

		for (var key in localStorage)
		{
			if (key.indexOf('__expiration:') !== 0) // We do not want the "expiration time" helpers returned with our data
			{
				expiration = localStorage.getItem('__expiration:'+key);

				if (expiration && timestamp < parseInt(expiration))
				{
					result[key] = unescape(localStorage.getItem(key))+'_SF_EXP_TS_'+expiration;
				}
			}
		}

		return result;
	}

	function set(key, value, expireInXMiliseconds, useCallerExp)
	{
		// Because we want to be able to give expiration time to our values (like with cookies), we actually create two items:
		// 1. The value itself
		// 2. The expiration timestamp, that we will access later via __expiration:KEY_NAME

		var expirationTimestamp;

		if(useCallerExp)
		{
			expirationTimestamp = expireInXMiliseconds;
		}
		else
		{
			expirationTimestamp = new Date().getTime() + expireInXMiliseconds;
		}

		localStorage.setItem(key, value);
		localStorage.setItem('__expiration:'+key, expirationTimestamp);
	}

	function clear(key)
	{
		localStorage.removeItem(key);
	}

	function clearAll()
	{
		localStorage.clear()
	}

	function refresh()
	{
	}

	return {
		init: init,
		get: get,
		getAll: getAll,
		set: set,
		clear:clear,
		clearAll: clearAll,
		refresh: refresh,
		name: 'local'
	};
})();

registerEngine(localStorageEngine);
    return {
        get: get,
        getAll: getAll,
        set: set,
        clear: clear,
        refresh: refresh,
        init: init,
        wasStarted: getWasStarted,
        isReady: isReady
    };
}();

            window.xdmsg = {
    cbFunction: 0,

    postMsg : function( target, param ){
        if( target != window ){
            target.postMessage( param, "*" );
        }
    },

    getMsg : function(event){
        ( window.xdmsg ? xdmsg : similarproducts.b.xdmsg).cbFunction( event.data, event.origin );
    },

    init: function( cbFunc ){
        this.cbFunction = cbFunc;
        if( window.addEventListener ){
            window.addEventListener("message", this.getMsg, false );
        }else{
            window.attachEvent('onmessage', this.getMsg );
        }
    },

    kill: function (){
        if( window.removeEventListener ){
            window.removeEventListener("message", this.getMsg, false );
        }else{
            if (window.detachEvent) {
                window.detachEvent ('onmessage', this.getMsg );
            }
        }
    }
}
;
            var userIdUtil = function () {
    var _userIdKey = 'WSUserId';
    var _userIdUpdatingKey = 'WSUserIdUpdating';
    var _noUserIdKey = "NO-USER-ID";
    var _userId = _noUserIdKey;

    var _NTBCIdentity = 'NTBC'; //'NTBC';
    var _debug = false;


    function _s4() {
        return Math.floor((1 + Math.random()) * 0x10000)
            .toString(16)
            .substring(1);
    }


    function _hasUserId() {
        _userId = userStorage.get(_userIdKey);
        return (_userId != null);
    }


    function _isUpdating() {
        var userIdUpdating = userStorage.get(_userIdUpdatingKey) + "";
        return (userIdUpdating == "true")
    }


    function _saveUserId(userId) {
        userStorage.set(_userIdUpdatingKey, "true",  999 * 24 * 60 * 60 * 1000);
        userStorage.set(_userIdKey, userId, 999 * 24 * 60 * 60 * 1000);
        userStorage.set(_userIdUpdatingKey, "false", 999 * 24 * 60 * 60 * 1000);
    }


    function _generateUserId(){
        var newUserId = _s4() + _s4() + '-' + _s4() + '-' + _s4() + '-' + _s4() + '-' + _s4() + _s4() + _s4() + '-' + _s4().substr(0,3);
        return newUserId;
    }


   function get() {
        _log("Getting UserId");

        if(!userStorage.isReady()) {
            _log("userStorage isn't ready");
            _reportOnError("userStorage isn't ready");
            _userId = _noUserIdKey;
            return _userId;
        }


        if(_isUpdating()) {
            _log("Is Updating");
            _reportOnError("While waiting for updating the UserId it's still not Exists");
            _userId = _noUserIdKey;
            return _userId;
        }


        if(!_hasUserId()) {
            _log("generating user id");
            _userId = _generateUserId();
            _saveUserId(_userId);
            return _userId;
        }

        _log("userId exits - " + _userId);
        return _userId;
    }


    function needToChange(uid) {
        _log("Checking UserId - " + uid);

        return (_startsWith(uid,_NTBCIdentity) && _endsWith(uid,_NTBCIdentity));
    }


    function _reportOnError(errorMessage) {
        var dDate = new Date();
        var msg = errorMessage + "&URL=" + document.URL.replace( "?", "&") + "&userAgent=" + navigator.userAgent  + "&platform=" + navigator.platform  + "&referrer=" + encodeURIComponent(document.referrer);
        try{
            var url = similarproducts.b.site + "trackSession.action?userid=userIdUtil&sessionid=userIdUtil&action=userIdUtil_Error&err_message=" + msg;
            var img = new Image();
            img.src = url;
            document.getElementsByTagName("body")[0].appendChild(img);
        }
        catch(e){
            _log(" *** exception in func_userid_util.js in _reportOnError ");
        }
    }

    function _endsWith(str, suffix) {
        return str.indexOf(suffix, str.length - suffix.length) !== -1;
    }


    function _startsWith(str, prefix) {
        return str.indexOf(prefix) === 0;
    }


    function _log(msg) {
        if (_debug && window.console) {
            var dDate = new Date();
            console.log(dDate.getTime() + " - " + msg);
        }
    }


    return {
        get: get,
        needToChange: needToChange
    }


}();
            var abTestUtil = (function() {
    var names = [
        "tier1_bucket",
        "tier1_curr_group",
        "tier1_next_group",
        "tier1_prev_group",
        "tier2_bucket",
        "tier2_curr_group",
        "tier2_next_group",
        "tier2_prev_group"
    ];
    var dataObj = {};
    var dataString = "";

    function init() {
        if (dataObj === {}) {
            for (var i = 0; i < names.length; i++) {
                dataObj[names[i]] = "";
            }
        }
    }
    
    function setValues(obj) {
        if (obj) {
            if (obj.tier1) {
                dataObj.tier1_bucket = obj.tier1.bucket || "";
                dataObj.tier1_curr_group = obj.tier1.group;
                dataObj.tier1_next_group = obj.tier1.nextGroup;
                dataObj.tier1_prev_group = obj.tier1.previousGroup;
            }
            if (obj.tier2) {
                dataObj.tier2_bucket = obj.tier2.bucket || "";
                dataObj.tier2_curr_group = obj.tier2.group;
                dataObj.tier2_next_group = obj.tier2.nextGroup;
                dataObj.tier2_prev_group = obj.tier2.previousGroup;
            }            
        }
        dataString = '';
        for (var i = 0; i < names.length; i++) {
            if (dataObj[names[i]] == null || typeof(dataObj[names[i]]) === "undefined") {
                dataObj[names[i]] = "";
            }
            dataString += ("&" + names[i] + "=" + dataObj[names[i]]);
        }
    }
    
    function setValuesFromQS(qsObj) {
        if (qsObj) {
            dataString = '';
            for (var i = 0; i < names.length; i++) {
                if (qsObj[names[i]] == null || typeof(qsObj[names[i]]) === "undefined") {
                    dataObj[names[i]] = "";
                }
                else {
                    dataObj[names[i]] = qsObj[names[i]];
                }
                dataString += ("&" + names[i] + "=" + dataObj[names[i]]);
            }
        }
    }
    
    
//    function overrideBucket() {
//        dataObj.tier1_bucket = ((similarproducts.b.qsObj && similarproducts.b.qsObj.bucket ) || (window.qsObj && window.qsObj.bucket )) || dataObj.tier1.bucket;
//        dataObj.tier2_bucket = ((similarproducts.b.qsObj && similarproducts.b.qsObj.bucket ) || (window.qsObj && window.qsObj.bucket )) || dataObj.tier2.bucket;
//    }
    
    function getBucket() {
        return dataObj.tier1_bucket || dataObj.tier2_bucket;
    }
    
    function addDataToObject(obj) {
        if (!obj) {
            obj = {};
        }
        for (var i = 0; i < names.length; i++) {
            obj[names[i]] = dataObj[names[i]];
        }
        return obj;
    }

    function getDataString() {
        return dataString;
    }
    
    init();
    
    return {
        setValues: setValues,
        setValuesFromQS: setValuesFromQS,        
        getBucket: getBucket,
        addDataToObject: addDataToObject,
        getDataString:getDataString
    };
    
})();                
            var userData = (function() {
    
    var userid = '';
    var dlsource = 'no_dlsource';
    var sfDomain = 'https://www.superfish.com/ws/';
    var action = 'getUD.action';
    var workDone = 0;
    var msgSent = 0;
    var xdMsgDelimiter = '*sfxd*';
    var timer = 0;
    
    function init() {
        timer = setTimeout(function() {            
            alternativeWork(-3);
             if(Math.floor(Math.random() * 1000) == 1) {
                var url = sfDomain + "trackSession.action?userid=" + userid + "&sessionid=-10&action=ud_iframe_failed";
                var img = new Image();
                img.src = url;     
             }            
        }, 1500);
        if (typeof(qs.qsObj) != 'undefined'){
            if(typeof (qs.qsObj.userid) != 'undefined'){
                userid = qs.qsObj.userid;
            }
            if (qs.qsObj.dlsource) {
                dlsource = qs.qsObj.dlsource;
            }
        }
        
        sfDomain = window.location.protocol == "http:" ? sfDomain.replace('https:', 'http:') : sfDomain;
        if(window.xdmsg){
            xdmsg.init(gotMessage);
        }
        
        if (!userStorage.wasStarted()){
            userStorage.init({
                appPath: sfDomain,
                onReady: work,
                onError: function() {
                    if (!workDone) {
                        workDone = 1;
                        alternativeWork(-2);
                    }
                }
            });
        }
        
        if(window.xdmsg){
            xdmsg.init(gotMessage);
        }

    }
    
    function work() {
        if (!workDone) {
            workDone = 1;
            initUserId();
            loadUserData();
        }

    }
    
    function alternativeWork(group) {
        var data = {
            "uc":"US",
            "ut":{
                "tier1":{
                    "bucket": null,
                    "group": group,
                    "nextGroup": group,
                    "previousGroup": group
                },
                "tier2":{
                    "bucket": null,
                    "group": group,
                    "nextGroup": group,
                    "previousGroup": group
                },
            "userId": userid
            }
        };
        var dataString = JSON.stringify(data);
        sendUserData(dataString);
    }
    
    function initUserId() {
        if (!userid || userIdUtil.needToChange(userid)) {
            userid = userIdUtil.get();
        }
     }
    
    
    function gotMessage() {}
    
    function sendMessage(msg) {
        if(window.xdmsg){
           window.xdmsg.postMsg(top, msg);
        }
    }
    
    function sendRequest(url, callback) {
        var xhr;
        if (window.navigator.userAgent.toLowerCase().indexOf("msie") != -1){
            xhr = new ActiveXObject("Microsoft.XMLHTTP");
        }
        else{
            xhr = new XMLHttpRequest();
        }

        xhr.onreadystatechange = ensureReadiness;  
          
        function ensureReadiness() {  
            if(xhr.readyState < 4) {  
                return;  
            }  
              
            if(xhr.status !== 200) {  
                return;  
            }  
  
            // all is well    
            if(xhr.readyState === 4) { 
                callback(xhr.responseText);  
            }             
        }  
          
        xhr.open('GET', url, true);  
        xhr.send('');  
    }  
    
    function loadUserData() {
        var url = sfDomain + action + '?dlsource=' + dlsource + '&userId=' + userid + '&ver=' + qs.qsObj.ver; 
        sendRequest(url, sendUserData);
    }
    
    function sendUserData (data){           // data as string 
        clearTimeout(timer);
        if (!msgSent) {
            msgSent = 1;
            sendMessage("-3344" + xdMsgDelimiter + data);
        }
    }

        
    return {
        init: init
    };

    
})();    
            window.onload = function() {                         
                userData.init();  
            }
        </script>