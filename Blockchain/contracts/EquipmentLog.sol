// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// We import this from OpenZeppelin, a security-audited library.
import "@openzeppelin/contracts/access/AccessControl.sol";

contract EquipmentLog is AccessControl {

    // --- Role Definitions ---
    // A Super Admin (you) who can grant roles.
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    // An In-Charge (Sports, Lab) who can manage equipment.
    bytes32 public constant INCHARGE_ROLE = keccak256("INCHARGE_ROLE");

    // --- Events (The Logbook) ---
    // These write the "history" to the blockchain.
    event LogNewEquipment(
        bytes32 indexed equipmentId,
        string equipmentName,
        address indexed registeredBy,
        uint256 timestamp
    );
    event LogDecommission(
        bytes32 indexed equipmentId,
        string reason,
        address indexed decommissionedBy,
        uint256 timestamp
    );
    event LogCheckout(
        bytes32 indexed equipmentId,
        string studentId, // Using string for Firebase UIDs
        address indexed inChargeAddress,
        uint256 timestamp
    );
    event LogReturn(
        bytes32 indexed equipmentId,
        string studentId,
        address indexed inChargeAddress,
        uint256 timestamp
    );

    /**
     * @dev Sets up the contract when it's first deployed.
     * The person who deploys this (you) gets the SUPER_ADMIN_ROLE.
     */
    constructor() {
        // Grant the deployer (msg.sender) the default admin role.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant the deployer the SUPER_ADMIN_ROLE.
        _grantRole(SUPER_ADMIN_ROLE, msg.sender);
    }

    // --- Admin Functions (for Super Admin only) ---

    /**
     * @dev Allows a Super Admin to grant the InCharge role.
     * This is how you give the Sports In-Charge their "power".
     */
    function grantInChargeRole(address _inChargeAddress)
        public
        onlyRole(SUPER_ADMIN_ROLE) // Only Super Admin can call
    {
        _grantRole(INCHARGE_ROLE, _inChargeAddress);
    }

    /**
     * @dev Allows a Super Admin to revoke the InCharge role.
     */
    function revokeInChargeRole(address _inChargeAddress)
        public
        onlyRole(SUPER_ADMIN_ROLE) // Only Super Admin can call
    {
        _revokeRole(INCHARGE_ROLE, _inChargeAddress);
    }

    // --- In-Charge Functions (for In-Charge only) ---

    /**
     * @dev Creates the "birth certificate" for a new item.
     */
    function registerNewEquipment(
        bytes32 _equipmentId,
        string memory _equipmentName
    ) public onlyRole(INCHARGE_ROLE) { // Only In-Charge can call
        emit LogNewEquipment(
            _equipmentId,
            _equipmentName,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Creates the "death certificate" for a damaged item.
     */
    function decommissionEquipment(
        bytes32 _equipmentId,
        string memory _reason
    ) public onlyRole(INCHARGE_ROLE) { // Only In-Charge can call
        emit LogDecommission(
            _equipmentId,
            _reason,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Logs a checkout transaction.
     */
    function logCheckout(bytes32 _equipmentId, string memory _studentId)
        public
        onlyRole(INCHARGE_ROLE) // Only In-Charge can call
    {
        emit LogCheckout(
            _equipmentId,
            _studentId,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev Logs a return transaction.
     */
    function logReturn(bytes32 _equipmentId, string memory _studentId)
        public
        onlyRole(INCHARGE_ROLE) // Only In-Charge can call
    {
        emit LogReturn(
            _equipmentId,
            _studentId,
            msg.sender,
            block.timestamp
        );
    }
}