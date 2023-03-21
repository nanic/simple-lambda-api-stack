'use strict';
module.exports.helloWorld = (event, context, callback) => {

    let requestBody = JSON.parse(event.body);
    console.log(requestBody);

}