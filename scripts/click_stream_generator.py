from faker import Faker
from datetime import datetime, timedelta
import json
import psycopg2
import random

faker = Faker()


def db_connect():
    conn = psycopg2.connect(
        host="postgres_db",
        database="ecom_db",
        user="admin",
        password="password",
        port="5432",
    )
    return conn


def get_todays_customer_info():
    conn = db_connect()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT customer_id, order_date FROM orders WHERE order_date::date = CURRENT_DATE"
    )
    customer_info = [
        {"customer_id": row[0], "order_date": row[1]} for row in cursor.fetchall()
    ]

    cursor.close()
    conn.close()
    return customer_info


def generate_click_events(customer_info):

    today = datetime.now()
    day_start = today.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + (timedelta(days=1) - timedelta(seconds=1))

    events = []
    # ci co coś kupili
    for i in customer_info:
        num_events = random.randint(2, 10)
        device = faker.random_element(elements=("mobile", "desktop", "tablet"))
        actions = ["page_view", "add_to_cart", "remove_from_cart", "checkout", "login"]
        total_minutes = num_events * 5  # bo 5 to maksymalny czas
        first_click = i["order_date"] - timedelta(minutes=total_minutes)

        # zeby nie wychodzilo poza dzien
        if first_click < day_start:
            first_click = day_start

        current_time = first_click
        for _ in range(num_events):
            current_time += timedelta(minutes=random.randint(1, 5))
            event = {
                "event_id": f"event-{faker.random_number(digits=5)}",
                "user_id": i["customer_id"],
                "event_type": random.choice(actions),
                "timestamp": current_time.isoformat() + "Z",
                "event_date": today.strftime("%Y-%m-%d"),
                "device": device,
            }
            events.append(event)

    # ghost users
    for _ in range(100):
        current_time = faker.date_time_between_dates(
            datetime_start=day_start, datetime_end=day_end
        )
        num_events = random.randint(2, 10)
        device = faker.random_element(elements=("mobile", "desktop", "tablet"))
        actions = ["page_view", "add_to_cart", "remove_from_cart", "login"]
        customer_id = random.randint(101, 500)

        for _ in range(num_events):
            if current_time >= day_end:
                break

            current_time += timedelta(minutes=random.randint(1, 5))
            event = {
                "event_id": f"event-{faker.random_number(digits=5)}",
                "user_id": customer_id,
                "event_type": random.choice(actions),
                "timestamp": current_time.isoformat() + "Z",
                "event_date": today.strftime("%Y-%m-%d"),
                "device": device,
            }
            events.append(event)
    events.sort(key=lambda x: x["timestamp"])
    return events


customers = get_todays_customer_info()
events = generate_click_events(customers)


file_name = f"clickstream_{datetime.now().strftime('%Y%m%d')}.json"
file_path = f"/opt/data/logs/{file_name}"

with open(file_path, "w") as f:
    json.dump(events, f, indent=4)

print("json generated")
