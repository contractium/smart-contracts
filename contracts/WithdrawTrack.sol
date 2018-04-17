pragma solidity ^0.4.21;
// pragma experimental ABIEncoderV2;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract WithdrawTrack is StandardToken, Ownable {

	struct TrackInfo {
		address to;
		uint256 amountToken;
		string withdrawId;
	}

	mapping(string => TrackInfo) withdrawTracks;

	function withdrawToken(address _to, uint256 _amountToken, string _withdrawId) public onlyOwner returns (bool) {
		bool result = transfer(_to, _amountToken);
		if (result) {
			withdrawTracks[_withdrawId] = TrackInfo(_to, _amountToken, _withdrawId);
		}
		return result;
	}

	function withdrawTrackOf(string _withdrawId) public view returns (address to, uint256 amountToken) {
		TrackInfo track = withdrawTracks[_withdrawId];
		return (track.to, track.amountToken);
	}

}