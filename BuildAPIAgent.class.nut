class BuildAPIAgent {
    // A very simple integration of the Electric Imp Build API
    // to provide agent code with extra model and device information
    //
    // Written by Tony Smith
    // Copyright Electric Imp, Inc. 2016
    // Released under the MIT License

    // Constants
    static BASE_URL = "https://build.electricimp.com/v4/";
    static version = [1,1,0];

    // Private properties
    _header = null;

    constructor(apiKey = null) {
        // Constructor requires a Build API key and must be on the agent
        if (imp.environment() != ENVIRONMENT_AGENT) {
            // Trying to run the code on a device - No!
            server.error("BuildAPIAgent cannot be instantiated on a device");
            return null;
        }

        if (apiKey == null) {
            // No API key? Report error and bail
            server.error("BuildAPIAgent cannot be instantiated without a Build API key");
            return null;
        } else {
            // Build the header for all future Build API requests
            _header = { "Authorization" : "Basic " + http.base64encode(apiKey) };
        }
    }

    // *** PUBLIC FUNCTIONS ***

    function getDeviceName(deviceID = null, callback = null) {
        // Make sure we have a valid deviceID string
        if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
            server.error("BuildAPIAgent.getDeviceName() requires a device ID passed as a string");
            return null;
        }

        if (callback) {
            _getDeviceInfo(deviceID, function(err, data) {
                if (err) {
                    callback(err, null);
                } else {
                    callback(null, data.device.name);
                }
            }.bindenv(this));
        } else {
            local device = _getDeviceInfo(deviceID, null);
            if (device) return device.name;
        }

       return null;
    }

    function getModelName(deviceID = null, callback = null) {
        // Make sure we have a valid deviceID string
        if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
            server.error("BuildAPIAgent.getModelName() requires a device ID passed as a string");
            return null;
        }

        if (callback) {
            _getModelsList(function(err, data) {
                if (err) {
                    callback (err, null);
                } else {
                    local myModel = _findModel(data.models, deviceID, "name");
                    if (myModel) {
                        callback(null, myModel);
                    } else {
                        callback(("No model name for that device ID " + deviceID), null);
                    }
                }
            }.bindenv(this));
        } else {
            return _findModel(_getModelsList(null), deviceID, "name");
        }
    }

    function getModelID(deviceID = null, callback = null) {
        // Make sure we have a valid deviceID string
        if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
            server.error("BuildAPIAgent.getModelID() requires a device ID passed as a string");
            return null;
        }

        if (callback) {
            _getModelsList(function(err, data) {
                if (err) {
                    callback (err, null);
                    return;
                }

                local myModel = _findModel(data.models, deviceID, "id");
                if (myModel) {
                    callback(null, myModel);
                } else {
                    callback(("No model ID for that device ID " + deviceID), null);
                }
            }.bindenv(this));
        } else {
            return _findModel(_getModelsList(null), deviceID, "id");
        }
    }

    function getLatestBuildNumber(modelName = null, callback = null) {
        // Make sure we have a valid modelName string
        if (modelName == null || typeof modelName != "string") {
            server.error("BuildAPIAgent.getLatestBuild() requires a model name passed as a string");
            return null;
        }

        local maxBuild = null;

        if (callback) {
            _getModelsList(function(err, data) {
                if (err) {
                    callback (err, null);
                    return;
                }

                foreach (model in data.models) {
                    if (model.name == modelName) {
                        _getRevisions(model.id, function(err, data) {
                            if (err) {
                                callback(err, null);
                                return;
                            }

                            maxBuild = data.revisions.len();
                            foreach (rev in data.revisions) {
                                local v = rev.version.tointeger();
                                if (v > maxBuild) maxBuild = v;
                            }
                            callback(null, maxBuild);
                        }.bindenv(this));
                        break;
                    }
                }
            }.bindenv(this));
        } else {
            local models = _getModelsList(null);
            local maxBuild = null;
            foreach (model in models) {
                if (model.name == modelName) {
                    local data = _getRevisions(model.id);
                    if (!data) return null;
                    maxBuild = data.revisions.len();
                    foreach (rev in data.revisions) {
                        local v = rev.version.tointeger();
                        if (v > maxBuild) maxBuild = v;
                    }

                    break;
                }
            }
        }

        return maxBuild;
    }

    // ******** PRIVATE FUNCTIONS - DO NOT CALL ********

    // In the following functions, if 'cb' (callback) is not null, the callback is triggered
    // by _sendGetRequest() (to which the callback is relayed) and the function returns null
    // (as does the calling function). If 'cb' is null, the data is retrieved synchronously

    function _getDeviceInfo(devID, cb) {
        local data = _sendGetRequest("devices/" + devID, cb);
        if (data) return data.device;
        return null;
    }

    function _getDevicesList() {
        local data = _sendGetRequest("devices");
        if (data) return data.devices;
        return null;
    }

    function _getModelInfo(modID, cb) {
        local data = _sendGetRequest("models/" + modID, cb);
        if (data) return data.model;
        return null;
    }

    function _getModelsList(cb) {
        local data = _sendGetRequest("models", cb);
        if (data) return data.models;
        return null;
    }

    function _getRevisions(modelID, cb) {
        return _sendGetRequest("models/" + modelID + "/revisions", cb);
    }

    function _sendGetRequest(url, cb) {
        // Issues a GET request based on the passed URL using account-specific header
        // If a callback is passed in (to 'cb'), it will be called to return the data,
        // else the data is retrieved synchronously and returned back up the call chain
        local query = http.get(BASE_URL + url, _header);

        if (cb) {
            query.sendasync(function(result) {
                if (result.statuscode == 200) {
                    cb(null, http.jsondecode(result.body));
                } else {
                    local err = (result.statuscode == 401) ? ("Build API Error: " + result.statuscode + " - Unrecognised API key") : ("Build API Error: " + result.statuscode + " - " + result.body);
                    cb(err, null);
                }
            }.bindenv(this));
        } else {
            local result = query.sendsync();

            if (result.statuscode == 200) {
                return http.jsondecode(result.body);
            } else {
                if (result.statuscode == 401) {
                    server.error("Build API Error: " + result.statuscode + " - Unrecognised API key");
                } else {
                    server.error("Build API Error: " + result.statuscode + " - " + result.body);
                }

                return null;
            }
        }
    }

    function _findModel(models, devID, key) {
        local myModel = null;
        foreach (model in models) {
            if ("devices" in model) {
                foreach (device in model.devices) {
                    if (device == devID) {
                        myModel = model[key];
                        break;
                    }
                }
            }

            if (myModel) break;
        }

        return myModel;
    }
}
