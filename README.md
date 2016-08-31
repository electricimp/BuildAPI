# BuildAPIAgent

A very simple integration of the Electric Imp Build API.

This class provides basic interaction with [Electric Imp’s Build API](https://electricimp.com/docs/buildapi/) in order to provide agent code with extra information that is not available through the [imp API](https://electricimp.com/docs/api/). Since this information is typically accessed once during an application’s runtime, *BuildAPIAgent* operates synchronously, so requests for information such as the name of the model will block your application code until the data is returned.

**To add this library to your project, add** `#require "BuildAPIAgent.class.nut:1.0.2"` **to the top of your agent code**

## Class Usage

### Constructor: BuildAPIAgent(*apiKey*)

The constructor takes a single, mandatory parameter: a Build API Key associated with your account. You can generate Build API keys by logging in to the [Electric Imp IDE](https://ide.electricimp.com/login). More information on acquiring keys can be found [here](https://electricimp.com/docs/resources/ideuserguide/#2-1-2).

#### Example

```squirrel
#require "BuildAPIAgent.class.nut:1.0.2"

const APP_NAME = "Weather";
const MY_API_KEY = "<YOUR_BUILD_API_KEY>";

local build = BuildAPIAgent(MY_API_KEY);
server.log("Running app code version " + build.getLatestBuildNumber(APP_NAME));

// Logs 'Running app code version 557'
```

## Class Methods

### getDeviceName(*deviceID*)

Use this method to discover the name of a device from its ID. The ID of an agent’s associated device is the value of [imp.configparams.deviceid](https://electricimp.com/docs/api/imp/configparams/).

#### Example

```
server.log("This device is called \"" + build.getDeviceName(imp.configparams.deviceid) + "\"");

// Logs 'This device is called "Buster"'
```

### getModelName(*deviceID*)

Use this method to discover the name of the model that the agent and device are running. Pass in the device’s ID, which is the value of [imp.configparams.deviceid](https://electricimp.com/docs/api/imp/configparams/).

#### Example

```
server.log("This agent's model is called \"" + build.getModelName(imp.configparams.deviceid) + "\"");

// Logs 'This agent's model is called "WeatherMonitor"'
```

### getModelID(*deviceID*)

Use this method to discover the ID of the model that the agent and device are running. Pass in the device’s ID, which is the value of [imp.configparams.deviceid](https://electricimp.com/docs/api/imp/configparams/).

#### Example

```
server.log("This agent's model has ID: \"" + build.getModelID(imp.configparams.deviceid) + "\"");

// Logs 'This agent's model has ID: "A3vEOo1hIHpy"'
```

### getLatestBuildNumber(*modelName*)

Use this method to determine the build number of the most recent version of your application code. Pass in the model’s name acquired using *getModelName()*. **Note** this may not be the version of the code your application is actually running &mdash; if you have saved code but not restarted your device(s), for example.

#### Example

```
local modelName = build.getDeviceName(imp.configparams.deviceid);
server.log("Running app code version " + build.getLatestBuildNumber(modelName));

// Logs 'Running app code version 557'
```

## License

BuildAPIAgent is released under the [MIT License](https://github.com/electricimp/BuildAPIAgent/blob/master/LICENSE).
