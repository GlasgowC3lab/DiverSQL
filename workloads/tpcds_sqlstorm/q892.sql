WITH
date_filtered AS (
    SELECT d_date_sk, d_year, d_quarter_seq
    FROM date_dim
    WHERE d_year BETWEEN 1998 AND 1999
),
sales_prepared AS (
    SELECT
        d.d_year,
        d.d_quarter_seq,
        cc.cc_state AS state,
        'Catalog' AS channel,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_ext_discount_amt AS ext_discount_amt,
        cs.cs_net_paid_inc_tax AS net_paid_inc_tax,
        cs.cs_net_profit AS net_profit,
        i.i_category AS category,
        p.p_discount_active AS promo_active
    FROM catalog_sales cs
    JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE i.i_category = 'Sports'
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)

    UNION ALL

    SELECT
        d.d_year,
        d.d_quarter_seq,
        s.s_state AS state,
        'Store' AS channel,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit,
        i.i_category,
        NULL AS promo_active
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category = 'Sports'

    UNION ALL

    SELECT
        d.d_year,
        d.d_quarter_seq,
        w.web_state AS state,
        'Web' AS channel,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        i.i_category,
        p.p_discount_active
    FROM web_sales ws
    JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_category = 'Sports'
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
),
sales_agg AS (
    SELECT
        channel,
        state,
        d_year,
        d_quarter_seq,
        category,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        CASE WHEN SUM(ext_sales_price) <> 0 THEN SUM(net_profit) / SUM(ext_sales_price) ELSE 0 END AS profit_margin,
        CASE WHEN SUM(ext_sales_price) <> 0 THEN SUM(ext_discount_amt) / SUM(ext_sales_price) ELSE 0 END AS discount_rate,
        COUNT(*) AS txn_count
    FROM sales_prepared
    GROUP BY channel, state, d_year, d_quarter_seq, category
)
SELECT
    channel,
    state,
    d_year,
    d_quarter_seq,
    category,
    total_sales,
    total_profit,
    profit_margin,
    discount_rate,
    txn_count,
    rn AS rank_state
FROM (
    SELECT
        channel,
        state,
        d_year,
        d_quarter_seq,
        category,
        total_sales,
        total_profit,
        profit_margin,
        discount_rate,
        txn_count,
        ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_quarter_seq ORDER BY total_profit DESC) AS rn
    FROM sales_agg
) t
WHERE rn <= 3
ORDER BY channel, d_year, d_quarter_seq, rn
