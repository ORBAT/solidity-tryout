contract TemperatureOracle {
	mapping (uint => int8) temperatureForTime;
	address owner;

	function TemperatureOracle(address _owner) {
		owner = _owner;
	}

	function getTemperature(uint time) external constant returns (int8) {
		return temperatureForTime[time - (time % (60*60))];
	}

	function setTemperature(int8 temperature) external returns (bool success) {
		if(msg.sender != owner) { // only the owner can set the temperature
			return false;
		}

		temperatureForTime[now - (now % (60*60))] = temperature;

		return true;
	}
}



contract WeatherBet {

	struct Bet {
		address bettor;
		int8 temperature;
		uint value;
	}

	bool private betOver;
	
	Bet private bet1;
	Bet private bet2;

	uint private betEnd;
	
	TemperatureOracle private tempOracle;

	function abs(int8 n) internal constant returns (int8) {
		if(n >= 0) return n;
		return -n;
	}

	/// @notice Will create a new weather bet between `bettor1` and `bettor2` 
	/// that will be resolved on `_betEnd` using temperature oracle at `_tempOracle`.
	function WeatherBet(uint _betEnd, address _tempOracle, address bettor1, address bettor2) {
		betEnd = _betEnd;
		tempOracle = TemperatureOracle(_tempOracle);
		bet1.bettor = bettor1;
		bet2.bettor = bettor2;
	}

	function endBet() external returns (bool isOver) {
		if(now < betEnd) return false;
		if(betOver) return true;
		
		int8 temperature = tempOracle.getTemperature(betEnd);
		int8 bet1Diff = abs(temperature - bet1.temperature);
		int8 bet2Diff = abs(temperature - bet2.temperature);
		
		uint gasCost = tx.gasprice * 500;

		uint payOut = address(this).balance - gasCost;

		if(bet1Diff == bet2Diff) { // both bets are equally close, reimburse bets
			bet1.bettor.send(bet1.value - gasCost);
			bet2.bettor.send(bet2.value - gasCost);
		} else if(bet1Diff < bet2Diff) { // bet 1 is closer
			bet1.bettor.send(payOut);
		} else { // bet 2 is closer
			bet2.bettor.send(payOut);
		}
		
		betOver = true;
		return true;
	}


	function betOn(int8 temperature) external returns (bool successful) {
		if(betOver) return false;
		
		if(msg.sender == bet1.bettor) {
			if(bet1.temperature != 0) return false;
			bet1.temperature = temperature;
			bet1.value = msg.value;
			return true;
		}

		if(msg.sender == bet2.bettor) {
			if(bet2.temperature != 0) return false;
			bet2.temperature = temperature;
			bet2.value = msg.value;
			return true;
		}

		return false;
	}
}