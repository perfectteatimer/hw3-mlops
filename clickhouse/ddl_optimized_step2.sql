DROP TABLE IF EXISTS mv_transactions;

DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions
(
    transaction_time String,
    merch            String,
    cat_id           LowCardinality(String),
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           LowCardinality(String),
    street           String,
    one_city         String,
    us_state         LowCardinality(String),
    post_code        String,
    lat              Float64,
    lon              Float64,
    population_city  UInt32,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = MergeTree
PARTITION BY us_state
ORDER BY (us_state, amount)
SETTINGS
    index_granularity = 4096;

CREATE MATERIALIZED VIEW mv_transactions
TO transactions
AS
SELECT
    transaction_time,
    merch,
    cat_id,
    amount,
    name_1,
    name_2,
    gender,
    street,
    one_city,
    us_state,
    post_code,
    lat,
    lon,
    population_city,
    jobs,
    merchant_lat,
    merchant_lon,
    target
FROM transactions_kafka;
