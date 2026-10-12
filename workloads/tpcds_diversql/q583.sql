WITH
    sampled_sales AS (
        SELECT
            ws_sold_date_sk,
            ws_warehouse_sk,
            ws_promo_sk,
            ws_web_page_sk,
            SUM(ws_net_profit) AS total_profit,
            SUM(ws_quantity) AS total_qty
        FROM web_sales TABLESAMPLE BERNOULLI (10)
        GROUP BY ws_sold_date_sk, ws_warehouse_sk, ws_promo_sk, ws_web_page_sk
    ),
    union_sales AS (
        SELECT ws_web_page_sk, ws_warehouse_sk FROM sampled_sales
        UNION
        SELECT ws_web_page_sk, ws_warehouse_sk FROM web_sales WHERE ws_quantity > 0
    ),
    sales_date AS (
        SELECT
            ss.ws_sold_date_sk,
            ss.ws_warehouse_sk,
            ss.ws_promo_sk,
            ss.ws_web_page_sk,
            ss.total_profit,
            ss.total_qty,
            d.d_date_sk,
            d.d_date,
            d.d_year,
            d.d_month_seq,
            d.d_holiday
        FROM sampled_sales ss
        JOIN date_dim d ON ss.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = 2000
          AND d.d_month_seq BETWEEN 1200 AND 1210
          AND d.d_holiday = 'N'
    ),
    promo_scalar AS (
        SELECT p_promo_sk FROM promotion WHERE p_discount_active = 'Y' LIMIT 1
    ),
    warehouse_excl AS (
        SELECT w_warehouse_sk FROM warehouse WHERE w_country = 'USA'
        EXCEPT
        SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA'
    ),
    catalog_anti AS (
        SELECT cp_catalog_page_sk,
               cp_catalog_page_id,
               cp_type,
               cp_start_date_sk
        FROM catalog_page
        WHERE cp_catalog_page_sk NOT IN (SELECT ws_web_page_sk FROM sampled_sales)
    )
SELECT
    COALESCE(p.p_promo_id, 'NO_PROMO')                AS promo_id,
    w.w_warehouse_name                                 AS warehouse_name,
    d.d_date                                           AS sale_date,
    cp.cp_catalog_page_id                              AS catalog_page_id,
    wp.wp_url                                          AS web_page_url,
    agg.total_profit                                   AS total_profit,
    agg.total_qty                                      AS total_qty,
    RANK() OVER (PARTITION BY d.d_year ORDER BY agg.total_profit DESC) AS profit_year_rank,
    CASE WHEN agg.total_profit > (
            SELECT total_profit FROM (
                SELECT SUM(ws_net_profit) AS total_profit
                FROM web_sales
                WHERE ws_sold_date_sk = (
                    SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000
                )
            ) sub
        ) THEN 'HIGH' ELSE 'NORMAL' END                AS profit_level
FROM (
        SELECT
            ss.ws_warehouse_sk,
            ss.ws_promo_sk,
            ss.ws_sold_date_sk,
            ss.ws_web_page_sk,
            ss.total_profit,
            ss.total_qty
        FROM sampled_sales ss
        INNER JOIN union_sales us
            ON ss.ws_web_page_sk = us.ws_web_page_sk
           AND ss.ws_warehouse_sk = us.ws_warehouse_sk
    ) agg
FULL OUTER JOIN promotion p ON agg.ws_promo_sk = p.p_promo_sk
LEFT JOIN warehouse w ON agg.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN sales_date d ON agg.ws_sold_date_sk = d.ws_sold_date_sk
LEFT JOIN web_page wp ON agg.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN catalog_anti cp ON d.d_date_sk = cp.cp_start_date_sk
WHERE agg.ws_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse_excl)
  AND p.p_promo_sk = (SELECT p_promo_sk FROM promo_scalar)
ORDER BY profit_year_rank, d.d_date
LIMIT 100
