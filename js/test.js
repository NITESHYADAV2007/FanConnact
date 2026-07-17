const url = 'https://free-api-live-football-data.p.rapidapi.com/football-league-all-seasons';
const options = {
	method: 'GET',
	headers: {
		'x-rapidapi-key': 'b3c7295e7fmsh4eb2fd9275cfccdp13d86ejsncc084bc4355d',
		'x-rapidapi-host': 'free-api-live-football-data.p.rapidapi.com',
		'Content-Type': 'application/json'
	}
};

try {
	const response = await fetch(url, options);
	const result = await response.text();
	console.log(result);
} catch (error) {
	console.error(error);
}