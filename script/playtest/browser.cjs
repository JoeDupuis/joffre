#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { execFileSync, execSync } = require("child_process");

const ROOT = path.resolve(__dirname, "../..");

function loadPlaywright() {
  const candidates = [process.env.PLAYWRIGHT_MODULE, "playwright"];
  try {
    candidates.push(path.join(execSync("npm root -g", { encoding: "utf8" }).trim(), "playwright"));
  } catch {}
  candidates.push("/opt/node22/lib/node_modules/playwright");
  for (const candidate of candidates.filter(Boolean)) {
    try {
      return require(candidate);
    } catch {}
  }
  throw new Error("Global playwright package not found. Set PLAYWRIGHT_MODULE; never run `playwright install` or add a package.json.");
}

function parseArgs(argv) {
  const options = {
    baseUrl: process.env.PLAYTEST_URL || "http://localhost:3000",
    game: null,
    maxScore: 21,
    seed: Date.now() % 100000,
    bidChance: 0.3,
    maxActions: 3000,
    staleMs: 5000,
    out: null,
    phone: true,
  };
  for (let i = 0; i < argv.length; i++) {
    const [flag, value] = [argv[i], argv[i + 1]];
    switch (flag) {
      case "--base-url": options.baseUrl = value; i++; break;
      case "--game": options.game = Number(value); i++; break;
      case "--max-score": options.maxScore = Number(value); i++; break;
      case "--seed": options.seed = Number(value); i++; break;
      case "--bid-chance": options.bidChance = Number(value); i++; break;
      case "--max-actions": options.maxActions = Number(value); i++; break;
      case "--stale-ms": options.staleMs = Number(value); i++; break;
      case "--out": options.out = value; i++; break;
      case "--no-phone": options.phone = false; break;
      case "-h":
      case "--help":
        console.log(`Usage: node script/playtest/browser.cjs [options]
  --game ID         Drive an existing game (default: create a full lobby with state.rb)
  --max-score N     Target score for a new game (default 21)
  --seed N          Seed for bot choices
  --bid-chance F    Chance an opening bidder bids the minimum instead of passing (default 0.3)
  --stale-ms N      How long other pages get to live-update after an action (default 5000)
  --max-actions N   Safety limit (default 3000)
  --out DIR         Screenshot directory (default tmp/playtest/<timestamp>)
  --no-phone        Skip the iPhone 13 observer
  --base-url URL    Default http://localhost:3000 (or PLAYTEST_URL)`);
        process.exit(0);
      default:
        throw new Error(`Unknown option ${flag}`);
    }
  }
  return options;
}

function random(seed) {
  let state = seed >>> 0 || 1;
  return () => {
    state = (state * 1664525 + 1013904223) >>> 0;
    return state / 2 ** 32;
  };
}

function rails(args, baseUrl) {
  const output = execFileSync("bin/rails", ["runner", "script/playtest/state.rb", ...args, "--json"], {
    cwd: ROOT,
    encoding: "utf8",
    env: { ...process.env, PLAYTEST_URL: baseUrl },
  });
  return JSON.parse(output.trim().split("\n").pop());
}

const HIDE_DEV_OVERLAYS = ".branch-indicator, .dev-signout-form, .dev-signout-button { display: none !important; }";

