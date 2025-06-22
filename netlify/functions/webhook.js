const axios = require("axios");

const token = process.env.TOKEN;
const mytoken = process.env.MYTOKEN;

exports.handler = async (event, context) => {
    const { httpMethod, queryStringParameters, body } = event;

    // Handle GET request for webhook verification
    if (httpMethod === "GET") {
        const mode = queryStringParameters["hub.mode"];
        const challenge = queryStringParameters["hub.challenge"];
        const verify_token = queryStringParameters["hub.verify_token"];

        if (mode && verify_token) {
            if (mode === "subscribe" && verify_token === mytoken) {
                return {
                    statusCode: 200,
                    body: challenge
                };
            } else {
                return {
                    statusCode: 403,
                    body: "Forbidden"
                };
            }
        }
    }

    // Handle POST request for incoming messages
    if (httpMethod === "POST") {
        try {
            const body_param = JSON.parse(body);

            console.log(JSON.stringify(body_param, null, 2));

            if (body_param.object) {
                console.log("inside body param");

                if (body_param.entry &&
                    body_param.entry[0].changes &&
                    body_param.entry[0].changes[0].value.messages &&
                    body_param.entry[0].changes[0].value.messages[0]) {

                    const phon_no_id = body_param.entry[0].changes[0].value.metadata.phone_number_id;
                    const from = body_param.entry[0].changes[0].value.messages[0].from;
                    const msg_body = body_param.entry[0].changes[0].value.messages[0].text.body;

                    console.log("phone number " + phon_no_id);
                    console.log("from " + from);
                    console.log("body param " + msg_body);

                    await axios({
                        method: "POST",
                        url: `https://graph.facebook.com/v13.0/${phon_no_id}/messages?access_token=${token}`,
                        data: {
                            messaging_product: "whatsapp",
                            to: from,
                            text: {
                                body: `Hi.. I'm Prasath, your message is ${msg_body}`
                            }
                        },
                        headers: {
                            "Content-Type": "application/json"
                        }
                    });

                    return {
                        statusCode: 200,
                        body: "OK"
                    };
                } else {
                    return {
                        statusCode: 404,
                        body: "Not Found"
                    };
                }
            }
        } catch (error) {
            console.error("Error:", error);
            return {
                statusCode: 500,
                body: "Internal Server Error"
            };
        }
    }

    return {
        statusCode: 405,
        body: "Method Not Allowed"
    };
};
