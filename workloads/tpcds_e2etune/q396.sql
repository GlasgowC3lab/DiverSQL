WITH store AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_return_amt_inc_tax AS return_amt,
        sr.sr_net_loss AS net_loss,
        'store' AS channel
    FROM store_returns sr
),
web AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_return_amt_inc_tax AS return_amt,
        wr.wr_net_loss AS net_loss,
        'web' AS channel
    FROM web_returns wr
),
combined AS (
    SELECT * FROM store
    UNION ALL
    SELECT * FROM web
),
joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.channel,
        c.c_customer_sk,
        r.return_amt,
        r.net_loss
    FROM combined r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN customer c ON r.customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1960 AND 1985
      AND c.c_preferred_cust_flag = 'Y'
      AND d.d_year >= 2000
),
aggregated AS (
    SELECT
        d_year,
        d_month_seq,
        channel,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        SUM(return_amt) AS total_return_amount,
        SUM(net_loss) AS total_net_loss,
        AVG(return_amt) AS avg_return_amount
    FROM joined
    GROUP BY d_year, d_month_seq, channel
    HAVING SUM(return_amt) > 1000
)
SELECT
    d_year,
    d_month_seq,
    channel,
    distinct_customers,
    total_return_amount,
    total_net_loss,
    avg_return_amount,
    RANK() OVER (PARTITION BY channel ORDER BY total_return_amount DESC) AS channel_monthly_rank
FROM aggregated
ORDER BY d_year, d_month_seq, channel
