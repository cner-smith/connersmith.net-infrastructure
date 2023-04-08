// GET API REQUEST
async function get_visitors() {
    try {
        let response = await fetch('https://api.connersmith.net', {
            method: 'GET'
        });
        let data = await response.json();
        if (data.hasOwnProperty('hits')) {
            document.getElementById("visitors").innerHTML = data['hits'] + " visits.";
        } else {
            console.error('Response from API is missing "hits" attribute.');
        }
        console.log(data);
        return data;
    } catch (err) {
        console.error(err);
    }
}

get_visitors();
