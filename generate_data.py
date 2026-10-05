"""
generate_data.py: schema.sql chalake ecommerce.db banata hai aur usme data bharta hai.

Run:  python generate_data.py
Output: ecommerce.db  (same folder mein)

Data synthetic hai (random, seed fixed), toh har baar same data banta hai.
Structure aur sizes guide jaise hain: 6 categories, 60 products, 2500 customers,
~7000 orders, ~12-13k order items, har order ka ek payment.
"""
import sqlite3, random, os
import datetime as dt

random.seed(42)
HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "ecommerce.db")
if os.path.exists(DB):
    os.remove(DB)

con = sqlite3.connect(DB)
con.executescript(open(os.path.join(HERE, "schema.sql"), encoding="utf-8").read())

# ---------------- categories ----------------
CATEGORIES = ["Electronics", "Fashion", "Home & Kitchen", "Beauty", "Grocery", "Books & Stationery"]
con.executemany("INSERT INTO categories VALUES (?,?)", list(enumerate(CATEGORIES, 1)))

# ---------------- products (10 per category, id 1-60) ----------------
# (name, brand, selling price, cost ratio)
PRODUCTS = [
    # Electronics 1-10
    ("Smartphone Nova X1", "Nova", 18999, .82), ("Laptop ProBook 14", "Zenith", 54999, .85),
    ("Wireless Earbuds AirBeat", "SoundPeak", 1999, .60), ("Bluetooth Speaker Boom", "SoundPeak", 2499, .62),
    ("Smartwatch FitPulse", "FitPulse", 3999, .65), ("Power Bank 20000mAh", "ChargeMax", 1799, .60),
    ("USB-C Fast Charger", "ChargeMax", 999, .45), ("Laptop Sleeve", "CarryPro", 899, .45),
    ("Phone Case Armor", "CarryPro", 399, .30), ("Wireless Mouse", "ClickPro", 699, .50),
    # Fashion 11-20
    ("Men's Cotton T-Shirt", "UrbanThread", 599, .50), ("Women's Kurti Set", "Ethnica", 1299, .50),
    ("Slim Fit Jeans", "DenimCo", 1799, .55), ("Running Shoes Stride", "StepUp", 2999, .60),
    ("Leather Wallet", "Craftsman", 799, .40), ("Cotton Saree", "Ethnica", 2499, .55),
    ("Winter Hoodie", "UrbanThread", 1499, .50), ("Aviator Sunglasses", "ShadeCo", 1199, .40),
    ("Formal Shirt", "UrbanThread", 999, .50), ("Backpack Urban 25L", "CarryPro", 1599, .50),
    # Home & Kitchen 21-30
    ("Mixer Grinder 750W", "HomeEase", 3499, .65), ("Non-stick Cookware Set", "HomeEase", 2199, .60),
    ("Air Fryer 4L", "CrispCook", 6999, .70), ("Electric Kettle 1.5L", "HomeEase", 1199, .60),
    ("Cotton Bedsheet Double", "SleepWell", 899, .45), ("Curtain Set 2pc", "SleepWell", 799, .45),
    ("Vacuum Flask 1L", "KeepCool", 699, .50), ("LED Desk Lamp", "BrightHome", 1099, .50),
    ("Dinner Set 24pc", "HomeEase", 1299, .55), ("Storage Containers Set", "KeepFresh", 599, .45),
    # Beauty 31-40
    ("Moisturizer", "GlowLab", 699, .40), ("Vitamin C Serum", "GlowLab", 599, .38),
    ("Sunscreen SPF50", "SunSafe", 549, .38), ("Matte Lipstick", "ColorPop", 449, .35),
    ("Face Wash Gel", "GlowLab", 299, .35), ("Argan Shampoo", "SilkyHair", 399, .40),
    ("Perfume Eau Fresh", "ScentCo", 1299, .45), ("Herbal Hair Oil", "SilkyHair", 249, .35),
    ("Kajal", "ColorPop", 149, .30), ("Body Lotion", "GlowLab", 349, .38),
    # Grocery 41-50
    ("Basmati Rice 5kg", "FarmFresh", 649, .82), ("Sunflower Oil 1L", "FarmFresh", 169, .85),
    ("Whole Wheat Atta 5kg", "FarmFresh", 289, .84), ("Masala Tea 500g", "ChaiHouse", 249, .75),
    ("Almonds 500g", "NutriBest", 549, .80), ("Toor Dal 1kg", "FarmFresh", 159, .85),
    ("Organic Honey 500g", "NutriBest", 399, .70), ("Ground Coffee 250g", "BeanBox", 349, .72),
    ("Rolled Oats 1kg", "NutriBest", 199, .78), ("Cashews 500g", "NutriBest", 599, .80),
    # Books & Stationery 51-60
    ("Notebook A4 Pack of 5", "PaperPlus", 299, .50), ("Gel Pen Set 10pc", "PaperPlus", 149, .45),
    ("SQL Made Easy", "LearnPress", 499, .55), ("Python Basics", "LearnPress", 599, .55),
    ("Desk Planner", "PaperPlus", 349, .50), ("Sketchbook A3", "ArtMate", 399, .50),
    ("Highlighter Set 6pc", "PaperPlus", 179, .45), ("Data Analysis Handbook", "LearnPress", 699, .55),
    ("Sticky Notes Pack", "PaperPlus", 99, .40), ("Geometry Box", "PaperPlus", 199, .50),
]
assert len(PRODUCTS) == 60
rows = []
for pid, (name, brand, price, ratio) in enumerate(PRODUCTS, 1):
    rows.append((pid, name, (pid - 1) // 10 + 1, brand, float(price), round(price * ratio, 2)))
con.executemany("INSERT INTO products VALUES (?,?,?,?,?,?)", rows)
PRICE = {r[0]: r[4] for r in rows}

# ---------------- customers ----------------
CITIES = {  # city: (state, region, weight)
    "Delhi": ("Delhi", "North", 14), "Mumbai": ("Maharashtra", "West", 14),
    "Bengaluru": ("Karnataka", "South", 13), "Hyderabad": ("Telangana", "South", 9),
    "Chennai": ("Tamil Nadu", "South", 8), "Kolkata": ("West Bengal", "East", 8),
    "Pune": ("Maharashtra", "West", 8), "Ahmedabad": ("Gujarat", "West", 6),
    "Jaipur": ("Rajasthan", "North", 5), "Lucknow": ("Uttar Pradesh", "North", 4),
    "Chandigarh": ("Chandigarh", "North", 3), "Guwahati": ("Assam", "East", 3),
    "Patna": ("Bihar", "East", 3), "Kochi": ("Kerala", "South", 2),
}
FIRST = ["Aarav", "Vivaan", "Aditya", "Arjun", "Rohan", "Rahul", "Amit", "Nikhil", "Karan", "Sahil",
         "Priya", "Neha", "Anjali", "Kavya", "Meera", "Pooja", "Sneha", "Riya", "Divya", "Aditi",
         "Harpreet", "Simran", "Isha", "Tanvi", "Deepak", "Manish", "Suresh", "Vikram", "Ananya", "Shreya"]
LAST = ["Sharma", "Verma", "Patel", "Singh", "Gupta", "Khan", "Rao", "Nair", "Bose", "Iyer", "Reddy",
        "Mehta", "Joshi", "Kapoor", "Das", "Mishra", "Yadav", "Chatterjee", "Menon", "Shah"]

# guide mein dikhaye gaye pehle 8 customers (same naam / city / signup)
KNOWN = {
    1: ("Harpreet", "Rao", "Guwahati", "2024-08-12"), 2: ("Nikhil", "Verma", "Bengaluru", "2024-08-22"),
    3: ("Aditi", "Patel", "Chennai", "2025-02-14"),    4: ("Rahul", "Bose", "Jaipur", "2024-11-18"),
    5: ("Kavya", "Khan", "Chandigarh", "2025-10-20"),  6: ("Sahil", "Gupta", "Pune", "2024-09-05"),
    7: ("Meera", "Nair", "Hyderabad", "2024-10-10"),   8: ("Pooja", "Khan", "Mumbai", "2025-01-08"),
}
N_CUST = 2500
city_names = list(CITIES)
city_w = [CITIES[c][2] for c in city_names]
signup_lo, signup_hi = dt.date(2023, 1, 1), dt.date(2025, 10, 31)

cust_rows, signup, region_of = [], {}, {}
for cid in range(1, N_CUST + 1):
    if cid in KNOWN:
        fn, ln, city, sd = KNOWN[cid]
        sdate = dt.date.fromisoformat(sd)
    else:
        fn, ln = random.choice(FIRST), random.choice(LAST)
        city = random.choices(city_names, city_w)[0]
        sdate = signup_lo + dt.timedelta(days=random.randint(0, (signup_hi - signup_lo).days))
    state, region, _ = CITIES[city]
    cust_rows.append((cid, f"{fn} {ln}", f"{fn.lower()}.{ln.lower()}{cid}@example.com",
                      city, state, region, sdate.isoformat()))
    signup[cid], region_of[cid] = sdate, region
con.executemany("INSERT INTO customers VALUES (?,?,?,?,?,?,?)", cust_rows)

# ---------------- orders, items, payments ----------------
START, END = dt.date(2024, 1, 1), dt.date(2025, 12, 31)
NDAYS = (END - START).days + 1
day_w = []                      # kaunse din zyada orders (festive Oct/Nov, weekend, growth)
for i in range(NDAYS):
    d = START + dt.timedelta(days=i)
    w = 1 + 0.6 * i / NDAYS
    if d.month in (10, 11): w *= 1.8
    elif d.month == 12:     w *= 1.2
    elif d.month in (1, 2): w *= 0.85
    if d.weekday() >= 5:    w *= 1.15
    day_w.append(w)

METHODS = ["UPI", "Card", "NetBanking", "Wallet", "COD"]
METHOD_W = [38, 22, 12, 10, 18]
DISCOUNTS = [0, 0, 0, 0, 5, 10, 10, 15, 20, 30]
REGION_DAYS = {"North": 3.2, "South": 3.0, "West": 2.6, "East": 4.5}
PIDS = list(range(1, 61))
POP = [1 / (PRICE[p] ** 0.35) for p in PIDS]          # sasti cheezein zyada bikti hain
BUNDLES = [(51, 52), (8, 9), (3, 9), (41, 42), (31, 35), (11, 13)]
BUNDLE_W = [6, 2, 2, 2, 2, 2]                          # Notebook + Gel Pen sabse zyada saath

order_rows, item_rows, pay_rows = [], [], []
order_id, item_id = 1000, 1

for cid in range(1, N_CUST + 1):
    if cid in (1, 5):                                  # guide: in dono ka koi order nahi
        n = 0
    else:
        n = 0 if random.random() < 0.12 else min(15, 1 + int(random.expovariate(1 / 2.7)))
    if n == 0:
        continue
    start_idx = min(max(0, (signup[cid] - START).days) + random.randint(0, 30), NDAYS - 1)
    idxs = sorted(random.choices(range(start_idx, NDAYS), weights=day_w[start_idx:], k=n))

    for idx in idxs:
        d = START + dt.timedelta(days=idx)
        method = random.choices(METHODS, METHOD_W)[0]
        festive = d.month in (10, 11)
        n_items = random.choices([1, 2, 3, 4], [35, 35, 20, 10] if festive else [50, 30, 15, 5])[0]

        basket = {}
        if random.random() < 0.12:
            a, b = random.choices(BUNDLES, BUNDLE_W)[0]
            basket[a], basket[b] = random.choice([1, 1, 2]), random.choice([1, 1, 2])
        while len(basket) < n_items:
            pid = random.choices(PIDS, POP)[0]
            if pid not in basket:
                basket[pid] = random.choices([1, 2, 3], [65, 25, 10])[0]

        first_cat = (next(iter(basket)) - 1) // 10 + 1
        cancel_p = 0.146 if method == "COD" else 0.06
        ret_p = {2: 0.12, 1: 0.07}.get(first_cat, 0.03)   # Fashion / Electronics mein zyada returns
        r = random.random()
        status = "Cancelled" if r < cancel_p else "Returned" if r < cancel_p + ret_p else "Delivered"
        days = None if status == "Cancelled" else max(1, min(10, round(random.gauss(REGION_DAYS[region_of[cid]], 1.3))))

        total = 0.0
        for pid, qty in basket.items():
            disc = random.choice(DISCOUNTS)
            item_rows.append((item_id, order_id, pid, qty, PRICE[pid], disc))
            total += round(qty * PRICE[pid] * (1 - disc / 100), 2)
            item_id += 1

        pstatus = {"Delivered": "Paid", "Cancelled": "Voided", "Returned": "Refunded"}[status]
        order_rows.append((order_id, cid, d.isoformat(), status, days))
        pay_rows.append((order_id, order_id, method, round(total, 2), pstatus))
        order_id += 1

con.executemany("INSERT INTO orders VALUES (?,?,?,?,?)", order_rows)
con.executemany("INSERT INTO order_items VALUES (?,?,?,?,?,?)", item_rows)
con.executemany("INSERT INTO payments VALUES (?,?,?,?,?)", pay_rows)
con.commit()

print("ecommerce.db ban gaya:", DB)
for t in ["categories", "products", "customers", "orders", "order_items", "payments"]:
    print(f"  {t:12s} {con.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]:>6,} rows")
con.close()
