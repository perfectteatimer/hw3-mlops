CREATE TABLE IF NOT EXISTS transactions_kafka
(
    transaction_time String,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        String,
    lat              Float64,
    lon              Float64,
    population_city  UInt32,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'redpanda:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse-consumer',
    kafka_format = 'CSV',
    kafka_row_delimiter = '\n',
    kafka_num_consumers = 1;
