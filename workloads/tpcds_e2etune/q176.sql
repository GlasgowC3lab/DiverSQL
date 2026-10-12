WITH store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        r.r_reason_desc,
        (sr.sr_return_amt + sr.sr_return_tax + sr.sr_return_amt_inc_tax) AS total_return_amt,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_net_loss AS net_loss,
        sr.sr_customer_sk AS cust_sk,
        'store' AS channel
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_class,
        r.r_reason_desc,
        (wr.wr_return_amt + wr.wr_return_tax + wr.wr_return_amt_inc_tax) AS total_return_amt,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_net_loss AS net_loss,
        wr.wr_refunded_customer_sk AS cust_sk,
        'web' AS channel
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
),
combined AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
aggregated AS (
    SELECT
        channel,
        i_category,
        d_month_seq,
        SUM(total_return_amt) AS total_return_amount,
        AVG(total_return_amt) AS avg_return_amount,
        SUM(return_quantity) AS total_return_quantity,
        COUNT(DISTINCT cust_sk) AS distinct_customers
    FROM combined
    GROUP BY channel, i_category, d_month_seq
)
SELECT
    channel,
    i_category,
    d_month_seq,
    total_return_amount,
    avg_return_amount,
    total_return_quantity,
    distinct_customers,
    RANK() OVER (PARTITION BY channel ORDER BY total_return_amount DESC) AS amount_rank
FROM aggregated
ORDER BY channel, total_return_amount DESC
LIMIT 100
