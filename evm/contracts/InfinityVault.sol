// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
  Infinity Vault (simple, secure vault split)
  - Accepts ETH and ERC20 tokens
  - Controlled by an owner (set to your Gnosis Safe address)
  - Configurable recipients and basis-point percentages (sum == 10000)
  - Distribute functions for ETH and ERC20 tokens
  - Rescue functions for emergency recovery (only owner)
  - Uses reentrancy guard and safe-call patterns
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract InfinityVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Recipients and their shares in basis points (bps). 10000 = 100%
    address[] public recipients;
    uint16[] public bps; // same length as recipients, each <= 10000

    event Deposited(address indexed from, uint256 amount);
    event DistributedETH(uint256 totalAmount);
    event DistributedERC20(address indexed token, uint256 totalAmount);
    event RecipientsUpdated(address[] recipients, uint16[] bps);
    event RescueTokens(address indexed token, address to, uint256 amount);
    event RescueETH(address indexed to, uint256 amount);

    constructor(address[] memory _recipients, uint16[] memory _bps, address owner_) {
        require(_recipients.length == _bps.length, "Length mismatch");
        require(_recipients.length > 0, "No recipients");
        _validateBpsSum(_bps);

        recipients = _recipients;
        bps = _bps;

        // Transfer ownership to the Gnosis Safe (owner_)
        _transferOwnership(owner_);
    }

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    // --- View helpers ---
    function getRecipients() external view returns (address[] memory) {
        return recipients;
    }

    function getBps() external view returns (uint16[] memory) {
        return bps;
    }

    // --- Owner only: update recipients / shares ---
    function updateRecipients(address[] calldata _recipients, uint16[] calldata _bps) external onlyOwner {
        require(_recipients.length == _bps.length, "Length mismatch");
        require(_recipients.length > 0, "No recipients");
        _validateBpsSum(_bps);

        recipients = _recipients;
        bps = _bps;
        emit RecipientsUpdated(_recipients, _bps);
    }

    // --- ETH distribution ---
    function distributeETH() external nonReentrant onlyOwner {
        uint256 total = address(this).balance;
        require(total > 0, "No ETH to distribute");
        _distributeETH(total);
        emit DistributedETH(total);
    }

    // --- ERC20 distribution ---
    function distributeERC20(IERC20 token) external nonReentrant onlyOwner {
        uint256 total = token.balanceOf(address(this));
        require(total > 0, "No tokens to distribute");
        _distributeERC20(token, total);
        emit DistributedERC20(address(token), total);
    }

    // --- Internal helpers ---
    function _distributeETH(uint256 total) internal {
        uint256 leftover = total;
        // Send each recipient their share; final recipient gets remainder to avoid rounding loss
        for (uint i = 0; i < recipients.length; i++) {
            uint256 share;
            if (i == recipients.length - 1) {
                share = leftover;
            } else {
                share = (total * bps[i]) / 10000;
                leftover -= share;
            }

            _safeSendETH(recipients[i], share);
        }
    }

    function _distributeERC20(IERC20 token, uint256 total) internal {
        uint256 distributed = 0;
        for (uint i = 0; i < recipients.length; i++) {
            uint256 share;
            if (i == recipients.length - 1) {
                share = total - distributed;
            } else {
                share = (total * bps[i]) / 10000;
                distributed += share;
            }

            token.safeTransfer(recipients[i], share);
        }
    }

    function _safeSendETH(address to, uint256 value) internal {
        if (value == 0) return;
        (bool ok, ) = to.call{ value: value }("");
        require(ok, "ETH send failed");
    }

    // --- Rescue / emergency functions (onlyOwner) ---
    function rescueERC20(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
        emit RescueTokens(address(token), to, amount);
    }

    function rescueETH(address payable to, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH");
        (bool ok, ) = to.call{ value: amount }("");
        require(ok, "Rescue ETH failed");
        emit RescueETH(to, amount);
    }

    // --- Validation ---
    function _validateBpsSum(uint16[] memory _bps) internal pure {
        uint256 sum = 0;
        for (uint i = 0; i < _bps.length; i++) {
            sum += _bps[i];
        }
        require(sum == 10000, "BPS must sum to 10000");
    }
}
