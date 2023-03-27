// GET API REQUEST
async function get_visitors() {
    // call post api request function
    //await post_visitor();
    try {
        let response = await fetch('https://api.connersmith.net/', {
            method: 'GET'
        });
        let data = await response.json()
        document.getElementById("visitors").innerHTML = data['hits'] + " visits.";
        console.log(data);
        return data;
    } catch (err) {
        console.error(err);
    }
}


get_visitors();