import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/task;
import ballerina/math;
import ballerina/runtime;

endpoint http:Client clientEndpoint {
    url: "http://localhost:9090"
};

task:Timer? timer;
string textTweetID ="0";

function main(string... args) {

    (function() returns error?) onTriggerFunction = op;

    function(error) onErrorFunction = opError;

    timer = new task:Timer(onTriggerFunction, onErrorFunction,
        30000, delay = 500);

    timer.start();

    runtime:sleep(86400000);

}


function op() returns error ? {
    io:println("jsonMsg tweetID : " + textTweetID);
    http:Request req = new;

    json jsonMsg = { lastTweetID: textTweetID, keyword: "#wso2con" };
    req.setJsonPayload(jsonMsg);

    var response = clientEndpoint->post("/",req);
    match response {
        http:Response resp => {
            var msg = resp.getJsonPayload();
            match msg {
                json jsonPayload => {
                    string outTweetID= jsonPayload["latestTweetID"].toString();

                    io:println("latest tweet ID : " + outTweetID);
                    textTweetID = outTweetID;

                }
                error err => {
                    log:printError(err.message, err = err);
                }
            }
        }
        error err => { log:printError(err.message, err = err); }
    }
    return ();

}

function opError(error e) {
    io:print("[ERROR] process failed");
    io:println(e);
}
