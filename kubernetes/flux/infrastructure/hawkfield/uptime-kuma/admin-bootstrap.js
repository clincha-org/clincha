const { io } = require("socket.io-client");

const url = process.env.KUMA_URL;
const username = process.env.KUMA_USERNAME;
const password = process.env.KUMA_PASSWORD;

const done = (code, msg) => {
    console.log(msg);
    process.exit(code);
};

const socket = io(url, { transports: [ "websocket" ], timeout: 10000 });

socket.on("connect_error", (err) => done(1, `connect failed: ${err.message}`));

socket.on("connect", () => {
    socket.emit("setup", username, password, (res) => {
        if (res.ok) {
            return done(0, `created admin user '${username}'`);
        }
        // Server-side guard: re-running against a populated user table is the
        // expected steady state, not a failure.
        if (/has been initialized/.test(res.msg || "")) {
            return done(0, "admin user already exists, nothing to do");
        }
        done(1, `setup failed: ${res.msg}`);
    });
});
