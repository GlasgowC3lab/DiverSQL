WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_sales_price AS ext_sales_price,
        'Catalog' AS sales_channel,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS org_id,
        'Call_Center' AS org_type
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        'Store',
        ss.ss_promo_sk,
        ss.ss_store_sk,
        'Store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        'Web',
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        'Web_Site'
    FROM web_sales ws
),
sales_with_dims AS (
    SELECT
        u.sold_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        u.sales_channel,
        u.item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_color,
        u.net_profit,
        u.ext_sales_price,
        u.promo_sk,
        p.p_promo_name,
        COALESCE(st.s_store_name, cc.cc_name, ws_dim.web_name) AS sales_location_name
    FROM unified_sales u
    LEFT JOIN date_dim d ON u.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON u.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON u.promo_sk = p.p_promo_sk
    LEFT JOIN store st ON u.org_type = 'Store' AND u.org_id = st.s_store_sk
    LEFT JOIN call_center cc ON u.org_type = 'Call_Center' AND u.org_id = cc.cc_call_center_sk
    LEFT JOIN web_site ws_dim ON u.org_type = 'Web_Site' AND u.org_id = ws_dim.web_site_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
),
daily_agg AS (
    SELECT
        d_date,
        d_year,
        d_month_seq,
        d_day_name,
        sales_channel,
        i_item_id,
        i_brand,
        i_category,
        i_color,
        item_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_cnt,
        AVG(net_profit) AS avg_net_profit,
        CONCAT_WS('|', COALESCE(i_brand, ''), COALESCE(i_category, ''), COALESCE(i_color, '')) AS item_desc_key,
        COALESCE(p_promo_name, 'NoPromo') AS promo_name,
        sales_location_name,
        CASE WHEN SUM(net_profit) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_status,
        (SELECT AVG(inner_s.net_profit)
         FROM (
             SELECT cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit, cs.cs_sold_date_sk AS sold_date_sk
             FROM catalog_sales cs
             UNION ALL
             SELECT ss.ss_item_sk, ss.ss_net_profit, ss.ss_sold_date_sk
             FROM store_sales ss
             UNION ALL
             SELECT ws.ws_item_sk, ws.ws_net_profit, ws.ws_sold_date_sk
             FROM web_sales ws
         ) inner_s
         JOIN date_dim inner_d ON inner_s.sold_date_sk = inner_d.d_date_sk
         WHERE inner_s.item_sk = item_sk
           AND inner_d.d_year = d_year - 1) AS prior_year_avg_net_profit
    FROM sales_with_dims
    GROUP BY
        d_date,
        d_year,
        d_month_seq,
        d_day_name,
        sales_channel,
        i_item_id,
        i_brand,
        i_category,
        i_color,
        item_sk,
        p_promo_name,
        sales_location_name
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_date, sales_channel ORDER BY total_net_profit DESC) AS channel_daily_rank
    FROM daily_agg
)
SELECT
    d_date,
    d_year,
    d_month_seq,
    d_day_name,
    sales_channel,
    i_item_id,
    total_net_profit,
    total_sales,
    transaction_cnt,
    avg_net_profit,
    prior_year_avg_net_profit,
    profit_status,
    item_desc_key,
    promo_name,
    sales_location_name,
    channel_daily_rank
FROM ranked
WHERE channel_daily_rank <= 5
ORDER BY d_date, sales_channel, total_net_profit DESC
