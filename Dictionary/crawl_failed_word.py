import requests
import time
import psycopg2
from psycopg2.extras import execute_batch
from typing import Dict, Optional, List
import json

# ====================================
# BƯỚC 1: ĐỌC FAILED WORDS
# ====================================
print("📖 Reading failed words...")
try:
    with open('failed_words.txt', 'r') as f:
        failed_words = [line.strip() for line in f if line.strip()]
    print(f"✅ Found {len(failed_words)} failed words")
except FileNotFoundError:
    print("❌ File 'failed_words.txt' not found!")
    exit()

if not failed_words:
    print("🎉 No failed words to retry!")
    exit()

# ====================================
# BƯỚC 2: HÀM LẤY DỮ LIỆU - NHIỀU FALLBACK
# ====================================
session = requests.Session()


def get_word_data_v2(word: str) -> Optional[Dict]:
    """Version 2: Nhiều fallback strategies"""

    # Strategy 1: Dictionary API (primary)
    try:
        dict_url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
        dict_res = session.get(dict_url, timeout=15)

        if dict_res.status_code == 200:
            data = dict_res.json()[0]

            phonetic = data.get('phonetic', '')
            if not phonetic:
                for p in data.get('phonetics', []):
                    if p.get('text'):
                        phonetic = p['text']
                        break

            pos = None
            if data.get('meanings'):
                pos = data['meanings'][0].get('partOfSpeech')

            # Try Google Translate
            time.sleep(0.7)  # Longer delay for retry
            vi_meaning = ""

            try:
                trans_url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q={word}"
                trans_res = session.get(trans_url, timeout=10)
                if trans_res.status_code == 200:
                    trans_data = trans_res.json()
                    if trans_data and trans_data[0]:
                        vi_meaning = trans_data[0][0][0]
            except:
                pass

            # Fallback: Use English definition
            if not vi_meaning or vi_meaning == word:
                if data.get('meanings') and data['meanings'][0].get('definitions'):
                    vi_meaning = data['meanings'][0]['definitions'][0].get('definition', '')

            if vi_meaning:
                return {
                    'word': word,
                    'pos': pos,
                    'phonetic': phonetic,
                    'vi_meaning': vi_meaning[:500]
                }
    except:
        pass

    # Strategy 2: Alternative Translation API - MyMemory
    try:
        time.sleep(0.5)
        mymemory_url = f"https://api.mymemory.translated.net/get?q={word}&langpair=en|vi"
        mm_res = session.get(mymemory_url, timeout=10)

        if mm_res.status_code == 200:
            mm_data = mm_res.json()
            if mm_data.get('responseStatus') == 200:
                vi_meaning = mm_data['responseData']['translatedText']

                return {
                    'word': word,
                    'pos': None,
                    'phonetic': '',
                    'vi_meaning': vi_meaning[:500]
                }
    except:
        pass

    # Strategy 3: Wiktionary API
    try:
        time.sleep(0.5)
        wiki_url = f"https://en.wiktionary.org/api/rest_v1/page/definition/{word}"
        wiki_res = session.get(wiki_url, timeout=10)

        if wiki_res.status_code == 200:
            wiki_data = wiki_res.json()
            if 'en' in wiki_data:
                definitions = wiki_data['en']
                if definitions:
                    pos = definitions[0].get('partOfSpeech', '')
                    meaning = definitions[0]['definitions'][0]['definition']

                    # Remove HTML tags
                    import re
                    meaning = re.sub('<[^<]+?>', '', meaning)

                    return {
                        'word': word,
                        'pos': pos,
                        'phonetic': '',
                        'vi_meaning': f"[EN] {meaning[:500]}"
                    }
    except:
        pass

    # Strategy 4: Just save the word without meaning (placeholder)
    return {
        'word': word,
        'pos': None,
        'phonetic': '',
        'vi_meaning': f"[Pending translation]"
    }


# ====================================
# MAP POS
# ====================================
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
    "prep": "Giới từ"
}

# ====================================
# KẾT NỐI DB
# ====================================
conn = psycopg2.connect(
    dbname="flashcard_ai",
    user="postgres",
    password="123456",
    host="localhost",
    port=5432
)
cur = conn.cursor()

# ====================================
# RETRY LOGIC
# ====================================
success_count = 0
still_failed = []
results = []

print("\n🔄 Starting retry process...")
print("=" * 70)

for i, word in enumerate(failed_words, 1):
    data = get_word_data_v2(word)

    if data and data['vi_meaning'] != "[Pending translation]":
        results.append((
            data['word'],
            data['pos'],
            POS_MAP.get(data['pos'], ''),
            data['phonetic'],
            data['vi_meaning'],
            "api_retry"
        ))
        success_count += 1

        if i % 50 == 0:
            print(f"[{i}/{len(failed_words)}] ✅ {word} → {data['vi_meaning'][:30]}")
            print(f"   📊 Success: {success_count} | Still failed: {len(still_failed)}")
    else:
        still_failed.append(word)
        if i % 50 == 0:
            print(f"[{i}/{len(failed_words)}] ❌ Still failed: {word}")

    # Batch insert every 100 words
    if len(results) >= 100:
        try:
            execute_batch(cur, """
                               INSERT INTO dictionary
                                   (word, part_of_speech, part_of_speech_vi, phonetic, meanings, source)
                               VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT (word) DO
                               UPDATE SET
                                   meanings = EXCLUDED.meanings,
                                   part_of_speech = EXCLUDED.part_of_speech,
                                   phonetic = EXCLUDED.phonetic
                               """, results)
            conn.commit()
            print(f"   💾 Committed {len(results)} words")
            results = []
        except Exception as e:
            print(f"   ❌ DB Error: {e}")
            conn.rollback()
            results = []

# Final batch
if results:
    try:
        execute_batch(cur, """
                           INSERT INTO dictionary
                               (word, part_of_speech, part_of_speech_vi, phonetic, meanings, source)
                           VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT (word) DO
                           UPDATE SET
                               meanings = EXCLUDED.meanings
                           """, results)
        conn.commit()
        print(f"   💾 Committed final {len(results)} words")
    except Exception as e:
        print(f"   ❌ DB Error: {e}")

cur.close()
conn.close()

# ====================================
# KẾT QUẢ
# ====================================
print("\n" + "=" * 70)
print("🎉 RETRY COMPLETED!")
print("=" * 70)
print(f"✅ Recovered: {success_count}/{len(failed_words)} ({success_count / len(failed_words) * 100:.1f}%)")
print(f"❌ Still failed: {len(still_failed)}/{len(failed_words)} ({len(still_failed) / len(failed_words) * 100:.1f}%)")
print("=" * 70)

# Save still failed words
if still_failed:
    with open('still_failed_words.txt', 'w') as f:
        f.write('\n'.join(still_failed))
    print(f"\n💾 Saved {len(still_failed)} still-failed words to 'still_failed_words.txt'")
    print("\n📝 You can manually translate these words or use a paid API")
    print("   Example: DeepL API, Google Translate API (official)")
else:
    print("\n🎊 ALL WORDS RECOVERED! 100% SUCCESS!")

# Calculate total success rate
print(f"\n📊 OVERALL SUCCESS RATE:")
print(f"   Original: 8178/10000 (81.8%)")
print(f"   After retry: {8178 + success_count}/10000 ({(8178 + success_count) / 100:.1f}%)")