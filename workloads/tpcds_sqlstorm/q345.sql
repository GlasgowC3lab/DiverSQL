WITH
date_range AS (
    SELECT *
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
),
catalog_sales_by_cc_month_item AS (
    SELECT
        cs.cs_call_center_sk AS cc_sk,
        d.d_year,
        d.d_month_seq,
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS item_net_profit
    FROM catalog_sales cs
    JOIN date_range d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_call_center_sk, d.d_year, d.d_month_seq, cs.cs_item_sk
),
catalog_item_rank AS (
    SELECT
        cc_sk,
        d_year,
        d_month_seq,
        cs_item_sk,
        item_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cc_sk, d_year, d_month_seq ORDER BY item_net_profit DESC) AS rn
    FROM catalog_sales_by_cc_month_item
),
catalog_top_item AS (
    SELECT
        cc_sk,
        d_year,
        d_month_seq,
        i.i_product_name AS top_product,
        item_net_profit AS top_product_profit
    FROM catalog_item_rank cir
    JOIN item i ON cir.cs_item_sk = i.i_item_sk
    WHERE cir.rn = 1
),
catalog_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        d.d_year,
        d.d_month_seq,
        COALESCE(SUM(cs.cs_net_profit), 0) AS net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_item_cnt,
        ct.top_product,
        ct.top_product_profit
    FROM call_center cc
    LEFT JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN date_range d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_top_item ct ON cc.cc_call_center_sk = ct.cc_sk AND d.d_year = ct.d_year AND d.d_month_seq = ct.d_month_seq
    GROUP BY cc.cc_call_center_sk, cc.cc_name, d.d_year, d.d_month_seq, ct.top_product, ct.top_product_profit
),
store_sales_by_store_month_item AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        d.d_year,
        d.d_month_seq,
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS item_net_profit
    FROM store_sales ss
    JOIN date_range d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq, ss.ss_item_sk
),
store_item_rank AS (
    SELECT
        store_sk,
        d_year,
        d_month_seq,
        ss_item_sk,
        item_net_profit,
        ROW_NUMBER() OVER (PARTITION BY store_sk, d_year, d_month_seq ORDER BY item_net_profit DESC) AS rn
    FROM store_sales_by_store_month_item
),
store_top_item AS (
    SELECT
        store_sk,
        d_year,
        d_month_seq,
        i.i_product_name AS top_product,
        item_net_profit AS top_product_profit
    FROM store_item_rank sir
    JOIN item i ON sir.ss_item_sk = i.i_item_sk
    WHERE sir.rn = 1
),
store_agg AS (
    SELECT
        s.s_store_sk AS entity_sk,
        s.s_store_name AS entity_name,
        d.d_year,
        d.d_month_seq,
        COALESCE(SUM(ss.ss_net_profit), 0) AS net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_item_cnt,
        st.top_product,
        st.top_product_profit
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    LEFT JOIN date_range d ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_top_item st ON s.s_store_sk = st.store_sk AND d.d_year = st.d_year AND d.d_month_seq = st.d_month_seq
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq, st.top_product, st.top_product_profit
),
web_sales_by_site_month_item AS (
    SELECT
        ws.ws_web_site_sk AS site_sk,
        d.d_year,
        d.d_month_seq,
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS item_net_profit
    FROM web_sales ws
    JOIN date_range d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws.ws_web_site_sk, d.d_year, d.d_month_seq, ws.ws_item_sk
),
web_item_rank AS (
    SELECT
        site_sk,
        d_year,
        d_month_seq,
        ws_item_sk,
        item_net_profit,
        ROW_NUMBER() OVER (PARTITION BY site_sk, d_year, d_month_seq ORDER BY item_net_profit DESC) AS rn
    FROM web_sales_by_site_month_item
),
web_top_item AS (
    SELECT
        site_sk,
        d_year,
        d_month_seq,
        i.i_product_name AS top_product,
        item_net_profit AS top_product_profit
    FROM web_item_rank wir
    JOIN item i ON wir.ws_item_sk = i.i_item_sk
    WHERE wir.rn = 1
),
web_agg AS (
    SELECT
        w.web_site_sk AS entity_sk,
        w.web_name AS entity_name,
        d.d_year,
        d.d_month_seq,
        COALESCE(SUM(ws.ws_net_profit), 0) AS net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_item_cnt,
        wt.top_product,
        wt.top_product_profit
    FROM web_site w
    LEFT JOIN web_sales ws ON w.web_site_sk = ws.ws_web_site_sk
    LEFT JOIN date_range d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_top_item wt ON w.web_site_sk = wt.site_sk AND d.d_year = wt.d_year AND d.d_month_seq = wt.d_month_seq
    GROUP BY w.web_site_sk, w.web_name, d.d_year, d.d_month_seq, wt.top_product, wt.top_product_profit
),
combined AS (
    SELECT 'catalog' AS channel,
           ca.cc_call_center_sk AS entity_sk,
           ca.cc_name AS entity_name,
           ca.d_year,
           ca.d_month_seq,
           ca.net_profit,
           ca.order_cnt,
           ca.distinct_item_cnt,
           ca.top_product,
           ca.top_product_profit
    FROM catalog_agg ca
    UNION ALL
    SELECT 'store' AS channel,
           sa.entity_sk,
           sa.entity_name,
           sa.d_year,
           sa.d_month_seq,
           sa.net_profit,
           sa.order_cnt,
           sa.distinct_item_cnt,
           sa.top_product,
           sa.top_product_profit
    FROM store_agg sa
    UNION ALL
    SELECT 'web' AS channel,
           wa.entity_sk,
           wa.entity_name,
           wa.d_year,
           wa.d_month_seq,
           wa.net_profit,
           wa.order_cnt,
           wa.distinct_item_cnt,
           wa.top_product,
           wa.top_product_profit
    FROM web_agg wa
),
final AS (
    SELECT
        c.channel,
        c.entity_sk,
        c.entity_name,
        c.d_year,
        c.d_month_seq,
        c.net_profit,
        c.order_cnt,
        c.distinct_item_cnt,
        c.top_product,
        c.top_product_profit,
        ROW_NUMBER() OVER (PARTITION BY c.channel ORDER BY c.net_profit DESC) AS profit_rank,
        SUM(c.net_profit) OVER (PARTITION BY c.channel ORDER BY c.d_year, c.d_month_seq
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        (c.net_profit / NULLIF((SELECT SUM(net_profit) FROM combined c2 WHERE c2.channel = c.channel), 0)) AS profit_share,
        CONCAT(c.channel, ': ', COALESCE(c.entity_name, 'N/A'), ' Rank ', CAST(ROW_NUMBER() OVER (PARTITION BY c.channel ORDER BY c.net_profit DESC) AS VARCHAR),
               ', Top ', COALESCE(c.top_product, 'None'), ' Profit ', CAST(COALESCE(c.top_product_profit, 0) AS VARCHAR)) AS summary
    FROM combined c
    WHERE c.d_year IS NOT NULL
)
SELECT
    d_year,
    d_month_seq,
    channel,
    entity_name,
    net_profit,
    order_cnt,
    distinct_item_cnt,
    top_product,
    top_product_profit,
    profit_rank,
    cumulative_profit,
    profit_share,
    summary
FROM final
WHERE profit_rank <= 5
ORDER BY d_year, d_month_seq, channel, profit_rank