function snapshot() {
  const text = (selector) => [...document.querySelectorAll(selector)].map((node) => node.innerText.trim()).join("|");
  const alts = (selector) => [...document.querySelectorAll(selector)].map((node) => node.alt).join(",");
  const message = text(".phase-area .message");
  let phase = "wait";
  if (document.querySelector(".round-result")) phase = "done";
  else if (document.querySelector(".bid-controls")) phase = "bid";
  else if (document.querySelector(".player-hand button.card")) phase = "play";
  else if (document.querySelector(".game-lobby")) phase = "lobby";
  return {
    phase,
    path: location.pathname,
    message,
    signature: [message, text(".bid-history .list"), alts(".play-area img"), alts(".player-hand img"), text(".score-board .team-line"), text(".round-result .title"), text(".team-display .title")].join("#"),
    highBidderNone: /High Bidder:\s*None/.test(text(".game-info")),
    canPass: [...document.querySelectorAll(".bid-controls button")].some((button) => button.innerText.trim() === "Pass"),
    tableCards: document.querySelectorAll(".play-area:not(.-last) img").length,
    lastTrick: !!document.querySelector(".play-area.-last"),
    roundSummary: !!document.querySelector(".round-summary"),
    result: text(".round-result .title"),
    canStart: [...document.querySelectorAll("button")].some((button) => button.innerText.trim() === "Start Game"),
  };
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const { chromium, devices } = loadPlaywright();
  const rand = random(options.seed);
  const out = path.resolve(ROOT, options.out || path.join("tmp/playtest", new Date().toISOString().replace(/[:.]/g, "-")));
  const authDir = path.join(ROOT, "tmp/playtest/auth");
  fs.mkdirSync(out, { recursive: true });
  fs.mkdirSync(authDir, { recursive: true });

  const game = options.game ? rails(["show", "--game", String(options.game)], options.baseUrl) : rails(["lobby", "--max-score", String(options.maxScore)], options.baseUrl);
  console.log(`Game #${game.id} (${game.status}, target ${game.max_score}) at ${options.baseUrl}/games/${game.id}, seed ${options.seed}`);

  const launch = { headless: true };
  const fallbackChrome = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
  if (!process.env.PLAYWRIGHT_BROWSERS_PATH && fs.existsSync(fallbackChrome)) launch.executablePath = fallbackChrome;
  const browser = await chromium.launch(launch);

  const problems = [];
  const errors = [];

  async function signIn(player, contextOptions, label) {
    const authFile = path.join(authDir, `${new URL(options.baseUrl).port || "80"}-${player.email}.json`);
    const context = await browser.newContext({
      ...contextOptions,
      baseURL: options.baseUrl,
      storageState: fs.existsSync(authFile) ? authFile : undefined,
    });
    const page = await context.newPage();
    page.on("pageerror", (error) => errors.push(`${label}: ${error.message}`));
    page.on("console", (message) => message.type() === "error" && errors.push(`${label}: ${message.text()}`));
    await page.goto(`/games/${game.id}`);
    if (new URL(page.url()).pathname.startsWith("/session")) {
      await page.goto("/session/new");
      const token = await page.locator('meta[name="csrf-token"]').getAttribute("content");
      const response = await page.request.post("/dev/switch_user", {
        form: { user_id: String(player.user_id), game_id: String(game.id), authenticity_token: token },
      });
      if (!response.ok()) throw new Error(`Dev sign-in for ${player.email} failed with ${response.status()} (is the server running in development?)`);
      await context.storageState({ path: authFile });
      await page.goto(`/games/${game.id}`);
    }
    if (!page.url().includes(`/games/${game.id}`)) throw new Error(`${label} landed on ${page.url()} instead of the game`);
    return { label, player, page };
  }

  const desktop = { viewport: { width: 1280, height: 900 } };
  const seats = [];
  for (const player of game.players) seats.push(await signIn(player, desktop, player.name.split(" ")[0]));
  const observers = [...seats];
  let phone = null;
  if (options.phone) {
    const owner = game.players.find((player) => player.owner) || game.players[0];
    phone = await signIn(owner, { ...devices["iPhone 13"] }, `${owner.name.split(" ")[0]} (iPhone 13)`);
    observers.push(phone);
  }

  const shots = new Set();
  async function screenshot(name, seat) {
    if (shots.has(name)) return;
    shots.add(name);
    const target = seat || seats[0];
    await target.page.screenshot({ path: path.join(out, `${name}-desktop.png`), fullPage: true, style: HIDE_DEV_OVERLAYS });
    if (phone) await phone.page.screenshot({ path: path.join(out, `${name}-phone.png`), fullPage: true, style: HIDE_DEV_OVERLAYS });
  }

  const read = (seat) => seat.page.evaluate(snapshot);
  const readAll = () => Promise.all(observers.map(read));

  async function waitFor(check, timeout) {
    const started = Date.now();
    while (Date.now() - started < timeout) {
      if (await check()) return true;
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
    return false;
  }

  const latencies = { own: [], others: [] };
  async function act(seat, describe, click) {
    const before = await readAll();
    const clicked = Date.now();
    await seat.page.mouse.move(0, 0);
    await click();
    const index = observers.indexOf(seat);
    const own = await waitFor(async () => (await read(seat)).signature !== before[index].signature, options.staleMs);
    if (!own) problems.push(`${seat.label}'s own page did not change after ${describe}`);
    latencies.own.push(Date.now() - clicked);
    const pending = new Set(observers.filter((observer) => observer !== seat));
    await waitFor(async () => {
      for (const observer of [...pending]) {
        if ((await read(observer)).signature !== before[observers.indexOf(observer)].signature) pending.delete(observer);
      }
      return pending.size === 0;
    }, options.staleMs);
    latencies.others.push(Date.now() - clicked);
    for (const observer of pending) problems.push(`${observer.label} did not live-update within ${options.staleMs}ms after ${seat.label} ${describe}`);
  }

  let actions = 0;
  while (actions < options.maxActions) {
    const states = await Promise.all(seats.map(read));

    if (states.every((state) => state.phase === "done")) break;

    if (states.every((state) => state.phase === "lobby")) {
      await screenshot("01-lobby", seats.find((seat) => seat.player.owner));
      const ownerIndex = states.findIndex((state) => state.canStart);
      if (ownerIndex < 0) throw new Error("Lobby has no Start Game button for the owner (is it full?)");
      const seat = seats[ownerIndex];
      await act(seat, "started the game", () => seat.page.getByRole("button", { name: "Start Game" }).click());
      actions++;
      continue;
    }

    const actors = states.map((state, index) => [state, seats[index]]).filter(([state]) => state.phase === "bid" || state.phase === "play");
    if (actors.length !== 1) {
      const settled = await waitFor(async () => (await Promise.all(seats.map(read))).filter((state) => state.phase === "bid" || state.phase === "play").length === 1, options.staleMs);
      if (!settled) {
        const summary = (await Promise.all(seats.map(read))).map((state, index) => `${seats[index].label}: ${state.phase} "${state.message}"`).join("; ");
        problems.push(`Expected exactly one player to act, got: ${summary}`);
        break;
      }
      continue;
    }

    const [state, seat] = actors[0];
    if (state.roundSummary) {
      if (!shots.has("05-round-summary")) await screenshot("05-round-summary", seat);
    } else if (state.phase === "bid") {
      await screenshot("02-bidding", seat);
    }
    if (state.phase === "play" && state.tableCards === 2) await screenshot("03-mid-trick", seat);
    if (state.phase === "play" && state.lastTrick) await screenshot("04-trick-done", seat);

    if (state.phase === "bid") {
      const bid = !state.canPass || (state.highBidderNone && rand() < options.bidChance);
      const button = bid ? seat.page.locator(".bid-controls .bid-option:not(.-secondary)").first() : seat.page.locator(".bid-controls button", { hasText: "Pass" });
      const label = bid ? await button.innerText() : "Pass";
      await act(seat, `bid ${label.trim()}`, () => button.click());
    } else {
      const cards = seat.page.locator(".player-hand button.card");
      const count = await cards.count();
      const card = cards.nth(Math.floor(rand() * count));
      const alt = await card.locator("img").getAttribute("alt");
      await act(seat, `played ${alt}`, () => card.click());
    }
    actions++;
  }

  const finals = await readAll();
  if (finals.every((state) => state.phase === "done")) {
    const winner = seats.find((seat, index) => /Win/.test(finals[index].result)) || seats[0];
    const loser = seats.find((seat, index) => /Lose/.test(finals[index].result));
    await screenshot("06-done", winner);
    if (loser) await loser.page.screenshot({ path: path.join(out, "06-done-loser-desktop.png"), fullPage: true, style: HIDE_DEV_OVERLAYS });
    const winners = finals.filter((state) => /Win/.test(state.result)).length;
    if (winners !== 2 && finals.length) problems.push(`Expected 2 of 4 seats to see "You Win", got ${winners}`);
  } else {
    problems.push(`Game did not finish after ${actions} actions`);
  }

  const result = rails(["show", "--game", String(game.id)], options.baseUrl);
  await browser.close();

  const stats = (values) => {
    const sorted = [...values].sort((a, b) => a - b);
    return sorted.length ? `p50 ${sorted[Math.floor(sorted.length / 2)]}ms, max ${sorted[sorted.length - 1]}ms` : "n/a";
  };
  console.log(`Actions: ${actions}. Final status: ${result.status}. Screenshots: ${path.relative(ROOT, out)}`);
  console.log(`Acting page updated: ${stats(latencies.own)}. All pages updated: ${stats(latencies.others)}`);
  for (const file of fs.readdirSync(out).sort()) console.log(`  ${file}`);
  if (errors.length) console.log(`Browser errors:\n  ${errors.join("\n  ")}`);
  if (problems.length) {
    console.log(`Problems:\n  ${problems.join("\n  ")}`);
    process.exit(1);
  }
  console.log("OK: every action live-updated all pages without reloads");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
