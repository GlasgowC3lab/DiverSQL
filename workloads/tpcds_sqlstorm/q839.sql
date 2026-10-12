WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_state AS region,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS net_paid,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE (p.p_promo_id IS NULL OR p.p_discount_active = 'Y')
      AND d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, s.s_state
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ws_site.web_state AS region,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS net_paid,
        SUM(ws.ws_net_profit) AS net_profit,
        COUNT(*) AS txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE (p.p_promo_id IS NULL OR p.p_discount_active = 'Y')
      AND d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, ws_site.web_state
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state AS region,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE (p.p_promo_id IS NULL OR p.p_discount_active = 'Y')
      AND d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
)
SELECT
    d_year,
    d_month_seq,
    region,
    channel,
    net_paid,
    net_profit,
    txn_cnt
FROM (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
) all_channels
ORDER BY d_year, d_month_seq, region, channel
LIMIT 100
