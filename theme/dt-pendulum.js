// Lesson 1: why dt matters, and how fixed-timestep "catch-up" fixes the rest.
//
// Three identical pendulums are driven by a simulated game loop whose update rate
// the reader controls (fewer love.update calls per second = bigger dt):
//   1. no dt       — every update steps the physics by 1/60 s, whatever really passed;
//   2. dt          — one step of length dt (semi-implicit Euler, as naive game code does);
//   3. dt + catch-up — accumulate real time and step in fixed 1/60 s slices
//                      (the "fix your timestep" pattern), capped at 0.25 s per frame.
// A gray ghost in every panel is the reference pendulum, integrated finely in real time.
// Inserted into the Markdown as <div class="dt-pendulum"></div>.
// Visible labels are Ukrainian on purpose: readers of the book see them.
(function () {
    "use strict";

    // g / L: natural angular frequency ≈ 8.5 rad/s, period ≈ 0.74 s. Chosen so that plain
    // semi-implicit Euler goes unstable (ω·dt > 2) at the slider's minimum of 4 updates/s.
    const K = 72;
    const THETA0 = 1.2;        // initial angle, rad (≈ 69°)
    const STEP = 1 / 60;       // fixed physics step for "no dt" and "catch-up"
    const CATCHUP_CAP = 0.25;  // longest frame the catch-up loop will simulate
    const STALL = 0.5;         // length of the "stall" button, s

    const PANELS = [
        { title: "Без dt", sub: "крок 1/60 с на кожен кадр", color: "#d64545" },
        { title: "З dt", sub: "один крок завдовжки dt", color: "#e8833a" },
        { title: "З dt і наздоганянням", sub: "кроки по 1/60 с, скільки вміститься", color: "#3a9a4e" },
    ];

    function el(tag, cls, text) {
        const e = document.createElement(tag);
        if (cls) e.className = cls;
        if (text !== undefined) e.textContent = text;
        return e;
    }

    // Semi-implicit (symplectic) Euler: velocity first, then position.
    function step(s, h) {
        s.w += -K * Math.sin(s.th) * h;
        s.th += s.w * h;
    }

    function wrapAngle(a) {
        return Math.atan2(Math.sin(a), Math.cos(a));
    }

    function build(host) {
        host.textContent = "";
        let rate = 60;
        let running = true;

        const rateRow = el("label", "dt-pendulum-rate");
        const rateInput = el("input");
        rateInput.type = "range";
        // Minimum 4/s, i.e. dt ≤ 0.25 s = CATCHUP_CAP: below that even catch-up would drop time
        // on every frame. The stall button shows what the cap does to a single long frame.
        rateInput.min = 4;
        rateInput.max = 60;
        rateInput.value = rate;
        const rateOut = el("output");
        rateRow.append(el("span", null, "Оновлень love.update за секунду:"), rateInput, rateOut);

        const buttons = el("div", "dt-pendulum-buttons");
        const pauseBtn = el("button", null, "⏸ Пауза");
        const stallBtn = el("button", null, "Підвисання " + String(STALL).replace(".", ",") + " с");
        const resetBtn = el("button", null, "↺ Скинути");
        for (const b of [pauseBtn, stallBtn, resetBtn]) b.type = "button";
        buttons.append(pauseBtn, stallBtn, resetBtn);

        const status = el("div", "dt-pendulum-status");
        const canvas = el("canvas", "dt-pendulum-canvas");
        const notes = el("div", "dt-pendulum-notes");
        host.append(rateRow, buttons, status, canvas, notes);
        const noteEls = PANELS.map(() => notes.appendChild(el("div")));

        // ref runs in real time; refShown is ref frozen at the last game update, so the ghost
        // and the error show what the game *should* display on that same frame.
        let ref, refShown, sims, catchAcc, sinceUpdate, stallLeft, simTime;

        function reset() {
            ref = { th: THETA0, w: 0 };
            refShown = { th: THETA0, w: 0 };
            sims = PANELS.map(() => ({ th: THETA0, w: 0 }));
            catchAcc = 0;
            sinceUpdate = 0;
            stallLeft = 0;
            simTime = 0;
        }

        // One love.update call with the given dt, for each of the three approaches.
        function gameUpdate(dt) {
            step(sims[0], STEP);
            step(sims[1], dt);
            catchAcc += Math.min(dt, CATCHUP_CAP);
            while (catchAcc >= STEP) {
                step(sims[2], STEP);
                catchAcc -= STEP;
            }
            refShown = { th: ref.th, w: ref.w };
            lastDt = dt;
        }
        let lastDt = 1 / 60;

        function draw() {
            const dpr = window.devicePixelRatio || 1;
            const w = host.clientWidth - 2;
            const h = Math.max(240, Math.min(320, w * 0.45));
            if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) {
                canvas.width = Math.round(w * dpr);
                canvas.height = Math.round(h * dpr);
                canvas.style.height = h + "px";
            }
            const ctx = canvas.getContext("2d");
            ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
            const style = getComputedStyle(document.documentElement);
            const fg = style.getPropertyValue("--fg").trim() || "#1f2933";
            const border = style.getPropertyValue("--table-border-color").trim() || "#d5dde8";
            ctx.clearRect(0, 0, w, h);
            const pw = w / 3;
            PANELS.forEach((p, i) => {
                const x0 = i * pw;
                if (i) {
                    ctx.strokeStyle = border;
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(x0, 6);
                    ctx.lineTo(x0, h - 6);
                    ctx.stroke();
                }
                ctx.fillStyle = p.color;
                ctx.font = "bold 14px sans-serif";
                ctx.textAlign = "center";
                ctx.fillText(p.title, x0 + pw / 2, 20);
                ctx.fillStyle = fg;
                ctx.globalAlpha = 0.7;
                ctx.font = "12px sans-serif";
                ctx.fillText(p.sub, x0 + pw / 2, 37);
                ctx.globalAlpha = 1;
                // The whole swing circle (radius L + bob) fits below the titles, so even a pendulum
                // that "exploded" and spins over the top never covers the text.
                const L = Math.max(30, Math.min(pw * 0.32, (h - 50) / 2 - 15));
                const px = x0 + pw / 2, py = 46 + L + 15;
                const bob = (th, color, alpha, r) => {
                    const bx = px + L * Math.sin(th), by = py + L * Math.cos(th);
                    ctx.globalAlpha = alpha;
                    ctx.strokeStyle = color;
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(px, py);
                    ctx.lineTo(bx, by);
                    ctx.stroke();
                    ctx.fillStyle = color;
                    ctx.beginPath();
                    ctx.arc(bx, by, r, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.globalAlpha = 1;
                };
                bob(refShown.th, "#7a8594", 0.35, 13);  // the ghost: where it should be
                bob(sims[i].th, p.color, 1, 11);
                ctx.fillStyle = fg;
                ctx.beginPath();
                ctx.arc(px, py, 3, 0, Math.PI * 2);
                ctx.fill();
            });
        }

        function updateText() {
            rateOut.textContent = rate;
            status.textContent = stallLeft > 0
                ? "Підвисання: love.update не викликається…"
                : "dt ≈ " + lastDt.toFixed(3).replace(".", ",") + " с  ·  сіра тінь — де маятник мав би бути насправді";
            sims.forEach((s, i) => {
                const blown = !Number.isFinite(s.th) || Math.abs(s.w) > 60;
                const err = Math.abs(wrapAngle(s.th - refShown.th)) * 180 / Math.PI;
                noteEls[i].className = blown || err > 20 ? "dt-pendulum-bad" : err > 5 ? "dt-pendulum-warn" : "dt-pendulum-good";
                noteEls[i].textContent = blown ? "фізика «вибухнула»" : "розбіжність з тінню: " + Math.round(err) + "°";
            });
        }

        let last = null;
        function frame(now) {
            if (!running || !visible) { last = null; return; }
            const real = last === null ? 0 : Math.min((now - last) / 1000, 0.1);
            last = now;
            // Reality: the reference pendulum, integrated finely every browser frame.
            for (let t = 0; t < real; t += 0.001) step(ref, Math.min(0.001, real - t));
            simTime += real;
            // The simulated game loop: an update call every 1/rate s, none during a stall.
            sinceUpdate += real;
            if (stallLeft > 0) {
                stallLeft -= real;
            } else if (sinceUpdate >= 1 / rate - 0.004) {
                // A little slack: browser frames are ~16.6 ms, just under 1/60 s, and without it
                // a 60/s game would update only every other frame.
                gameUpdate(sinceUpdate);
                sinceUpdate = 0;
            }
            draw();
            updateText();
            requestAnimationFrame(frame);
        }

        function start() {
            if (!running || !visible) return;
            last = null;
            requestAnimationFrame(frame);
        }

        rateInput.addEventListener("input", () => { rate = Number(rateInput.value); updateText(); });
        pauseBtn.addEventListener("click", () => {
            running = !running;
            pauseBtn.textContent = running ? "⏸ Пауза" : "▶ Далі";
            start();
        });
        stallBtn.addEventListener("click", () => { stallLeft = STALL; });
        resetBtn.addEventListener("click", () => { reset(); draw(); updateText(); });

        // Animate only while visible (inside a closed <details> the widget has no size).
        let visible = false;
        if ("IntersectionObserver" in window) {
            new IntersectionObserver(entries => {
                const was = visible;
                visible = entries[entries.length - 1].isIntersecting;
                if (visible && !was) start();
            }).observe(host);
        } else {
            visible = true;
        }

        reset();
        updateText();
        start();
    }

    function init() {
        for (const host of document.querySelectorAll(".dt-pendulum")) {
            if (!host.dataset.ready) {
                host.dataset.ready = "1";
                build(host);
            }
        }
    }

    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    } else {
        init();
    }
})();
