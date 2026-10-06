# Fork & Flame — restaurant website + management system

One Node app that serves the customer website **and** the staff panels. SQLite database, no external services.

* **Customers:** browse 122 dishes (with photos), order for delivery / pickup / dine-in (QR table ordering), and follow the order live on a tracking page.
* **Staff:** role-based panels — Owner, Manager, Cashier, Kitchen, Rider — all updating in real time.

## Quick start

```bash
npm install
npm run dev            # http://localhost:3000   (demo data + demo staff accounts)
```

Production:

```bash
npm install
npm run build
cp .env.example .env   # edit it
npm start
```

or with Docker: `docker build -t forkflame . && docker run -p 3000:3000 -v ffdata:/data -e ADMIN_PASSWORD='ChooseOne123' forkflame`

> **Persist `DATA_DIR`.** The database and uploaded photos live there. On hosts with an ephemeral disk, attach a volume or the data is lost on redeploy.

## Staff sign-in

Open **`/staff`**. In development (demo data on) every account uses password `Demo@1234`:

| Username | Role | Lands on |
|---|---|---|
| `owner` | Owner | Dashboard (everything, incl. staff accounts) |
| `manager` | Manager | Dashboard, orders, menu, reviews, settings |
| `cashier` | Cashier | Counter / POS |
| `kitchen` | Kitchen | Kitchen display |
| `rider1`, `rider2` | Rider | Deliveries |

In production (`SEED_DEMO=false`) only the owner is created, using `ADMIN_USERNAME` / `ADMIN_PASSWORD` (or a random password printed once in the log). Create the rest under **Staff**. New accounts must change their password on first sign-in.

## Order flow

```
Delivery : Received → Confirmed → Preparing → Ready → Out for delivery → Delivered
Pickup / Dine-in : Received → Confirmed → Preparing → Ready → Picked up / Served
```

| Step | Who |
|---|---|
| Place order | Customer (web / QR table), or Cashier/Manager at the counter, by phone or WhatsApp |
| Confirm | Cashier, Manager (or automatic — Settings) |
| Preparing, Ready | Kitchen, Manager |
| Assign rider | Manager (or a rider claims a ready order) |
| Out for delivery, Delivered (+ cash collected) | Rider (assigned), Manager |
| Hand over / Served, take payment | Cashier, Manager |
| Cancel (reason required) | Manager; Cashier only before cooking starts |
| Step back one step | Manager |

Rules are enforced on the **server** (`shared/orderFlow.ts` is the single source of truth, also used by the UI). Kitchen never sees customer phone/address; riders only see ready/unassigned or their own deliveries. Prices are always recalculated on the server.

Customers track at `/track` (order number + phone) or through the private link they get after ordering. The page polls every 8 s and shows ETA, progress, and the rider’s name/phone once out for delivery.

## Table QR codes

Print a QR for each table pointing to `https://YOUR-DOMAIN/order?table=7` (change 7). The table number is pre-filled and the kitchen sees it.

## Dish photos

Only **real photos** are used. 20 dishes (karahi, handi, tikka, gola and seekh kabab) already have the restaurant’s own photos; the other 102 show a neutral “Photo coming soon” tile until you add a photo.

Two ways to add them:

1. **Bulk:** put the photos in a folder, name each one with its dish number from `PHOTOS-NEEDED.csv` (e.g. `042.jpg` or `42-zinger-burger.jpg`), then run `npm run photos -- ./my-photos`, `npm run build`, and restart.
2. **One at a time, no rebuild:** Staff → Menu → edit dish → *Upload real photo* (resized in the browser, stored in `DATA_DIR/uploads`). “Use default picture” reverts.

Use photos you own or are licensed to use.

## Scripts

`npm run dev` · `npm run build` · `npm start` · `npm test` (API integration tests) · `npm run typecheck` · `npm run photos -- <folder>`

## Security notes

Passwords hashed with scrypt; sessions are random tokens stored hashed, in an httpOnly SameSite cookie; login and public forms are rate limited; cross-site writes are rejected; CSP and security headers in production; uploads are type-checked by content. Back up `DATA_DIR` regularly (SQLite file `fork-flame.db` + `uploads/`).
