const Eykar = artifacts.require('Eykar');
const CoordinatesLib = artifacts.require('CoordinatesLib');

contract('Eykar', (accounts) => {

    it('should convert an id to a location on the spawn spiral', async () => {
        const coordinatesLib = await CoordinatesLib.deployed();
        const instance = await Eykar.deployed();

        for (let i = 0; i < 10; i++) {
            const result = await instance.findNextLocationOnSpiral(i, 3);
            const deserialized = await coordinatesLib.convertToCoordinates(result.location);
            assert.equal(deserialized.x.toNumber(), [0, 3, 3, 3, 0, -3, -3, -3, 0, 6][i]);
            assert.equal(deserialized.y.toNumber(), [0, 3, 0, -3, -3, -3, 0, 3, 3, 6][i]);
        }
    });

    it('should register a player and create its colonies', async () => {
        const instance = await Eykar.deployed();
        console.log();

        // register for 10 ethers (10000000000000000000 wei)
        await instance.register("First player", { value: 10000000000000000000, from: accounts[0] });
        const colonies = await instance.getColonies(accounts[0]);
        assert.equal(colonies.length, 1);
        assert.equal(colonies[0].name, "First player");
        assert.equal(colonies[0].owner, accounts[0]);
        assert.equal(colonies[0].location, '0x0000000000000000000000000000000000000000000000000000000000000000');
        assert.equal(colonies[0].plotsAmount, 0);
        assert.equal(colonies[0].people, 4);
        assert.equal(colonies[0].food, 8);
        assert.equal(colonies[0].materials, 16);
        assert.equal(colonies[0].redirection, 1);
    });

})