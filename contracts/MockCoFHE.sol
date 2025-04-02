// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity >=0.8.25 <0.9.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {FunctionId, Utils} from "@fhenixprotocol/cofhe-contracts/ICofhe.sol";
import "hardhat/console.sol";

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
    uint256 constant shiftedTypeMask = uintTypeMask << 8; // 0x7f007 bits reserved for uint type in the one before last byte

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

    function getUintTypeFromHash(uint256 hash) internal pure returns (uint8) {
        return uint8((hash & shiftedTypeMask) >> 8);
    }

    function getIsBoolTypeFromHash(uint256 hash) internal pure returns (bool) {
        uint8 inputType = getUintTypeFromHash(hash);
        return (inputType ^ Utils.EBOOL_TFHE) == 0;
    }

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

    function sliceString(
        string memory str,
        uint start,
        uint length
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        require(start + length <= strBytes.length, "Out of bounds");

        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = strBytes[start + i];
        }

        return string(result);
    }

    function stringifyCtHash(
        uint256 ctHash
    ) internal view returns (string memory) {
        string memory hashStr = Strings.toString(ctHash);
        uint256 length = bytes(hashStr).length;
        if (length <= 6) {
            return hashStr;
        }

        bool stored = inMockStorage[ctHash];
        uint256 value = mockStorage[ctHash];
        bool isBool = getIsBoolTypeFromHash(ctHash);

        string memory valueString = isBool
            ? (value == 1 ? "true" : "false")
            : Strings.toString(value);

        string memory truncated = string.concat(
            "",
            sliceString(hashStr, 0, 4),
            "..",
            sliceString(hashStr, length - 4, 4),
            "[",
            stored ? valueString : "EMPTY",
            "]"
        );

        return truncated;
    }

    // Storage functions

    function _set(uint256 ctHash, uint256 value, bool log) internal {
        mockStorage[ctHash] = value;
        inMockStorage[ctHash] = true;

        if (log && logOps)
            console.log("__cofhe__ set             ", stringifyCtHash(ctHash));
    }

    function _set(uint256 ctHash, uint256 value) internal {
        _set(ctHash, value, false);
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
            _set(ctHash, uint256(blockhash(block.number - 1)));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ random          ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.cast)) {
            _set(ctHash, _get(input));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ cast            ",
                        stringifyCtHash(input),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.not)) {
            bool inputIsTruthy = _get(input) == 1;
            _set(ctHash, !inputIsTruthy);

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ not             ",
                        stringifyCtHash(input),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.square)) {
            _set(ctHash, _get(input) * _get(input));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ square          ",
                        stringifyCtHash(input),
                        " * ",
                        stringifyCtHash(input),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
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
            _set(ctHash, _get(input1) - _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ sub             ",
                        stringifyCtHash(input1),
                        " - ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.add)) {
            _set(ctHash, _get(input1) + _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ add             ",
                        stringifyCtHash(input1),
                        " + ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.xor)) {
            _set(ctHash, _get(input1) ^ _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ xor             ",
                        stringifyCtHash(input1),
                        " ^ ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.and)) {
            _set(ctHash, _get(input1) & _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ and             ",
                        stringifyCtHash(input1),
                        " & ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.or)) {
            _set(ctHash, _get(input1) | _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ or              ",
                        stringifyCtHash(input1),
                        " | ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.div)) {
            _set(ctHash, _get(input1) / _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ div             ",
                        stringifyCtHash(input1),
                        " / ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.rem)) {
            _set(ctHash, _get(input1) % _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ rem             ",
                        stringifyCtHash(input1),
                        " % ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.mul)) {
            _set(ctHash, _get(input1) * _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ mul             ",
                        stringifyCtHash(input1),
                        " * ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.shl)) {
            _set(ctHash, _get(input1) << _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ shl             ",
                        stringifyCtHash(input1),
                        " << ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.shr)) {
            _set(ctHash, _get(input1) >> _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ shr             ",
                        stringifyCtHash(input1),
                        " >> ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.gte)) {
            _set(ctHash, _get(input1) >= _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ gte             ",
                        stringifyCtHash(input1),
                        " >= ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.lte)) {
            _set(ctHash, _get(input1) <= _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ lte             ",
                        stringifyCtHash(input1),
                        " <= ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.lt)) {
            _set(ctHash, _get(input1) < _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ lt              ",
                        stringifyCtHash(input1),
                        " < ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.gt)) {
            _set(ctHash, _get(input1) > _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ gt              ",
                        stringifyCtHash(input1),
                        " > ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.min)) {
            uint256 min = _get(input1) < _get(input2)
                ? _get(input1)
                : _get(input2);
            _set(ctHash, min);

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ min             ",
                        "min(",
                        stringifyCtHash(input1),
                        ", ",
                        stringifyCtHash(input2),
                        ") => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.max)) {
            uint256 max = _get(input1) > _get(input2)
                ? _get(input1)
                : _get(input2);
            _set(ctHash, max);

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ max             ",
                        "max(",
                        stringifyCtHash(input1),
                        ", ",
                        stringifyCtHash(input2),
                        ") => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.eq)) {
            _set(ctHash, _get(input1) == _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ eq              ",
                        stringifyCtHash(input1),
                        " == ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.ne)) {
            _set(ctHash, _get(input1) != _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ ne              ",
                        stringifyCtHash(input1),
                        " != ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.rol)) {
            _set(ctHash, _get(input1) << _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ rol             ",
                        stringifyCtHash(input1),
                        " << ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.ror)) {
            _set(ctHash, _get(input1) >> _get(input2));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ ror             ",
                        stringifyCtHash(input1),
                        " >> ",
                        stringifyCtHash(input2),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
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
            _set(ctHash, input1);

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ trivialEncrypt  ",
                        Strings.toString(input1),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        if (opIs(operation, FunctionId.select)) {
            _set(ctHash, _get(input1) == 1 ? _get(input2) : _get(input3));

            if (logOps)
                console.log(
                    string.concat(
                        "__cofhe__ select          ",
                        stringifyCtHash(input1),
                        " ? ",
                        stringifyCtHash(input2),
                        " : ",
                        stringifyCtHash(input3),
                        " => ",
                        stringifyCtHash(ctHash)
                    )
                );
            return;
        }
        revert InvalidThreeInputOperation(operation);
    }
}
