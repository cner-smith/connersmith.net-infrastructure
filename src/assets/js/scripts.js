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
    document.cookie = cookieName + "=" + cookieValue + ";" + expires + ";path=/";
}

// GET API REQUEST
async function get_visitors() {
    try {
        // Check if the cookie "visited" exists
        if (!checkCookie("visited")) {
            // If not, make the API request to update the visitor count
            let response = await fetch('https://api.connersmith.net/Prod/visitor_count', {
                method: 'GET'
            });
            console.log(response);
            let data = await response.json();
            var name = "connersmith.net"
            var count = data[name];
            console.log(data)
            console.log(name)

            // If the data object has a property named hits,
            // the value of hits is used to update the content of an HTML element with an ID of visitors.
            // Otherwise, an error message is logged to the console.
            
            if (data) {
                document.getElementById("visitors").innerHTML = count + " visits";
            } else {
                console.error('Response from API is missing "value" attribute.');
            }
            console.log(data);
            
            // Set the "visited" cookie with a value of "true" and an expiration of 30 days
            setCookie("visited", "true", 30);
            
            return count;
        } else {
            console.log("Already visited");
            return;
        }
    } catch (err) {
        console.error(err);
    }
}

// The get_visitors() function is then called at the end of the code block.
get_visitors();
