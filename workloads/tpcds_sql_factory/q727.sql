WITH catalog_customer AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel,
        SUM(cs.cs_net_paid_inc_tax) AS net_paid_inc_tax,
        SUM(cs.cs_net_profit) AS net_profit,
        w.w_state AS state,
        w.w_country AS country
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    GROUP BY cs.cs_bill_customer_sk, w.w_state, w.w_country
),
web_customer AS (
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        'web' AS channel,
        SUM(ws.ws_net_paid_inc_tax) AS net_paid_inc_tax,
        SUM(ws.ws_net_profit) AS net_profit,
        site.web_state AS state,
        site.web_country AS country
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    GROUP BY ws.ws_bill_customer_sk, site.web_state, site.web_country
),
combined AS (
    SELECT * FROM catalog_customer
    UNION ALL
    SELECT * FROM web_customer
)
SELECT
    customer_sk,
    channel,
    state,
    country,
    net_paid_inc_tax,
    net_profit,
    CASE WHEN net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    DENSE_RANK() OVER (PARTITION BY channel ORDER BY net_paid_inc_tax DESC) AS channel_rank,
    RANK() OVER (ORDER BY net_paid_inc_tax DESC) AS overall_rank
FROM combined
ORDER BY overall_rank
LIMIT 100
