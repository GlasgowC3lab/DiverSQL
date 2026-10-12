WITH store_agg AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        'store' AS return_source,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id, c.c_birth_country
),
web_agg AS (
    SELECT
        c.c_customer_id,
        c.c_birth_country,
        wp.wp_type AS return_source,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450900 AND 2451100
      AND c.c_preferred_cust_flag = 'Y'
      AND wp.wp_type IS NOT NULL
    GROUP BY c.c_customer_id, c.c_birth_country, wp.wp_type
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    comb.c_customer_id,
    comb.c_birth_country,
    comb.return_source,
    comb.total_net_loss,
    comb.total_return_qty,
    comb.avg_return_amt_inc_tax,
    ROW_NUMBER() OVER (PARTITION BY comb.return_source ORDER BY comb.total_net_loss DESC) AS source_customer_rank,
    SUM(comb.total_net_loss) OVER (PARTITION BY comb.return_source ORDER BY comb.total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_loss
FROM combined comb
WHERE comb.total_net_loss > 0
ORDER BY comb.total_net_loss DESC
LIMIT 100
