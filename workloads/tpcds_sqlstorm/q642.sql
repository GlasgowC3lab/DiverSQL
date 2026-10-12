WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        'store' AS channel,
        s.s_state AS state,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        'catalog' AS channel,
        cc.cc_state AS state,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_sold_date_sk IS NOT NULL
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        'web' AS channel,
        w.w_state AS state,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk IS NOT NULL
),
sales_with_date AS (
    SELECT
        su.date_sk,
        d.d_year AS sales_year,
        d.d_moy AS sales_month,
        su.item_sk,
        i.i_product_name,
        i.i_category,
        i.i_class,
        i.i_brand,
        su.channel,
        su.state,
        su.net_profit,
        su.net_paid,
        su.promo_sk
    FROM sales_union su
    JOIN date_dim d ON su.date_sk = d.d_date_sk
    JOIN item i ON su.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
agg AS (
    SELECT
        sales_year,
        sales_month,
        state,
        channel,
        item_sk,
        i_product_name,
        i_category,
        i_class,
        i_brand,
        SUM(net_profit) AS total_net_profit,
        SUM(net_paid) AS total_net_paid,
        COUNT(*) AS sales_transactions,
        SUM(CASE WHEN promo_sk IS NOT NULL THEN 1 ELSE 0 END) AS promo_sales,
        AVG(net_profit / NULLIF(net_paid, 0)) AS profit_to_paid_ratio
    FROM sales_with_date
    GROUP BY
        sales_year,
        sales_month,
        state,
        channel,
        item_sk,
        i_product_name,
        i_category,
        i_class,
        i_brand
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_year, sales_month, state ORDER BY total_net_profit DESC) AS rn,
        SUM(promo_sales) OVER (PARTITION BY sales_year, sales_month, state) AS total_promo_sales_state,
        SUM(total_net_profit) OVER (PARTITION BY sales_year, sales_month, state) AS total_net_profit_state
    FROM agg
)
SELECT
    sales_year,
    sales_month,
    state,
    channel,
    item_sk,
    i_product_name,
    i_category,
    i_class,
    i_brand,
    total_net_profit,
    total_net_paid,
    sales_transactions,
    promo_sales,
    profit_to_paid_ratio,
    total_promo_sales_state,
    total_net_profit_state,
    CAST(promo_sales AS double) / NULLIF(total_promo_sales_state, 0) AS promo_sales_pct,
    total_net_profit / NULLIF(total_net_profit_state, 0) AS net_profit_share,
    rn
FROM ranked
WHERE rn <= 5
ORDER BY sales_year, sales_month, state, rn
