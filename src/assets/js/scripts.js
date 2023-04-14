// Function to check if a cookie exists
function checkCookie(cookieName) {
    var cookies = document.cookie.split(';');
    for (var i = 0; i < cookies.length; i++) {
        var cookie = cookies[i].trim();
        if (cookie.indexOf(cookieName) === 0) {
            return true;
        }
    }
    return false;
}

// Function to set a cookie
function setCookie(cookieName, cookieValue, expirationDays) {
    var date = new Date();
    date.setTime(date.getTime() + (expirationDays * 24 * 60 * 60 * 1000));
    var expires = "expires=" + date.toUTCString();
    var sameSite = "SameSite=Strict"; // Add SameSite attribute
    document.cookie = cookieName + "=" + cookieValue + ";" + expires + ";path=/;" + sameSite; // Append SameSite attribute
}

// POST API REQUEST
async function updateVisitors(increaseHits) {
    try {
        // Make the API request to update the visitor count and pass the increase_hits boolean value
        let response = await fetch('https://api.connersmith.net/Prod/visitor_count', {
            method: 'POST',
            body: JSON.stringify({ increase_hits: increaseHits })
        });
        let data = await response.json();
        var name = "connersmith.net"
        var count = data[name];

        // If the data object has a property named hits,
        // the value of hits is used to update the content of an HTML element with an ID of visitors.
        // Otherwise, an error message is logged to the console.
        if (data) {
            document.getElementById("visitors").innerHTML = count + " visits";
        } else {
            console.error('Response from API is missing "value" attribute.');
        }

        // Set the "visited" cookie with a value of "true" and an expiration of 30 days
        setCookie("visited", "true", 30);

        return count;
    } catch (err) {
        console.error(err);
    }
}

// GET API REQUEST
async function get_visitors() {
    try {
        // Check if the cookie "visited" exists
        if (!checkCookie("visited")) {
            // If not, make the API request to update the visitor count and pass increase_hits as true
            return await updateVisitors(true);
        } else {
            console.log("Already visited");
            // If visited, make the API request without increasing hits count, pass increase_hits as false
            return await updateVisitors(false);
        }
    } catch (err) {
        console.error(err);
    }
}

// The get_visitors() function is then called at the end of the code block.
get_visitors();

