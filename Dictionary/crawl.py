import requests
import time
import psycopg2
from psycopg2.extras import execute_batch
from typing import Dict, Optional
from concurrent.futures import ThreadPoolExecutor, as_completed
import threading
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry


# ====================================
# SETUP SESSION VỚI RETRY
# ====================================
def create_session():
    """Tạo session với retry logic"""
    session = requests.Session()
    retry = Retry(
        total=3,
        backoff_factor=0.5,
        status_forcelist=[429, 500, 502, 503, 504]
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session


# Thread-local storage cho session
thread_local = threading.local()


def get_session():
    if not hasattr(thread_local, 'session'):
        thread_local.session = create_session()
    return thread_local.session


# ====================================
# BƯỚC 1: TẢI DANH SÁCH 10K TỪ
# ====================================
print("📥 Downloading 10,000 words list...")
# https://github.com/first20hours/google-10000-english
# url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa.txt"
# url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
# url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears-short.txt"
# url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears-medium.txt"
# url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt"
url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english.txt"

response = requests.get(url)

if response.status_code != 200:
    print("❌ Cannot download word list")
    exit()

words_to_crawl = response.text.strip().split('\n')
print(f"✅ Loaded {len(words_to_crawl)} words")


# ====================================
# BƯỚC 2: HÀM LẤY DỮ LIỆU (IMPROVED)
# ====================================
def get_word_data(word: str) -> Optional[Dict]:
    """Lấy phonetic, POS, nghĩa tiếng Việt với error handling tốt hơn"""
    session = get_session()

    try:
        # 1. API Dictionary
        dict_url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
        dict_res = session.get(dict_url, timeout=15)

        if dict_res.status_code != 200:
            return None

        data = dict_res.json()
        if not data or not isinstance(data, list):
            return None

        data = data[0]

        # Lấy phonetic
        phonetic = data.get('phonetic', '')
        if not phonetic:
            for p in data.get('phonetics', []):
                if p.get('text'):
                    phonetic = p['text']
                    break

        # Lấy POS
        pos = None
        if data.get('meanings'):
            pos = data['meanings'][0].get('partOfSpeech')

        # 2. API Translation (với delay và fallback)
        time.sleep(0.3)  # Tăng delay để tránh rate limit

        vi_meaning = ""
        try:
            # Method 1: Google Translate (unofficial)
            trans_url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=vi&dt=t&q={word}"
            trans_res = session.get(trans_url, timeout=10)

            if trans_res.status_code == 200:
                trans_data = trans_res.json()
                if trans_data and trans_data[0] and trans_data[0][0]:
                    vi_meaning = trans_data[0][0][0]
        except:
            # Fallback: Lấy definition tiếng Anh
            if data.get('meanings') and data['meanings'][0].get('definitions'):
                vi_meaning = data['meanings'][0]['definitions'][0].get('definition', '')[:200]

        # Validate kết quả
        if not vi_meaning or vi_meaning == word:
            return None

        return {
            'word': word,
            'pos': pos,
            'phonetic': phonetic,
            'vi_meaning': vi_meaning
        }

    except requests.exceptions.Timeout:
        return None
    except requests.exceptions.RequestException:
        return None
    except (KeyError, IndexError, TypeError, ValueError):
        return None
    except Exception as e:
        print(f"   ⚠️  Unexpected error for '{word}': {str(e)[:50]}")
        return None


# ====================================
# BƯỚC 3: MAP POS
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
# BƯỚC 4: KẾT NỐI DB
# ====================================
conn = psycopg2.connect(
    dbname="flashcard_ai",
    user="postgres",
    password="123456",
    host="localhost",
    port=5432
)
cur = conn.cursor()

# Thread-safe counters
lock = threading.Lock()
success_count = 0
failed_count = 0
processed_count = 0
failed_words = []  # Track failed words

# Buffer để batch insert
insert_buffer = []
BATCH_SIZE = 50  # Giảm xuống để commit thường xuyên hơn


# ====================================
# BƯỚC 5: HÀM XỬ LÝ 1 TỪ
# ====================================
def process_word(word: str, index: int, total: int):
    """Crawl và lưu 1 từ"""
    global success_count, failed_count, processed_count, insert_buffer, failed_words

    # Fetch data
    data = get_word_data(word)

    with lock:
        processed_count += 1

        if not data:
            failed_count += 1
            failed_words.append(word)
            if processed_count % 100 == 0:
                progress = processed_count / total * 100
                print(f"[{processed_count}/{total}] ({progress:.1f}%) ❌ Failed: {failed_count}")
            return

        # Thêm vào buffer
        insert_buffer.append((
            data['word'],
            data['pos'],
            POS_MAP.get(data['pos'], ''),
            data['phonetic'],
            data['vi_meaning'],
            "api"
        ))

        success_count += 1

        # Progress update
        if processed_count % 100 == 0:
            progress = processed_count / total * 100
            success_rate = success_count / processed_count * 100
            print(f"[{processed_count}/{total}] ({progress:.1f}%) ✅ {word} → {data['vi_meaning'][:30]}")
            print(f"   📊 Success: {success_count} ({success_rate:.1f}%) | Failed: {failed_count}")

        # Batch insert khi buffer đầy
        if len(insert_buffer) >= BATCH_SIZE:
            flush_buffer()


# ====================================
# BƯỚC 6: HÀM BATCH INSERT
# ====================================
def flush_buffer():
    """Insert batch vào DB"""
    global insert_buffer

    if not insert_buffer:
        return

    try:
        execute_batch(cur, """
                           INSERT INTO dictionary
                               (word, part_of_speech, part_of_speech_vi, phonetic, meanings, source)
                           VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT (word) DO NOTHING
                           """, insert_buffer)

        conn.commit()
        print(f"   💾 Committed {len(insert_buffer)} words to DB")
        insert_buffer = []

    except Exception as e:
        print(f"   ❌ DB Batch Error: {e}")
        conn.rollback()
        insert_buffer = []


# ====================================
# BƯỚC 7: CRAWL VỚI MULTITHREADING
# ====================================
start_time = time.time()
MAX_WORKERS = 5  # GIẢM XUỐNG để tránh rate limit

print(f"\n🚀 Starting multithreaded crawl with {MAX_WORKERS} workers...")
print(f"📚 Total words: {len(words_to_crawl)}")
print("=" * 70)

with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
    # Submit tất cả tasks
    futures = {
        executor.submit(process_word, word, i, len(words_to_crawl)): word
        for i, word in enumerate(words_to_crawl, 1)
    }

    # Chờ hoàn thành
    for future in as_completed(futures):
        word = futures[future]
        try:
            future.result()
        except Exception as e:
            with lock:
                failed_count += 1
                failed_words.append(word)
                print(f"❌ Exception for '{word}': {str(e)[:50]}")

# Flush buffer cuối cùng
flush_buffer()

cur.close()
conn.close()

# ====================================
# THỐNG KÊ
# ====================================
total_time = time.time() - start_time
success_rate = success_count / len(words_to_crawl) * 100

print("\n" + "=" * 70)
print("🎉 CRAWL COMPLETED!")
print("=" * 70)
print(f"✅ Success: {success_count}/{len(words_to_crawl)} ({success_rate:.1f}%)")
print(f"❌ Failed: {failed_count}/{len(words_to_crawl)} ({failed_count / len(words_to_crawl) * 100:.1f}%)")
print(f"⏱️  Total time: {total_time / 60:.1f} minutes ({total_time:.0f} seconds)")
print(f"📊 Average rate: {len(words_to_crawl) / total_time:.2f} words/sec")
print("=" * 70)

# Lưu failed words vào file để retry sau
if failed_words:
    with open('failed_words.txt', 'w') as f:
        f.write('\n'.join(failed_words))
    print(f"\n💾 Saved {len(failed_words)} failed words to 'failed_words.txt'")
    print("   You can retry these words later with a separate script")