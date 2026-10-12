WITH unified_sales AS (
    SELECT ss_customer_sk AS customer_sk,
           ss_sold_date_sk AS date_sk,
           'store' AS channel,
           ss_quantity AS quantity,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid
    FROM store_sales
    UNION ALL
    SELECT cs_bill_customer_sk AS customer_sk,
           cs_sold_date_sk AS date_sk,
           'catalog' AS channel,
           cs_quantity AS quantity,
           cs_net_profit AS net_profit,
           cs_net_paid AS net_paid
    FROM catalog_sales
    UNION ALL
    SELECT ws_bill_customer_sk AS customer_sk,
           ws_sold_date_sk AS date_sk,
           'web' AS channel,
           ws_quantity AS quantity,
           ws_net_profit AS net_profit,
           ws_net_paid AS net_paid
    FROM web_sales
),
monthly_sales AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        s.channel,
        s.customer_sk,
        SUM(s.quantity) AS total_quantity,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.net_paid) AS total_net_paid
    FROM unified_sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.channel,
        s.customer_sk
),
ranked_customers AS (
    SELECT
        ms.year,
        ms.month_seq,
        ms.channel,
        ms.customer_sk,
        ms.total_quantity,
        ms.total_net_profit,
        ms.total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ms.year, ms.month_seq, ms.channel ORDER BY ms.total_net_profit DESC) AS profit_rank,
        AVG(ms.total_net_profit) OVER (PARTITION BY ms.year, ms.month_seq, ms.channel ORDER BY ms.total_net_profit DESC ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS moving_avg_profit_5,
        SUM(ms.total_net_profit) OVER (PARTITION BY ms.year, ms.month_seq, ms.channel) AS channel_month_total_profit
    FROM monthly_sales ms
)
SELECT
    rc.year,
    rc.month_seq,
    rc.channel,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    rc.total_quantity,
    rc.total_net_profit,
    rc.total_net_paid,
    rc.channel_month_total_profit,
    rc.profit_rank,
    rc.moving_avg_profit_5
FROM ranked_customers rc
JOIN customer c ON rc.customer_sk = c.c_customer_sk
WHERE rc.profit_rank <= 10
ORDER BY rc.year, rc.month_seq, rc.channel, rc.profit_rank
