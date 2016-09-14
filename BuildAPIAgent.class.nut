//#require "Promise.class.nut:3.0.0"

class BuildAPIAgent {
    // A very simple integration of the Electric Imp Build API
    // to provide agent code with extra model and device information
    //
    // Written by Tony Smith
    // Copyright Electric Imp, Inc. 2016
    // Released under the MIT License
    //
    // Written by Austin Eldridge
    // Released under the MIT License

    // 'Constants'
    static BASE_URL = "https://build.electricimp.com/v4/";
    static version = [2,0,0];

    // Private properties
    _header = null;

    // Constructor requires a Build API key
    constructor(apiKey = null) {
        if (imp.environment() != ENVIRONMENT_AGENT) {
           // Trying to run the code on a device - No!
           server.error("BuildAPIAgent cannot be instantiated on a device");
           return null;
       }

       if (apiKey == null) {
           // No API key? Report error and bail
           server.error("BuildAPIAgent cannot be instantiated without an API key");
           return null;
        } else {
            // Build the header for all future Build API requests
            _header = { "Authorization" : "Basic " + http.base64encode(apiKey) };
        }
    }

    // *** PUBLIC FUNCTIONS ***

    function getDeviceName(deviceID = imp.configparams.deviceid) {
       if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
           local error = "BuildAPIAgent.getDeviceName() requires a device ID passed as a string"
           //server.error(error);
           return Promise.reject(error);
       }

       return _getDeviceInfo(deviceID)
                    .then(function(device){
                        return device.name
                    }.bindenv(this))
   }

   function getModelName(deviceID = imp.configparams.deviceid) {
       if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
           local error = "BuildAPIAgent.getModelName() requires a device ID passed as a string"
           //server.error(error);
           return Promise.reject(error);
       }

       return _getModelsList()
                    .then(function(data){
                        foreach (model in data.models) {
                            if ("devices" in model) {
                                foreach (device in model.devices) {
                                    if (device == deviceID) {
                                        return model.name
                                    }
                                }
                            }
                        }
                        throw "deviceID " + deviceID + " not found in any models for the provided Build API Key"
                    }.bindenv(this))

   }

   function getModelID(deviceID = imp.configparams.deviceid) {
       if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
           local error = "BuildAPIAgent.getModelID() requires a device ID passed as a string"
           //server.error(error);
           return Promise.reject(error);
       }

       return _getModelsList()
                    .then(function(data){
                        foreach (model in data.models) {
                            if ("devices" in model) {
                                foreach (device in model.devices) {
                                    if (device == deviceID) {
                                        return model.id
                                    }
                                }
                            }
                        }
                        throw "deviceID " + deviceID + " not found in any models for the provided Build API Key"
                    }.bindenv(this))

   }

    // Gets and returns the latest build number for a given model
    function getLatestBuildNumber(modelName = null) {
        if (modelName == null || (typeof modelName != "string")) {
            local error = "BuildAPI.getLatestBuildNumber() requires a model name passed as a string"
            //server.error(error);
            return Promise.reject(error);
        }

        return _getModelsList()
                    .then(function(data){
                        foreach (model in data.models) {
                            if (model.name == modelName) {
                                return _getRevisionList(model.id);
                            }
                        }
                    }.bindenv(this))
                    .then(function(result){
                        local maxBuild = -1;
                        foreach (rev in result.revisions) {
                            local v = rev.version.tointeger();
                            if (v > maxBuild) maxBuild = v;
                        }
                        return maxBuild
                    }.bindenv(this))
                    .fail(function(error){
                        //server.error("BuildAPI.getLatestBuildNumber failed - " + http.jsonenecode(error))
                        throw error
                    }.bindenv(this))
    }

    // **** PRIVATE FUNCTIONS - DO NOT CALL ****

    function _getDeviceInfo(deviceID) {
        return _sendGetRequest("devices/" + deviceID)
    }

    function _getDevicesList() {
        return _sendGetRequest("devices");
    }

    function _getModelsList() {
        return _sendGetRequest("models");
    }

    function _getModelInfo(modelID) {
        return _sendGetRequest("models/" + modelID);
    }

    function _getModelsList() {
        return _sendGetRequest("models");
    }

    function _getRevisionList(modelID) {
        return _sendGetRequest("models/" + modelID + "/revisions");
    }

    function _sendGetRequest(url) {
        return Promise(function(fulfill, reject){
            // Issues a GET request based on the passed URL using stock header
            http.get(BASE_URL + url, _header).sendasync(function(result){
                if (result.statuscode == 200) {
                    fulfill(http.jsondecode(result.body));
                } else {
                    local error
                    if (result.statuscode == 401) {
                        error = "Build API Error: " + result.statuscode + " - Unrecognised API key"
                    } else {
                        //TODO: Handlers for common errors
                        error = "Build API Error: " + http.jsonencode(result)
                    }
                    //server.error(error);
                    reject(error);
                }
            }.bindenv(this));
        }.bindenv(this))
    }
}


/*
g_Build <- BuildAPIAgent("<BUILD API KEY>");
g_Build.getModelName()
       //.then(g_Build.getLatestBuildNumber.bindenv(g_Build))    //Can use this version if you don't want the model name logged
       .then(function(modelName){
           server.log("Model: " + modelName)
           return g_Build.getLatestBuildNumber(modelName)
       })
       .then(function(buildVersion){
               server.log("Build: " + buildVersion);
       })
       .fail(function(error){
           server.error("UNABLE TO GET BUILDVERSION VIA BUILDAPI")
           server.error(error)
       })
*/
