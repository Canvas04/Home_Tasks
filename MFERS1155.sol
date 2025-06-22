// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC1155} from "@openzeppelin/contracts@5.3.0/token/ERC1155/ERC1155.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts@5.3.0/token/ERC1155/extensions/ERC1155Burnable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts@5.3.0/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts@5.3.0/access/Ownable.sol";

contract MFERS1155 is ERC1155, ERC1155Burnable, Ownable, ERC1155Supply {
    constructor()
        ERC1155("ipfs://QmPMc4tcBsMqLRuCQtPmPe84bpSjrC3Ky7t3JWuHXYB4aS")
        Ownable(msg.sender)
    {}

    struct MintPhase {
        uint256 startTime;
        uint256 endTime;
        uint256 tokenId;
        uint256 price;
        uint256 maxSupply;
        uint256 mintedDuringPhase;
        bool stopped;
    }
    uint256 public lastPhase;
    mapping(uint256 => MintPhase) private mintPhases;
    /// @notice phaseId => amount of minting
    mapping(uint256 => uint256) private amountMinting;
    uint256 private constant MAX_TOKENS_PER_WALLET = 1;

    event MintPhaseCreated(
        uint256 phaseId,
        uint256 startTime,
        uint256 endTime,
        uint256 tokenId,
        uint256 price,
        uint256 maxSupply
    );
    event MintPhaseStopped(uint256 phaseId);
    error InvalidTime();
    error OutsideMintingTimeframe();
    error MintingPhaseStopped();
    error InsufficientFunds();
    error MintingPhaseSupplyReached();
    error NotEnoughtMoney();
    error TrasnferFundsFailed();
    error MintingAmountReached();

    function mint(uint256 _amount, uint256 _phaseId) external payable {
        MintPhase storage phase = mintPhases[_phaseId];

        require(
            block.timestamp >= phase.startTime &&
                block.timestamp <= phase.endTime,
            OutsideMintingTimeframe()
        );
        require(!phase.stopped, MintingPhaseStopped());
        require(msg.value >= _amount * phase.price, InsufficientFunds());
        require(
            phase.mintedDuringPhase + _amount <= phase.maxSupply,
            MintingPhaseSupplyReached()
        );

        amountMinting[_phaseId]++;

        require(
            amountMinting[_phaseId] <= MAX_TOKENS_PER_WALLET,
            MintingAmountReached()
        );

        phase.mintedDuringPhase += _amount;
        _mint(msg.sender, phase.tokenId, _amount, "");

        (bool success, ) = payable(msg.sender).call{
            value: phase.price * _amount
        }("");
        require(success, TrasnferFundsFailed());
    }

    function mintForOwner(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function createMintPhase(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tokenId,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyOwner {
        require(_endTime > _startTime, InvalidTime());
        lastPhase++;
        uint256 phaseId = lastPhase;
        mintPhases[phaseId] = MintPhase({
            startTime: _startTime,
            endTime: _endTime,
            tokenId: _tokenId,
            price: _price,
            maxSupply: _maxSupply,
            mintedDuringPhase: 0,
            stopped: false
        });

        emit MintPhaseCreated(
            phaseId,
            _startTime,
            _endTime,
            _tokenId,
            _price,
            _maxSupply
        );
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, values);
    }

    function getMintPhaseInfo(uint256 _phaseId)
        external
        view
        returns (MintPhase memory)
    {
        return mintPhases[_phaseId];
    }

    function isMintPhaseStopped(uint256 _phaseId) external view returns (bool) {
        return mintPhases[_phaseId].stopped;
    }

    function stopMintPhase(uint256 _phaseId) external {
        mintPhases[_phaseId].stopped = true;
        
        emit MintPhaseStopped(_phaseId);
    }
}
