import os
import argparse
from kafka import KafkaProducer
from tqdm import tqdm


def stream_csv_to_kafka(csv_path, bootstrap_servers, topic):
    producer = KafkaProducer(
        bootstrap_servers=bootstrap_servers,
        value_serializer=lambda v: v.encode("utf-8"),
    )

    with open(csv_path, "r", encoding="utf-8") as f:
        header = f.readline()

        for line in tqdm(f, desc="sending rows"):
            line = line.rstrip("\n")
            if not line:
                continue
            producer.send(topic, line)

    producer.flush()
    producer.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--csv", default=os.getenv("CSV_PATH", "/data/train.csv"))
    parser.add_argument(
        "--bootstrap", default=os.getenv("KAFKA_BOOTSTRAP_SERVERS", "redpanda:9092")
    )
    parser.add_argument("--topic", default=os.getenv("KAFKA_TOPIC", "transactions"))
    args = parser.parse_args()

    if not os.path.exists(args.csv):
        raise FileNotFoundError(f"csv file not found: {args.csv}")

    stream_csv_to_kafka(args.csv, args.bootstrap, args.topic)


if __name__ == "__main__":
    main()
