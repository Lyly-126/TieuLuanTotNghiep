import json
import psycopg2

EN_FILE = "data/simple-extract.jsonl"
VI_FILE = "data/vi.jsonl"

POS_MAP = {
    "noun": "Danh từ",
    "verb": "Động từ",
    "adjective": "Tính từ",
    "adverb": "Trạng từ",
    "pronoun": "Đại từ",
    "preposition": "Giới từ",
    "conjunction": "Liên từ",
    "interjection": "Thán từ",
    "determiner": "Từ hạn định",
    "name": "Danh từ",
    "adj": "Tính từ",
    "adv": "Trạng từ"
}

# =====================
# 1️⃣ LOAD EN DATA
# =====================
print("🔄 Loading EN dictionary...")
en_dict = {}

with open(EN_FILE, encoding="utf-8") as f:
    for line in f:
        obj = json.loads(line)
        word = obj.get("word")
        if not word:
            continue
        en_dict[word.lower()] = obj

print(f"✅ Loaded EN words: {len(en_dict)}")

# =====================
# 2️⃣ CONNECT DB
# =====================
conn = psycopg2.connect(
    dbname="flashcard_ai",
    user="postgres",
    password="123456",
    host="localhost",
    port=5432
)
cur = conn.cursor()

# =====================
# 3️⃣ MERGE + INSERT
# =====================
print("🚀 Start merging & inserting...")
count = 0
commit_batch = 1000  # commit mỗi 1000 từ cho nhẹ DB

with open(VI_FILE, encoding="utf-8") as f:
    for line in f:
        vi = json.loads(line)

        translations = vi.get("translations", [])
        en_word = None

        for t in translations:
            if t.get("lang_code") == "en":
                en_word = t.get("word")
                break

        if not en_word:
            continue

        en = en_dict.get(en_word.lower())
        if not en:
            continue

        # EN
        pos_en = en.get("pos")
        definitions = []
        for s in en.get("senses", []):
            definitions.extend(s.get("glosses", []))

        phonetic = None
        for s in en.get("sounds", []):
            if "ipa" in s:
                phonetic = s["ipa"]
                break

        # VI
        meanings = [vi.get("word")]

        try:
            cur.execute("""
                        INSERT INTO dictionary
                        (word, part_of_speech, part_of_speech_vi, phonetic, definitions, meanings, source)
                        VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (word) DO NOTHING
                        """, (
                            en_word,
                            pos_en,
                            POS_MAP.get(pos_en),
                            phonetic,
                            "; ".join(definitions),  # List → Text, ngăn cách bằng ";"
                            ", ".join(meanings),  # List → Text, ngăn cách bằng ","
                            "vi+en"
                        ))

            count += 1

            if count % commit_batch == 0:
                conn.commit()
                print(f"✅ Inserted {count} words...")

        except Exception as e:
            print("❌ Error at word:", en_word, e)

# FINAL COMMIT
conn.commit()
cur.close()
conn.close()

print(f"🎉 DONE: imported {count} words total")
