// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.5 <0.8.0;
pragma abicoder v2;

// A contract which has an owner.
contract Owned {
    // Owner of the contract.
    address payable public immutable owner;

    constructor() { owner = msg.sender; }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }
}

/// A contract which can be destroyied.
///
/// Only the contract owner can destruct an instance of this contract.
contract Destructible is Owned {
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}

contract MusicStore is Destructible {
    /// A music stored in the store.
    struct Music {
        // Id of the music.
        uint32 id;
        // Name of the music.
        string name;
        // Price to be paid for the music.
        uint256 price;
        // Is this music available to be bought.
        bool isAvailable;
    }

    /// The name of the store.
    string public name;

    // Musics stored in the store.
    mapping(uint32 => Music) storedMusics;
    // Musics contents.
    mapping(uint32 => bytes) musicsContent;
    // Id of the next music;
    uint32 nextMusicIdx;

    // List of musics that each user bought from this store.
    mapping(address => uint32[]) boughtLists;

    constructor(string memory _name) {
        name = _name;
    }

    modifier musicNameNotEmpty(string calldata _name) {
        require(bytes(_name).length != 0, "music name cannot be empty");
        _;
    }

    /// Adds a new music to the store.
    function addMusic(string calldata _name,
                      uint32 _price,
                      bytes memory _content)
        public
        onlyOwner
        musicNameNotEmpty(_name)
    {
        uint32 musicID = nextMusicIdx++;
        Music storage newMusic = storedMusics[musicID];
        newMusic.id = musicID;
        newMusic.name = _name;
        newMusic.price = _price;
        newMusic.isAvailable = true;
        musicsContent[musicID] = _content;
    }

    /// Hides a previously added music.
    ///
    /// No user can buy the music after this function is called.
    function hideMusic(string calldata _name)
        public
        onlyOwner
        musicNameNotEmpty(_name)
    {
        Music storage music = getMusicByName(_name);
        music.isAvailable = false;
    }

    /// Show a previously hidden music.
    ///
    /// User can buy the music after this function is called.
    function showMusic(string calldata _name)
        public
        onlyOwner
        musicNameNotEmpty(_name)
    {
        Music storage music = getMusicByName(_name);
        music.isAvailable = true;
    }

    /// Withdraw the current balance of the contract.
    function withdraw()
        public
        onlyOwner
    {
        owner.transfer(address(this).balance);
    }

    /// List all available musics in this storage.
    function listAvailableMusics()
        public
        view
        returns (Music[] memory musics, uint32 total)
    {
        musics = new Music[](nextMusicIdx);
        for (uint32 i = 0; i < nextMusicIdx; i++) {
            Music memory music = storedMusics[i];
            if (music.isAvailable) {
                musics[total++] = music;
            }
        }
    }

    /// List all musics bought by the sender.
    function listBoughtMusics()
        public
        view
        returns (Music[] memory musics)
    {
        uint32[] storage boughtList = boughtLists[msg.sender];
        musics = new Music[](boughtList.length);

        for (uint32 i = 0; i < boughtList.length; i++) {
            musics[i] = storedMusics[boughtList[i]];
        }
    }

    /// Buy a music.
    function buyMusic(string calldata _name)
        public
        payable
        musicNameNotEmpty(_name)
    {
        Music storage music = getMusicByName(_name);
        require(msg.value == music.price, "wrong transaction value");

        uint32[] storage boughtList = boughtLists[msg.sender];
        for (uint32 i = 0; i < boughtList.length; i++) {
            require(boughtList[i] != music.id, "music already bought");
        }

        boughtList.push(music.id);
    }

    /// Get the contents of a previously bought music.
    function getMusicContent(string calldata _name)
        public
        view
        musicNameNotEmpty(_name)
        returns (bytes memory)
    {
        uint32[] storage boughtList = boughtLists[msg.sender];
        for (uint32 i = 0; i < boughtList.length; i++) {
            Music storage music = storedMusics[boughtList[i]];
            if (compareStrings(music.name, _name)) {
                return musicsContent[music.id];
            }
        }

        revert("music not found or not bought");
    }

    function getMusicByName(string calldata _name)
        internal
        view
        musicNameNotEmpty(_name)
        returns (Music storage music)
    {
        music = storedMusics[nextMusicIdx];
        for (uint32 i = 0; i < nextMusicIdx; i++) {
            music = storedMusics[i];
            if (compareStrings(music.name, _name)) {
                return music;
            }
        }

        revert("music not found");
    }
}

function compareStrings(string memory a, string memory b) pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
}
