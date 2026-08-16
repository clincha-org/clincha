const fs = require("fs");
const { io } = require("socket.io-client");

const readSecret = (path) => fs.readFileSync(path, "utf8").trim();

const url = process.env.KUMA_URL;
const username = readSecret(process.env.KUMA_USERNAME_FILE);
const password = readSecret(process.env.KUMA_PASSWORD_FILE);

const done = (code, msg) => {
    console.log(msg);
    process.exit(code);
};

// Leave transports at the default. Forcing ["websocket"] gets as far as an
// accepted connection server-side but never completes the Socket.IO handshake,
// so the client sits waiting for a "connect" that never arrives. The default
// polling-then-upgrade path lands on websocket anyway.
const socket = io(url, { timeout: 10000 });

setTimeout(() => done(1, "timed out waiting for uptime-kuma"), 60000);

socket.on("connect_error", (err) => done(1, `connect failed: ${err.message}`));

socket.on("connect", () => {
    socket.emit("setup", username, password, (res) => {
        // The username comes from a mounted Secret; interpolating it into the
        // log is what CodeQL flags as clear-text logging of sensitive data.
        if (res.ok) {
            return done(0, "created admin user");
        }
        // Server-side guard: re-running against a populated user table is the
        // expected steady state, not a failure.
        if (/has been initialized/.test(res.msg || "")) {
            return done(0, "admin user already exists, nothing to do");
        }
        done(1, `setup failed: ${res.msg}`);
    });
});
