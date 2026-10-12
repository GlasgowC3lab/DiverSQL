WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_promo_sk AS promo_sk,
        NULL AS call_center_sk,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        cs.cs_call_center_sk,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        NULL AS call_center_sk,
        'web' AS channel
    FROM web_sales ws
),
enriched_sales AS (
    SELECT
        us.*,
        d.d_year,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'UNKNOWN') || '-' || COALESCE(cd.cd_marital_status, 'UNKNOWN') AS demog_key,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name,
        COALESCE(cc.cc_name, 'N/A') AS call_center_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.date_sk = d.d_date_sk
    LEFT JOIN customer c ON us.customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON us.call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
),
agg_sales AS (
    SELECT
        es.channel,
        es.d_year,
        es.c_customer_id,
        es.c_first_name,
        es.c_last_name,
        es.demog_key,
        SUM(es.net_paid) AS total_paid,
        SUM(es.net_profit) AS total_profit,
        SUM(es.quantity) AS total_quantity,
        COUNT(DISTINCT es.item_sk) AS distinct_items,
        MAX(es.promo_name) AS promo_name,
        MAX(es.call_center_name) AS call_center_name,
        (SELECT AVG(u2.net_profit)
           FROM unified_sales u2
           JOIN date_dim d2 ON u2.date_sk = d2.d_date_sk
           WHERE d2.d_year = es.d_year
             AND u2.channel = es.channel) AS avg_net_profit_per_tx
    FROM enriched_sales es
    GROUP BY
        es.channel,
        es.d_year,
        es.c_customer_id,
        es.c_first_name,
        es.c_last_name,
        es.demog_key
),
ranked_sales AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank_year,
        CASE
            WHEN total_profit > 0 THEN 'profitable'
            WHEN total_profit < 0 THEN 'loss'
            ELSE 'zero'
        END AS profit_flag,
        CASE
            WHEN total_paid = 0 THEN 'N/A'
            WHEN total_profit / total_paid >= 0.2 THEN 'high_margin'
            ELSE 'low_margin'
        END AS margin_category,
        SUM(total_profit) OVER (PARTITION BY channel, d_year ORDER BY total_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_channel_year
    FROM agg_sales
)
SELECT
    channel,
    d_year,
    c_customer_id,
    c_first_name,
    c_last_name,
    demog_key,
    total_paid,
    total_profit,
    total_quantity,
    distinct_items,
    promo_name,
    call_center_name,
    ROUND(avg_net_profit_per_tx, 2) AS avg_net_profit_per_tx,
    profit_rank_year,
    profit_flag,
    margin_category,
    cum_profit_channel_year
FROM ranked_sales
WHERE total_profit >= 0 AND profit_rank_year <= 10

UNION ALL

SELECT
    channel,
    d_year,
    c_customer_id,
    c_first_name,
    c_last_name,
    demog_key,
    total_paid,
    total_profit,
    total_quantity,
    distinct_items,
    promo_name,
    call_center_name,
    ROUND(avg_net_profit_per_tx, 2) AS avg_net_profit_per_tx,
    profit_rank_year,
    profit_flag,
    margin_category,
    cum_profit_channel_year
FROM ranked_sales
WHERE total_profit < 0 AND profit_rank_year <= 5
ORDER BY d_year, channel, profit_rank_year
