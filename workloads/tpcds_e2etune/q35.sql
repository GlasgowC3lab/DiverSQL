WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        c.cd_credit_rating,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM store_sales ss
    JOIN customer_demographics c
        ON ss.ss_cdemo_sk = c.cd_demo_sk
    WHERE c.cd_credit_rating = 'Good'
      AND c.cd_gender = 'F'
      AND ss.ss_quantity > 0
    GROUP BY ss.ss_store_sk, c.cd_credit_rating
),
returns_agg AS (
    SELECT
        c.cd_credit_rating,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM web_returns wr
    JOIN customer_demographics c
        ON wr.wr_refunded_cdemo_sk = c.cd_demo_sk
    WHERE c.cd_credit_rating = 'Good'
      AND c.cd_gender = 'F'
    GROUP BY c.cd_credit_rating
)
SELECT
    s.s_store_id,
    s.s_state,
    sa.cd_credit_rating,
    sa.total_sales_profit,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    sa.total_transactions,
    COALESCE(ra.total_returns, 0) AS total_returns,
    RANK() OVER (ORDER BY (sa.total_sales_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON sa.cd_credit_rating = ra.cd_credit_rating
WHERE s.s_state = 'CA'
ORDER BY net_profit_after_returns DESC
LIMIT 20
