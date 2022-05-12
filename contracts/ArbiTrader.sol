//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "./loans/aave/DataTypes.sol";
import "./loans/aave/interfaces/IFlashLoanSimpleReceiver.sol";
import "./loans/aave/interfaces/IPoolAddressesProvider.sol";
import "./loans/aave/interfaces/IPool.sol";
import "./AbstractExchange.sol";

/**
 * @notice Functional contract is FlashLoanReceiverBase
 * @dev Contract will NOT store funds or store any given state.
 * @dev Will be upgradable after demo
 */
contract ArbiTrader is IFlashLoanSimpleReceiver, AbstractExchange {
    IPoolAddressesProvider public aavePoolProvider;
    IPool public aavePool;

    address public immutable treassury;
    address public immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    constructor(address _aavePoolProvider, address _treassury) {
        owner = msg.sender;
        treassury = payable(_treassury);
        aavePoolProvider = IPoolAddressesProvider(_aavePoolProvider);
        aavePool = IPool(aavePoolProvider.getPool());
    }

    /**
     * @notice Main function to trigger arbitrage
     * @param _asset address
     * @param _amount borrowed
     * @param _operations array of exchanges and swaps to perform
     */
    function performStrategy(
        address _asset,
        uint256 _amount,
        bytes calldata _operations
    ) external onlyOwner returns (bool) {
         _initFlashLoan(_asset,_amount,_operations);
        return true;
    }

    function _initFlashLoan(
        address _baseAsset,
        uint256 _loanAmount,
        bytes calldata _params
    ) internal onlyOwner {
        aavePool.flashLoanSimple(
            address(this),
            _baseAsset,
            _loanAmount,
            _params,
            0
        );
    }

    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _premium,
        address _initiator,
        bytes calldata _params
    ) external returns (bool) {
        require( IERC20(_asset).balanceOf(address(this)) >= _amount,"AT1 Loan Transfer Fail");
        // TOOO: arbi strategy 'executeOperation'

        // Reapy: Approve aave pool to take loan amount + fees
        SafeERC20.safeApprove(
            IERC20(_asset),
            address(aavePool),
            _amount + aavePool.FLASHLOAN_PREMIUM_TO_PROTOCOL()
        );
        return true;
    }

    /**
    * @notice Fetch Borrowed asset stats
    * @dev Read asset data
    * @param _asset Token to borrow
     */
    function getReserveData(address _asset)
        public
        view
        returns (DataTypes.ReserveData memory _data)
    {
        _data = aavePool.getReserveData(_asset);
    }

    fallback() external payable {}
}
