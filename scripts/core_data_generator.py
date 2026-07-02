import os
from dotenv import load_dotenv
import psycopg2
from faker import Faker
from datetime import datetime, timedelta

load_dotenv()

faker = Faker()


def db_connect():
    conn = psycopg2.connect(
        host="localhost",
        database="ecom_db",
        user="admin",
        password="password",
        port="5433",
    )
    return conn


def db_init():
    conn = db_connect()
    cursor = conn.cursor()

    cursor.execute("""
                   CREATE TABLE IF NOT EXISTS orders(
                   order_id UUID PRIMARY KEY,
                   customer_id BIGINT NOT NULL,
                   order_date TIMESTAMP NOT NULL,
                   total_amount DECIMAL(10,2) NOT NULL,
                   currency VARCHAR(3) NOT NULL,
                   status VARCHAR(50) NOT NULL,
                   payment_method VARCHAR(50) NOT NULL
                   );
                   """)
    conn.commit()
    cursor.close()
    conn.close()
    print("table ready")


def generate_odrers(num_records=100):
    conn = db_connect()
    cursor = conn.cursor()
    target_date = datetime.now()
    day_start = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + (timedelta(days=1) - timedelta(seconds=1))

    for _ in range(num_records):
        order = (
            faker.uuid4(),
            faker.random_int(min=1, max=1000),
            faker.date_time_between_dates(
                datetime_start=day_start, datetime_end=day_end
            ),
            faker.random_number(digits=4) / 100,
            faker.currency_code(),
            faker.random_element(
                elements=("Pending", "Shipped", "Delivered", "Cancelled")
            ),
            faker.random_element(
                elements=("Credit Card", "PayPal", "Apple Pay", "Bank Transfer")
            ),
        )
        cursor.execute(
            "INSERT INTO orders (order_id,customer_id,order_date,total_amount,currency,status,payment_method) VALUES (%s,%s,%s,%s,%s,%s,%s) "
            "ON CONFLICT (order_id) DO NOTHING",
            order,
        )

    conn.commit()
    cursor.close()
    conn.close()
    print("Orders deployed")


db_init()
generate_odrers(100)
