contract TemperatureOracle {
	int8 internal temperature;
	address owner;

	function TemperatureOracle(address _owner) {
		owner = _owner;
	}

	function getTemperature() external constant returns (int8) {
		return temperature;
	}

	function setTemperature(int8 newTemperature) external returns (bool success) {
		if(msg.sender != owner) { // only owner can set temperature
			return false;
		}

		temperature = newTemperature;
		return true;
	}
}



contract WeatherBet {

	struct Bet {
		address bettor;
		int8 betTemperature;
		uint amount;
	}

	uint private betEnd;
	string private location;
	TemperatureOracle private tempOracle;
	
	bool private betOver;

	Bet[] private bets;
	uint private n_bets;

	address[] private winners;
	mapping (address => bool) didWin;
	uint private n_winners;


	/// @param _betEnd day for which the bet is (in UNIX/POSIX time)
	/// @param _tempOracle address for the TemperatureOracle all parties have agreed to
	/// @notice Will create a new weather bet for `_location`, end timestamp `_betEnd` and temperature oracle `_tempOracle`
	function WeatherBet(uint _betEnd, string _location, address _tempOracle) {
		betEnd = _betEnd;
		tempOracle = TemperatureOracle(_tempOracle);
	}

	function smallestDifference() internal constant returns (int8) {
		
	}

	function endBet() external returns (bool isOver) {
		if(isBetOver()) return true;
		if(now < betEnd) return false;
		
		int8 currentTemperature = tempOracle.getTemperature();

		Bet bet;

		for(var i = 0; i < n_bets; i++) {
			bet = bets[i];
			if(bet.betTemperature >= )
		}

		betOver = true;
		return true;
	}

	function betOn(int8 temperature) external returns (bool successful) {
		if(isBetOver()) return false;
		bets.length = n_bets + 1;
		bets[n_bets] = Bet({bettor: msg.sender, betTemperature: temperature, amount: msg.value});
		n_bets++;
		return true;
	}

	function isBetOver() constant returns (bool) {
		return betOver;
	}
}