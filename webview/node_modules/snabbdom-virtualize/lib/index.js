'use strict';

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.virtualizeString = exports.virtualizeNode = undefined;

exports.default = function (el, options) {
    if (typeof el === 'string') {
        return (0, _strings2.default)(el, options);
    } else {
        return (0, _nodes2.default)(el, options);
    }
};

var _nodes = require('./nodes');

var _nodes2 = _interopRequireDefault(_nodes);

var _strings = require('./strings');

var _strings2 = _interopRequireDefault(_strings);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.virtualizeNode = _nodes2.default;
exports.virtualizeString = _strings2.default;