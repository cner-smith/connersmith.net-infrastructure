// GET API REQUEST
async function get_visitors() {
    try {
        // The fetch() method is used to make the request, passing in the method type GET as the second argument.
        // The response is then logged to the console, and the JSON data is extracted from it using response.json() and assigned to the data variable.
        let response = await fetch('https://api.connersmith.net/Prod/visitor_count', {
            method: 'GET'
        });
        console.log(response)
        let data = await response.json

        // If the data object has a property named hits,
        // the value of hits is used to update the content of an HTML element with an ID of visitors.
        // Otherwise, an error message is logged to the console.
        
        if (data) {
            document.getElementById("visitors").innerHTML = data.body["connersmith.net"] + " visits.";
        } else {
            console.error('Response from API is missing "value" attribute.');
        }
        console.log(data);
        return data;
    } catch (err) {
        console.error(err);
    }
}

// The get_visitors() function is then called at the end of the code block.
get_visitors();
