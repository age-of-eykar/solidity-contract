const CoordinatesLib = artifacts.require("CoordinatesLib");
const Eykar = artifacts.require("Eykar");

module.exports = function (deployer) {
    deployer.deploy(CoordinatesLib);
    deployer.link(CoordinatesLib, Eykar);
    deployer.deploy(Eykar);
};