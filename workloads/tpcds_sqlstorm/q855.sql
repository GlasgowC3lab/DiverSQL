WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_call_center_sk AS channel_id,
        'catalog' AS channel_type
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_store_sk,
        'store' AS channel_type
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_web_site_sk,
        'web' AS channel_type
    FROM web_sales ws
),
channel_details AS (
    SELECT
        cc.cc_call_center_sk AS channel_id,
        cc.cc_name AS channel_name,
        'catalog' AS channel_type
    FROM call_center cc
    UNION ALL
    SELECT
        s.s_store_sk,
        s.s_store_name,
        'store' AS channel_type
    FROM store s
    UNION ALL
    SELECT
        ws.web_site_sk,
        ws.web_name,
        'web' AS channel_type
    FROM web_site ws
),
filtered_sales AS (
    SELECT
        us.sold_date_sk,
        us.item_sk,
        us.promo_sk,
        us.quantity,
        us.net_paid,
        us.net_profit,
        us.channel_id,
        us.channel_type,
        cd.channel_name,
        d.d_date,
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        p.p_promo_name,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Y' ELSE 'N' END AS promo_active
    FROM unified_sales us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
    JOIN channel_details cd ON us.channel_id = cd.channel_id AND us.channel_type = cd.channel_type
    WHERE d.d_year BETWEEN 2000 AND 2002
),
quarterly_agg AS (
    SELECT
        d_year,
        d_quarter_seq,
        channel_type,
        channel_name,
        i_category,
        i_brand,
        SUM(quantity) AS total_quantity,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        AVG(net_profit / NULLIF(net_paid, 0)) AS avg_profit_margin,
        SUM(CASE WHEN promo_active = 'Y' THEN net_profit ELSE 0 END) AS promo_net_profit
    FROM filtered_sales
    GROUP BY d_year, d_quarter_seq, channel_type, channel_name, i_category, i_brand
),
quarterly_with_lag AS (
    SELECT
        *,
        LAG(total_net_profit) OVER (PARTITION BY channel_type, i_category, i_brand ORDER BY d_year, d_quarter_seq) AS prev_net_profit,
        LAG(total_net_paid) OVER (PARTITION BY channel_type, i_category, i_brand ORDER BY d_year, d_quarter_seq) AS prev_net_paid
    FROM quarterly_agg
),
quarterly_growth AS (
    SELECT
        d_year,
        d_quarter_seq,
        channel_type,
        channel_name,
        i_category,
        i_brand,
        total_quantity,
        total_net_paid,
        total_net_profit,
        avg_profit_margin,
        promo_net_profit,
        CASE
            WHEN prev_net_profit IS NOT NULL AND prev_net_profit <> 0
            THEN (total_net_profit - prev_net_profit) / prev_net_profit
            ELSE NULL
        END AS net_profit_qoq_growth,
        CASE
            WHEN prev_net_paid IS NOT NULL AND prev_net_paid <> 0
            THEN (total_net_paid - prev_net_paid) / prev_net_paid
            ELSE NULL
        END AS net_paid_qoq_growth
    FROM quarterly_with_lag
),
top_products AS (
    SELECT
        d_year,
        d_quarter_seq,
        channel_type,
        i_product_name,
        total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq, channel_type ORDER BY total_net_profit DESC) AS rn
    FROM (
        SELECT
            d_year,
            d_quarter_seq,
            channel_type,
            i_product_name,
            SUM(net_profit) AS total_net_profit
        FROM filtered_sales
        GROUP BY d_year, d_quarter_seq, channel_type, i_product_name
    ) prod
)
SELECT
    qg.d_year,
    qg.d_quarter_seq,
    qg.channel_type,
    qg.channel_name,
    qg.i_category,
    qg.i_brand,
    qg.total_quantity,
    qg.total_net_paid,
    qg.total_net_profit,
    qg.avg_profit_margin,
    qg.promo_net_profit,
    qg.net_profit_qoq_growth,
    qg.net_paid_qoq_growth,
    tp.i_product_name AS top_product,
    tp.total_net_profit AS top_product_profit
FROM quarterly_growth qg
LEFT JOIN (
    SELECT
        d_year,
        d_quarter_seq,
        channel_type,
        i_product_name,
        total_net_profit
    FROM top_products
    WHERE rn = 1
) tp
    ON qg.d_year = tp.d_year
   AND qg.d_quarter_seq = tp.d_quarter_seq
   AND qg.channel_type = tp.channel_type
ORDER BY qg.d_year, qg.d_quarter_seq, qg.channel_type
