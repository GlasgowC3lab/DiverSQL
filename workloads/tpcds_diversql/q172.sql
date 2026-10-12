WITH store_keys AS (
    SELECT c.c_customer_sk, i.i_item_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_return_amt > (SELECT avg(sr2.sr_return_amt) FROM store_returns sr2)
),
web_keys AS (
    SELECT c.c_customer_sk, i.i_item_sk
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > (SELECT avg(wr2.wr_return_amt) FROM web_returns wr2)
),
common_keys AS (
    SELECT c_customer_sk, i_item_sk
    FROM store_keys
    INTERSECT
    SELECT c_customer_sk, i_item_sk
    FROM web_keys
),
store_agg AS (
    SELECT sr.sr_customer_sk AS c_customer_sk,
           sr.sr_item_sk AS i_item_sk,
           SUM(sr.sr_return_amt) AS store_return_amt
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk, sr.sr_item_sk
),
web_agg AS (
    SELECT wr.wr_refunded_customer_sk AS c_customer_sk,
           wr.wr_item_sk AS i_item_sk,
           SUM(wr.wr_return_amt) AS web_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_refunded_customer_sk, wr.wr_item_sk
)
SELECT
    c.c_customer_id,
    c.c_customer_sk,
    c.ca_state,
    c.i_item_id,
    c.total_return_amt,
    c.rn
FROM (
    SELECT
        ca.c_customer_id,
        ca.c_customer_sk,
        ca_addr.ca_state,
        i.i_item_id,
        (sa.store_return_amt + wa.web_return_amt) AS total_return_amt,
        row_number() OVER (PARTITION BY ca_addr.ca_state ORDER BY (sa.store_return_amt + wa.web_return_amt) DESC) AS rn
    FROM common_keys ck
    JOIN store_agg sa ON ck.c_customer_sk = sa.c_customer_sk AND ck.i_item_sk = sa.i_item_sk
    JOIN web_agg wa ON ck.c_customer_sk = wa.c_customer_sk AND ck.i_item_sk = wa.i_item_sk
    JOIN customer ca ON ck.c_customer_sk = ca.c_customer_sk
    JOIN customer_address ca_addr ON ca.c_current_addr_sk = ca_addr.ca_address_sk
    JOIN item i ON ck.i_item_sk = i.i_item_sk
) c
WHERE c.rn <= 5
ORDER BY c.ca_state, c.total_return_amt DESC
