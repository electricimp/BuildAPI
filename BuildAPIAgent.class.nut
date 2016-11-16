class BuildAPIAgent {
    // A very simple integration of the Electric Imp Build API
    // to provide agent code with extra model and device information
    //
    // Written by Tony Smith
    // Copyright Electric Imp, Inc. 2016
    // Released under the MIT License

    // Constants
    static BASE_URL = "https://build.electricimp.com/v4/";
    static version = [1,0,1];

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
            server.error("BuildAPIAgent cannot be instantiated without an API key");
            return null;
        } else {
            // Build the header for all future Build API requests
            _header = { "Authorization" : "Basic " + http.base64encode(apiKey) };
        }
    }

    // *** PUBLIC FUNCTIONS ***

    function getDeviceName(deviceID = null) {
        if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
            server.error("BuildAPIAgent.getDeviceName() requires a device ID passed as a string");
            return null;
        }

        local device = _getDeviceInfo(deviceID);
        if (device) return device.name;
        return null;
    }

    function getModelName(deviceID = null) {
        if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
            server.error("BuildAPIAgent.getModelName() requires a device ID passed as a string");
            return null;
        }

        local models = _getModelsList();
        local myModel = null;
        foreach (model in models) {
            if ("devices" in model) {
                foreach (device in model.devices) {
                    if (device == deviceID) {
                        myModel = model.name;
                        break;
                    }
                }
            }

            if (myModel) break;
        }

        return myModel;
    }

    function getModelID(deviceID = null) {
        if (deviceID == null || deviceID == "" || typeof deviceID != "string") {
            server.error("BuildAPIAgent.getModelID() requires a device ID passed as a string");
            return null;
        }

        local models = _getModelsList();
        local myModel = null;
        foreach (model in models) {
            if ("devices" in model) {
                foreach (device in model.devices) {
                    if (device == deviceID) {
                        myModel = model.id;
                        break;
                    }
                }
            }

            if (myModel) break;
        }

        return myModel;
    }

    function getLatestBuildNumber(modelName = null) {
        if (modelName == null || typeof modelName != "string") {
            server.error("BuildAPIAgent.getLatestBuild() requires a model name passed as a string");
            return null;
        }

        local maxBuild = null;
        local models = _getModelsList();

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

        return maxBuild;
    }

    // ******** PRIVATE FUNCTIONS - DO NOT CALL ********

    function _getDeviceInfo(devID) {
        local data = _sendGetRequest("devices/" + devID);
        if (data) return data.device;
        return null;
    }

    function _getDevicesList() {
        local data = _sendGetRequest("devices");
        if (data) return data.devices;
        return null;
    }

    function _getModelInfo(modID) {
        local data = _sendGetRequest("models/" + modID);
        if (data) return data.model;
        return null;
    }

    function _getModelsList() {
        local data = _sendGetRequest("models");
        if (data) return data.models;
        return null;
    }

    function _getRevisions(modelID) {
        return _sendGetRequest("models/" + modelID + "/revisions");
    }

    function _sendGetRequest(url) {
        // Issues a GET request based on the passed URL using stock header
        local result = http.get(BASE_URL + url, _header).sendsync();
        if (result.statuscode == 200) {
            return http.jsondecode(result.body);
        } else {
            if (result.statuscode == 401) {
                server.error("Build API Error: " + result.statuscode + " - Unrecognised API key");
            } else {
                // TODO Handlers for common errors
                server.error("Build API Error: " + result.statuscode + " - " + result.body);
            }

            return null;
        }
    }
}
