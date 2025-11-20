CREATE MATERIALIZED VIEW IF NOT EXISTS mv_transactions
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
