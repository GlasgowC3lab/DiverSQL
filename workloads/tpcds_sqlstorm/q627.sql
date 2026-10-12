WITH catalog AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS qty,
        SUM(cs.cs_ext_sales_price) AS sales,
        SUM(cs.cs_ext_discount_amt) AS discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY cs.cs_item_sk, d.d_year
), store AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_quantity) AS qty,
        SUM(ss.ss_ext_sales_price) AS sales,
        SUM(ss.ss_ext_discount_amt) AS discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY ss.ss_item_sk, d.d_year
), web AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS qty,
        SUM(ws.ws_ext_sales_price) AS sales,
        SUM(ws.ws_ext_discount_amt) AS discount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY ws.ws_item_sk, d.d_year
), combined AS (
    SELECT
        item_sk,
        d_year,
        SUM(profit) AS total_profit,
        SUM(qty) AS total_qty,
        SUM(sales) AS total_sales,
        SUM(discount) AS total_discount
    FROM (
        SELECT item_sk, d_year, profit, qty, sales, discount FROM catalog
        UNION ALL
        SELECT item_sk, d_year, profit, qty, sales, discount FROM store
        UNION ALL
        SELECT item_sk, d_year, profit, qty, sales, discount FROM web
    ) AS u
    GROUP BY item_sk, d_year
), enriched AS (
    SELECT
        c.item_sk,
        i.i_product_name AS i_product_name,
        i.i_brand AS i_brand,
        i.i_category AS i_category,
        c.d_year,
        c.total_profit,
        c.total_qty,
        c.total_sales,
        c.total_discount,
        CASE WHEN c.total_sales > 0 THEN (c.total_profit / c.total_sales) * 100 ELSE 0 END AS profit_margin_pct,
        SUM(c.total_profit) OVER (PARTITION BY c.d_year ORDER BY c.total_profit DESC) AS running_profit
    FROM combined c
    JOIN item i ON i.i_item_sk = c.item_sk
), ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rank_by_profit
    FROM enriched
)
SELECT
    d_year,
    rank_by_profit,
    item_sk,
    i_product_name,
    i_brand,
    i_category,
    total_profit,
    total_qty,
    total_sales,
    total_discount,
    profit_margin_pct,
    running_profit
FROM ranked
WHERE rank_by_profit <= 10
ORDER BY d_year, rank_by_profit
