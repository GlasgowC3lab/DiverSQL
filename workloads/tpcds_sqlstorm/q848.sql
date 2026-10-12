WITH store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        sum(ss.ss_net_paid_inc_tax) AS store_sales,
        sum(ss.ss_net_profit) AS store_profit,
        count(DISTINCT ss.ss_item_sk) AS store_distinct_items,
        avg(ss.ss_ext_discount_amt) AS store_avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year IN (1999, 2000)
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        sum(ws.ws_net_paid_inc_tax) AS web_sales,
        sum(ws.ws_net_profit) AS web_profit,
        count(DISTINCT ws.ws_item_sk) AS web_distinct_items,
        avg(ws.ws_ext_discount_amt) AS web_avg_discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year IN (1999, 2000)
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        sum(cs.cs_net_paid_inc_tax) AS catalog_sales,
        sum(cs.cs_net_profit) AS catalog_profit,
        count(DISTINCT cs.cs_item_sk) AS catalog_distinct_items,
        avg(cs.cs_ext_discount_amt) AS catalog_avg_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year IN (1999, 2000)
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined AS (
    SELECT
        COALESCE(s.d_year, w.d_year, c.d_year) AS sales_year,
        COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq) AS month_seq,
        COALESCE(s.category, w.category, c.category) AS category,
        s.store_sales,
        s.store_profit,
        s.store_distinct_items,
        s.store_avg_discount,
        w.web_sales,
        w.web_profit,
        w.web_distinct_items,
        w.web_avg_discount,
        c.catalog_sales,
        c.catalog_profit,
        c.catalog_distinct_items,
        c.catalog_avg_discount
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.d_year = w.d_year
        AND s.d_month_seq = w.d_month_seq
        AND s.category = w.category
    FULL OUTER JOIN catalog_agg c
        ON COALESCE(s.d_year, w.d_year) = c.d_year
        AND COALESCE(s.d_month_seq, w.d_month_seq) = c.d_month_seq
        AND COALESCE(s.category, w.category) = c.category
)
SELECT
    sales_year,
    month_seq,
    category,
    store_sales,
    web_sales,
    catalog_sales,
    total_sales,
    total_profit,
    total_distinct_items,
    avg_discount_across_channels,
    LAG(total_sales) OVER (PARTITION BY category ORDER BY sales_year, month_seq) AS prev_month_total_sales,
    (total_sales - LAG(total_sales) OVER (PARTITION BY category ORDER BY sales_year, month_seq)) /
        NULLIF(LAG(total_sales) OVER (PARTITION BY category ORDER BY sales_year, month_seq), 0) AS mom_growth
FROM (
    SELECT
        sales_year,
        month_seq,
        category,
        store_sales,
        web_sales,
        catalog_sales,
        (store_sales + web_sales + catalog_sales) AS total_sales,
        (store_profit + web_profit + catalog_profit) AS total_profit,
        (store_distinct_items + web_distinct_items + catalog_distinct_items) AS total_distinct_items,
        (store_avg_discount + web_avg_discount + catalog_avg_discount) / 3.0 AS avg_discount_across_channels
    FROM combined
) q
WHERE sales_year = 2000
ORDER BY category, month_seq
