// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity >=0.8.0;

contract StadiumTicket is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum BlockDirection {NORTH, EAST, SOUTH, WEST}

    struct StadiumCategory {
        uint256 categoryId;
        uint256 price;
        BlockDirection direction;
        uint256 capacity;
        string name;
        uint256 minted;
    }

    struct MatchEvent {
        string homeTeam;
        string awayTeam;
        uint256 startDate;
    }

    MatchEvent public matchEvent;
    mapping (uint256 => StadiumCategory) categories;
    uint256[] supplies;

    constructor(string memory homeTeam_, string memory awayTeam_, uint256 startDate_) ERC1155("") {
        require(!compareStrings(homeTeam_, awayTeam_), "The home and away team can not be the same team.");
        require(startDate_ > block.timestamp, "You can not set start time of the match to a past date.");
        matchEvent = MatchEvent({
            homeTeam: homeTeam_,
            awayTeam: awayTeam_,
            startDate: startDate_
        });
    }

    function addCategory(uint256 price, uint8 direction, uint256 capacity, string memory name) public onlyOwner {
        require(direction <= uint8(BlockDirection.WEST), "Direction is out of range.");
        require(price >= 0, "Price should be greater than or equal to 0.");
        require(capacity > 0, "Capacity should be greater than 0.");
        for(uint256 i=0; i<supplies.length; i++) {
            require(!compareStrings(categories[i].name, name), "There is already a category with the same name.");
        }
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        categories[tokenId] = StadiumCategory(tokenId, price, BlockDirection(direction), capacity, name, 0);
        supplies.push(capacity);
    }

    function buyTicket(uint256 id, uint256 amount) public payable {
        require(supplies.length > 0, "There is no category to buy ticket");
        require(id <= supplies.length-1 && id >= 0, "Category does not exist.");
        require(categories[id].minted + amount <= supplies[id], "The category has not enough place for the amount you entered.");
        require(msg.value >= (categories[id].price * amount), "You don't have enough price.");
        _mint(msg.sender, id, amount, "");
        categories[id].minted += amount;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance is 0.");
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdraw couldn't be completed.");
    }
}