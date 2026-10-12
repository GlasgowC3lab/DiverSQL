WITH sales_union AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_customer_sk AS customer_sk,
           ss_cdemo_sk AS cdemo_sk,
           ss_hdemo_sk AS hdemo_sk,
           ss_store_sk AS store_sk,
           ss_item_sk AS item_sk,
           ss_promo_sk AS promo_sk,
           ss_quantity AS quantity,
           ss_net_profit AS net_profit,
           ss_net_paid AS net_paid,
           ss_ext_sales_price AS ext_sales_price,
           'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk AS date_sk,
           cs_bill_customer_sk AS customer_sk,
           cs_bill_cdemo_sk AS cdemo_sk,
           cs_bill_hdemo_sk AS hdemo_sk,
           cs_call_center_sk AS store_sk,
           cs_item_sk AS item_sk,
           cs_promo_sk AS promo_sk,
           cs_quantity AS quantity,
           cs_net_profit AS net_profit,
           cs_net_paid AS net_paid,
           cs_ext_sales_price AS ext_sales_price,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_bill_customer_sk AS customer_sk,
           ws_bill_cdemo_sk AS cdemo_sk,
           ws_bill_hdemo_sk AS hdemo_sk,
           ws_warehouse_sk AS store_sk,
           ws_item_sk AS item_sk,
           ws_promo_sk AS promo_sk,
           ws_quantity AS quantity,
           ws_net_profit AS net_profit,
           ws_net_paid AS net_paid,
           ws_ext_sales_price AS ext_sales_price,
           'web' AS channel
    FROM web_sales
),
sales_enriched AS (
    SELECT s.*,
           d.d_year,
           d.d_moy AS month_of_year,
           d.d_date,
           i.i_category,
           i.i_brand,
           cd.cd_gender,
           cd.cd_marital_status,
           hd.hd_buy_potential,
           CASE 
               WHEN s.channel = 'store' THEN st.s_state
               WHEN s.channel = 'catalog' THEN cc.cc_state
               WHEN s.channel = 'web' THEN w.w_state
               ELSE NULL
           END AS state
    FROM sales_union s
    LEFT JOIN date_dim d ON s.date_sk = d.d_date_sk
    LEFT JOIN item i ON s.item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON s.hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store st ON s.store_sk = st.s_store_sk
    LEFT JOIN call_center cc ON s.store_sk = cc.cc_call_center_sk
    LEFT JOIN warehouse w ON s.store_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
),
agg_sales AS (
    SELECT
        state,
        i_category,
        cd_gender,
        hd_buy_potential,
        SUM(net_profit) AS total_net_profit,
        SUM(ext_sales_price) AS total_ext_sales,
        SUM(net_profit) / NULLIF(SUM(ext_sales_price), 0) AS profit_margin,
        AVG(net_profit) AS avg_net_profit,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS store_net_profit,
        SUM(CASE WHEN channel = 'catalog' THEN net_profit ELSE 0 END) AS catalog_net_profit,
        SUM(CASE WHEN channel = 'web' THEN net_profit ELSE 0 END) AS web_net_profit
    FROM sales_enriched
    GROUP BY state, i_category, cd_gender, hd_buy_potential
    HAVING SUM(net_profit) > 0
)
SELECT
    state,
    i_category,
    cd_gender,
    hd_buy_potential,
    total_net_profit,
    total_ext_sales,
    profit_margin,
    avg_net_profit,
    distinct_customers,
    store_net_profit,
    catalog_net_profit,
    web_net_profit,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_net_profit DESC) AS rank_by_state
FROM agg_sales
ORDER BY total_net_profit DESC
LIMIT 100
