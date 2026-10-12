WITH
store_sales_enriched AS (
    SELECT
        'store' AS channel,
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        s.s_state AS state,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        i.i_item_id AS item_id,
        p.p_promo_id AS promo_id,
        ss.ss_quantity AS qty,
        ss.ss_net_paid AS net_amount,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
),
store_returns_enriched AS (
    SELECT
        'store' AS channel,
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        s.s_state AS state,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        i.i_item_id AS item_id,
        NULL AS promo_id,
        -sr.sr_return_quantity AS qty,
        -sr.sr_return_amt_inc_tax AS net_amount,
        -sr.sr_net_loss AS net_profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
catalog_sales_enriched AS (
    SELECT
        'catalog' AS channel,
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        cc.cc_state AS state,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        i.i_item_id AS item_id,
        p.p_promo_id AS promo_id,
        cs.cs_quantity AS qty,
        cs.cs_net_paid AS net_amount,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
),
catalog_returns_enriched AS (
    SELECT
        'catalog' AS channel,
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        cc.cc_state AS state,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        i.i_item_id AS item_id,
        NULL AS promo_id,
        -cr.cr_return_quantity AS qty,
        -cr.cr_return_amt_inc_tax AS net_amount,
        -cr.cr_net_loss AS net_profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
web_sales_enriched AS (
    SELECT
        'web' AS channel,
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        ws_state.web_state AS state,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        i.i_item_id AS item_id,
        p.p_promo_id AS promo_id,
        ws.ws_quantity AS qty,
        ws.ws_net_paid AS net_amount,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site ws_state ON ws.ws_web_site_sk = ws_state.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
),
web_returns_enriched AS (
    SELECT
        'web' AS channel,
        d.d_year AS sales_year,
        d.d_quarter_name AS sales_quarter,
        NULL AS state,
        i.i_category AS category,
        i.i_class AS class,
        i.i_brand AS brand,
        i.i_item_id AS item_id,
        NULL AS promo_id,
        -wr.wr_return_quantity AS qty,
        -wr.wr_return_amt_inc_tax AS net_amount,
        -wr.wr_net_loss AS net_profit
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
union_all AS (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM store_returns_enriched
    UNION ALL
    SELECT * FROM catalog_sales_enriched
    UNION ALL
    SELECT * FROM catalog_returns_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
    UNION ALL
    SELECT * FROM web_returns_enriched
),
agg_metrics AS (
    SELECT
        channel,
        sales_year,
        sales_quarter,
        state,
        category,
        class,
        brand,
        promo_id,
        SUM(qty) AS total_quantity,
        ROUND(SUM(net_amount), 2) AS total_net_amount,
        ROUND(SUM(net_profit), 2) AS total_net_profit
    FROM union_all
    GROUP BY GROUPING SETS (
        (channel, sales_year, sales_quarter, state, category, class, brand, promo_id),
        (channel, sales_year, sales_quarter, state, category, class, brand),
        (channel, sales_year, sales_quarter, state, category, class),
        (channel, sales_year, sales_quarter, state, category),
        (channel, sales_year, sales_quarter, state),
        (channel, sales_year, sales_quarter),
        (channel, sales_year),
        (channel)
    )
)
SELECT
    channel,
    sales_year,
    sales_quarter,
    state,
    category,
    class,
    brand,
    COALESCE(CAST(promo_id AS VARCHAR), 'NO_PROMO') AS promo_id,
    total_quantity,
    total_net_amount,
    total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY channel, sales_year, sales_quarter ORDER BY total_net_amount DESC) AS sales_rank
FROM agg_metrics
ORDER BY channel, sales_year, sales_quarter, state, total_net_amount DESC
