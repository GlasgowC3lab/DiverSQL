WITH store_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        i.i_category,
        i.i_brand,
        i.i_class,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY ss.ss_sold_date_sk, i.i_category, i.i_brand, i.i_class
),
catalog_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        i.i_category,
        i.i_brand,
        i.i_class,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY cs.cs_sold_date_sk, i.i_category, i.i_brand, i.i_class
),
web_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        i.i_category,
        i.i_brand,
        i.i_class,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY ws.ws_sold_date_sk, i.i_category, i.i_brand, i.i_class
),
combined AS (
    SELECT
        COALESCE(s.date_sk, c.date_sk, w.date_sk) AS date_sk,
        COALESCE(s.i_category, c.i_category, w.i_category) AS i_category,
        COALESCE(s.i_brand, c.i_brand, w.i_brand) AS i_brand,
        COALESCE(s.i_class, c.i_class, w.i_class) AS i_class,
        COALESCE(s.store_net_paid, 0) + COALESCE(c.catalog_net_paid, 0) + COALESCE(w.web_net_paid, 0) AS total_net_paid,
        COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) AS total_net_profit,
        COALESCE(s.store_quantity, 0) + COALESCE(c.catalog_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity
    FROM store_agg s
    FULL OUTER JOIN catalog_agg c
      ON s.date_sk = c.date_sk
     AND s.i_category = c.i_category
     AND s.i_brand = c.i_brand
     AND s.i_class = c.i_class
    FULL OUTER JOIN web_agg w
      ON COALESCE(s.date_sk, c.date_sk) = w.date_sk
     AND COALESCE(s.i_category, c.i_category) = w.i_category
     AND COALESCE(s.i_brand, c.i_brand) = w.i_brand
     AND COALESCE(s.i_class, c.i_class) = w.i_class
),
final AS (
    SELECT
        d.d_date,
        comb.i_category,
        comb.i_brand,
        comb.i_class,
        comb.total_net_paid,
        comb.total_net_profit,
        comb.total_quantity,
        AVG(comb.total_net_paid) OVER (PARTITION BY comb.i_category, comb.i_brand ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d,
        RANK() OVER (PARTITION BY d.d_date ORDER BY comb.total_net_paid DESC) AS sales_rank
    FROM combined comb
    JOIN date_dim d ON comb.date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    d_date,
    i_category,
    i_brand,
    i_class,
    total_net_paid,
    total_net_profit,
    total_quantity,
    moving_avg_7d,
    sales_rank
FROM final
WHERE total_net_paid > 100000
ORDER BY d_date DESC, total_net_paid DESC
LIMIT 200
