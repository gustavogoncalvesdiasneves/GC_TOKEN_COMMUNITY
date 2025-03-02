// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GCToken is ERC721 {
    struct GC {
        string name;
        uint8 level;
        string img;
    }

    GC[] public GCs;
    address public otakuOwner;
    mapping(string => bool) private gcSongs;
    mapping(string => address) public songSuggestions;
    mapping(string => uint) public songVotes;
    mapping(address => uint) public fanContributions;
    mapping(string => uint8) public songRarity; 
    event SongSuggested(address indexed user, string song);
    event SongVoted(address indexed user, string song);
    event SongAdded(string song, uint8 rarity);
    event RewardClaimed(address indexed user, uint amount);

    ERC20 public rewardToken;

    constructor (address _rewardToken) ERC721("GCToken", "GCT") {
        otakuOwner = msg.sender;
        rewardToken = ERC20(_rewardToken);
        
        gcSongs["departures ~anata ni okuru ai no uta~"] = true;
        gcSongs["the everlasting guilty crown"] = true;
        gcSongs["euterpe"] = true;
        gcSongs["hill of sorrow"] = true;
        gcSongs["bios"] = true;
        gcSongs["planetes"] = true;
    }

    modifier onlyOtakuOwner() {
        require(msg.sender == otakuOwner, "Only the Otaku Owner can add new songs!");
        _;
    }

    function songsEgoist(string memory _song) public view returns (string memory) {
        string memory lowerSong = _toLower(_song);

        if (gcSongs[lowerSong]) {
            return string(abi.encodePacked("Sugoi! '", _song, "' this is an awesome song of Guilty Crown!"));
        } else {
            return "This song is not part of the Guilty Crown soundtrack...";
        }
    }

    function addSong(string memory _song) public onlyOtakuOwner {
        string memory lowerSong = _toLower(_song);
        require(!gcSongs[lowerSong], "This song is already in the list!");
        gcSongs[lowerSong] = true;
        songRarity[lowerSong] = _assignRarity();
        emit SongAdded(lowerSong, songRarity[lowerSong]);
    }

    function suggestSong(string memory _song) public {
        string memory lowerSong = _toLower(_song);
        require(songSuggestions[lowerSong] == address(0), "This song has already been suggested! (vote this song please)");
        songSuggestions[lowerSong] = msg.sender;
        emit SongSuggested(msg.sender, lowerSong);
    }

    function voteSong(string memory _song) public {
        string memory lowerSong = _toLower(_song);
        require(songSuggestions[lowerSong] != address(0), "This song is not suggested!");
        songVotes[lowerSong]++;
        emit SongVoted(msg.sender, lowerSong);
    }

    function addSongFromVotes(string memory _song) public onlyOtakuOwner {
        string memory lowerSong = _toLower(_song);
        require(songVotes[lowerSong] >= 5, "Not enough votes to add song.");
        addSong(lowerSong);
        fanContributions[songSuggestions[lowerSong]]++;
    }

    function claimReward() public {
        uint rewardAmount = fanContributions[msg.sender] * 10 * (10 ** 18);
        require(rewardAmount > 0, "No rewards to claim.");
        rewardToken.transfer(msg.sender, rewardAmount);
        fanContributions[msg.sender] = 0;
        emit RewardClaimed(msg.sender, rewardAmount);
    }

    function _assignRarity() internal view returns (uint8) {
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        if (random < 50) return 1; // Common
        if (random < 80) return 2; // Rare
        if (random < 95) return 3; // Epic
        return 4; // Legendary
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
