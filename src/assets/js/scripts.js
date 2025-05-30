// GET API REQUEST
async function get_visitors() {
    try {
        // The fetch() method is used to make the request, passing in the method type GET as the second argument.
        // The response is then logged to the console, and the JSON data is extracted from it using response.json() and assigned to the data variable.
        let response = await fetch('https://api.connersmith.net/Prod/visitor_count', {
            method: 'GET'
        });
        // Check if the response was successful (status code 200-299)
        if (!response.ok) {
            // If not successful, log the status and throw an error to be caught by the catch block
            console.error(`API request failed with status: ${response.status}`);
            // You could try to parse the error response from the API if it provides one
            // let errorData = await response.json();
            // console.error('Error details:', errorData);
            throw new Error(`API request failed with status ${response.status}`);
        }
        let data = await response.json();

        // Access the visitorCount property from the data object
        var count = data.visitorCount; // <--- THIS IS THE MAIN CHANGE

        // If the data object has a property named hits, // (Comment is now a bit outdated, but logic is fine)
        // the value of hits is used to update the content of an HTML element with an ID of visitors.
        // Otherwise, an error message is logged to the console.
        
        // Check if count is a number (it could be undefined if 'visitorCount' was missing)
        if (typeof count === 'number') {
            document.getElementById("visitors").innerHTML = count + " visits.";
        } else {
            console.error('Response from API is missing "visitorCount" attribute or it is not a number.');
            document.getElementById("visitors").innerHTML = "Visits: N/A"; // Display a fallback
        }
        return count;
    } catch (err) {
        console.error("Error in get_visitors:", err); // More specific error logging
        // Display an error message on the page if fetching fails
        document.getElementById("visitors").innerHTML = "Could not load visits.";
    }
}

// The get_visitors() function is then called at the end of the code block.
get_visitors();