// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity >=0.8.25 <0.9.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {FunctionId, Utils} from "@fhenixprotocol/cofhe-contracts/ICofhe.sol";

address constant SIGNER_ADDRESS = 0x6E12D8C87503D4287c294f2Fdef96ACd9DFf6bd2;
uint256 constant SIGNER_PRIVATE_KEY = 49099792800763675079532137679706322989817545357788440619111868498148356080914;

/**
 * @dev Mock implementation of the CoFHE contract, used to test FHE ops in isolation.
 * Is inherited by MockTaskManager.
 *
 * It is responsible for storing a map of ctHash -> value
 * and for performing the operations on the values.
 *
 * It is intended as a 1:1 drop-in replacement for the real CoFHE coprocessor, with the following differences:
 * - AsyncCallbacks are called synchronously (with a mock 1-10 second delay).
 * - Unencrypted values are available onchain via the `mockStorage` map.
 *
 * NOTE: This is not used in production
 */
abstract contract MockCoFHE {
    // Pulled from TMCommon
    uint256 constant uintTypeMask = (type(uint8).max >> 1); // 0x7f - 7 bits reserved for uint type in the one before last byte
    uint256 constant triviallyEncryptedMask = type(uint8).max - uintTypeMask; //0x80  1 bit reserved for isTriviallyEncrypted

    bool public logOps = true;

    mapping(uint256 => uint256) public mockStorage;
    mapping(uint256 => bool) public inMockStorage;

    error InputNotInMockStorage(uint256 ctHash);

    // Used internally to check if we missed any operations in the mocks
    error InvalidUnaryOperation(string operation);
    error InvalidTwoInputOperation(string operation);
    error InvalidThreeInputOperation(string operation);

    // OPTIONS

    function setLogOps(bool _logOps) public {
        logOps = _logOps;
    }

    // Utils

    function strEq(
        string memory _a,
        string memory _b
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function opIs(
        string memory op,
        FunctionId fid
    ) internal pure returns (bool) {
        return strEq(op, Utils.functionIdToString(fid));
    }

    // Storage functions

    function _set(uint256 ctHash, uint256 value) internal {
        mockStorage[ctHash] = value;
        inMockStorage[ctHash] = true;
    }

    function _set(uint256 ctHash, bool value) internal {
        _set(ctHash, value ? 1 : 0);
    }

    function _get(uint256 ctHash) internal view returns (uint256) {
        if (!inMockStorage[ctHash]) revert InputNotInMockStorage(ctHash);
        return mockStorage[ctHash];
    }

    // Public functions

    function MOCK_setInEuintKey(uint256 ctHash, uint256 value) public {
        _set(ctHash, value);
    }

    // Mock functions

    function MOCK_verifyKeyInStorage(uint256 ctHash) internal view {
        if (!inMockStorage[ctHash]) revert InputNotInMockStorage(ctHash);
    }

    function MOCK_unaryOperation(
        uint256 ctHash,
        string memory operation,
        uint256 input
    ) internal {
        if (opIs(operation, FunctionId.random)) {
            // if (logOps) console.log("MOCK_random", ctHash);
            _set(ctHash, uint256(blockhash(block.number - 1)));
            return;
        }
        if (opIs(operation, FunctionId.cast)) {
            // if (logOps) console.log("MOCK_cast", ctHash, _get(input));
            _set(ctHash, _get(input));
            return;
        }
        if (opIs(operation, FunctionId.not)) {
            bool inputIsTruthy = _get(input) == 1;
            // if (logOps)
            //     console.log("MOCK_not", ctHash, inputIsTruthy, !inputIsTruthy);
            _set(ctHash, !inputIsTruthy);
            return;
        }
        if (opIs(operation, FunctionId.square)) {
            // if (logOps)
            //     console.log(
            //         "MOCK_square",
            //         ctHash,
            //         _get(input),
            //         _get(input) * _get(input)
            //     );
            _set(ctHash, _get(input) * _get(input));
            return;
        }
        revert InvalidUnaryOperation(operation);
    }

    function MOCK_twoInputOperation(
        uint256 ctHash,
        string memory operation,
        uint256 input1,
        uint256 input2
    ) internal {
        if (opIs(operation, FunctionId.sub)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_sub",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) - _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) - _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.add)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_add",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) + _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) + _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.xor)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_xor",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) ^ _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) ^ _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.and)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_and",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) & _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) & _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.or)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_or",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) | _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) | _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.div)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_div",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) / _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) / _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.rem)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_rem",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) % _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) % _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.mul)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_mul",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) * _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) * _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.shl)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_shl",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) << _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) << _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.shr)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_shr",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) >> _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) >> _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.gte)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_gte",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             _get(input1) >= _get(input2) ? "1 (true)" : "0 (false)"
            //         )
            //     );
            _set(ctHash, _get(input1) >= _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.lte)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_lte",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             _get(input1) <= _get(input2) ? "1 (true)" : "0 (false)"
            //         )
            //     );
            _set(ctHash, _get(input1) <= _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.lt)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_lt",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             _get(input1) < _get(input2) ? "1 (true)" : "0 (false)"
            //         )
            //     );
            _set(ctHash, _get(input1) < _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.gt)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_gt",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             _get(input1) > _get(input2) ? "1 (true)" : "0 (false)"
            //         )
            //     );
            _set(ctHash, _get(input1) > _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.min)) {
            uint256 min = _get(input1) < _get(input2)
                ? _get(input1)
                : _get(input2);
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_min",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(min)
            //         )
            //     );
            _set(ctHash, min);
            return;
        }
        if (opIs(operation, FunctionId.max)) {
            uint256 max = _get(input1) > _get(input2)
                ? _get(input1)
                : _get(input2);
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_max",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(max)
            //         )
            //     );
            _set(ctHash, max);
            return;
        }
        if (opIs(operation, FunctionId.eq)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_eq",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             _get(input1) == _get(input2) ? "1 (true)" : "0 (false)"
            //         )
            //     );
            _set(ctHash, _get(input1) == _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.ne)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_ne",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             _get(input1) != _get(input2) ? "1 (true)" : "0 (false)"
            //         )
            //     );
            _set(ctHash, _get(input1) != _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.rol)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_rol",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) << _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) << _get(input2));
            return;
        }
        if (opIs(operation, FunctionId.ror)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_ror",
            //             " (",
            //             Strings.toString(_get(input1)),
            //             ", ",
            //             Strings.toString(_get(input2)),
            //             ") => ",
            //             Strings.toString(_get(input1) >> _get(input2))
            //         )
            //     );
            _set(ctHash, _get(input1) >> _get(input2));
            return;
        }
        revert InvalidTwoInputOperation(operation);
    }

    function MOCK_threeInputOperation(
        uint256 ctHash,
        string memory operation,
        uint256 input1,
        uint256 input2,
        uint256 input3
    ) internal {
        if (opIs(operation, FunctionId.trivialEncrypt)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_trivialEncrypt",
            //             " (",
            //             Strings.toString(ctHash),
            //             ") => ",
            //             Strings.toString(input1)
            //         )
            //     );
            _set(ctHash, input1);
            return;
        }
        if (opIs(operation, FunctionId.select)) {
            // if (logOps)
            //     console.log(
            //         string.concat(
            //             "MOCK_select",
            //             " (",
            //             _get(input1) == 1 ? "1 (true)" : "0 (false)",
            //             " ? ",
            //             Strings.toString(_get(input2)),
            //             " : ",
            //             Strings.toString(_get(input3)),
            //             ") => ",
            //             Strings.toString(
            //                 _get(input1) == 1 ? _get(input2) : _get(input3)
            //             )
            //         )
            //     );
            _set(ctHash, _get(input1) == 1 ? _get(input2) : _get(input3));
            return;
        }
        revert InvalidThreeInputOperation(operation);
    }
}
