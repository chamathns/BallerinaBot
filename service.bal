import ballerina/http;
import ballerina/io;
import wso2/twitter;
import ballerina/config;
import ballerinax/docker;

endpoint twitter:Client twitter {
    clientId: config:getAsString("consumerKey"),
    clientSecret: config:getAsString("consumerSecret"),
    accessToken: config:getAsString("accessToken"),
    accessTokenSecret: config:getAsString("accessTokenSecret")
};

@docker:Expose {}

endpoint http:Listener listener {
    port:9090
};

// Docker configurations
@docker:Config {
    registry:"registry.hub.docker.com",
    name:"helloworld",
    tag:"v1.0"
}
@docker:CopyFiles {
    files:[
        {source:"./twitter.toml", target:"/home/ballerina/conf/twitter.toml", isBallerinaConf:true}
    ]
}

@http:ServiceConfig {
    basePath: "/"
}

service<http:Service> botOp bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/"
    }

    sayHello (endpoint caller, http:Request request) {

        json opreq = check request.getJsonPayload();
        string searchKeyWord = opreq.keyword.toString();
        string lastTweetID = opreq.lastTweetID.toString();

        http:Response response = new;
        var tweetResponse = twitter->search (searchKeyWord);


        match tweetResponse {
            twitter:Status[] twitterStatus =>{
                string tempTweetID = <string> twitterStatus[0].id;

                foreach i in twitterStatus{

                    int tweetId = i.id;

                    if ((<string> tweetId)== lastTweetID){
                        break;
                    }

                    string text = i.text;
                    string source = i.source;
                    string retweetCount = <string> i.retweetCount;

                    io:println("Tweet ID: " + <string> tweetId);
                    io:println("Tweet: " + text);
                    io:println("Source: " + source);
                    io:println("RT count: " + retweetCount);
                    io:println("----------------------------------------------------------------------------");

                    var tweetResponse1 = twitter->retweet(tweetId);


                }

                lastTweetID = tempTweetID;

                json payload = {latestTweetID:lastTweetID};
                response.setJsonPayload(payload);

                _ = caller->respond(response);

            }
            twitter:TwitterError e => io:println(e);
        }
    }
}