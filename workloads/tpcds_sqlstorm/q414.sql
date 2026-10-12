WITH
    sales_union AS (
        SELECT cs.cs_item_sk AS item_sk,
               cs.cs_sold_date_sk AS date_sk,
               cs.cs_ext_sales_price AS sales_amount,
               cs.cs_net_profit AS profit,
               cs.cs_quantity AS quantity,
               'catalog' AS channel
          FROM catalog_sales cs
        UNION ALL
        SELECT ss.ss_item_sk,
               ss.ss_sold_date_sk,
               ss.ss_ext_sales_price,
               ss.ss_net_profit,
               ss.ss_quantity,
               'store'
          FROM store_sales ss
        UNION ALL
        SELECT ws.ws_item_sk,
               ws.ws_sold_date_sk,
               ws.ws_ext_sales_price,
               ws.ws_net_profit,
               ws.ws_quantity,
               'web'
          FROM web_sales ws
    ),
    returns_union AS (
        SELECT cr.cr_item_sk AS item_sk,
               cr.cr_returned_date_sk AS date_sk,
               cr.cr_return_amount AS return_amount,
               cr.cr_return_quantity AS quantity,
               'catalog' AS channel
          FROM catalog_returns cr
        UNION ALL
        SELECT sr.sr_item_sk,
               sr.sr_returned_date_sk,
               sr.sr_return_amt,
               sr.sr_return_quantity,
               'store'
          FROM store_returns sr
        UNION ALL
        SELECT wr.wr_item_sk,
               wr.wr_returned_date_sk,
               wr.wr_return_amt,
               wr.wr_return_quantity,
               'web'
          FROM web_returns wr
    ),
    item_sales AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_product_name,
               i.i_category,
               i.i_category_id,
               i.i_class,
               i.i_class_id,
               d.d_year,
               SUM(s.sales_amount) AS total_sales,
               SUM(s.profit) AS total_profit,
               SUM(s.quantity) AS total_quantity,
               COUNT(DISTINCT s.date_sk) AS distinct_sales_dates,
               SUM(COALESCE(r.return_amount, 0)) AS total_returns_amount,
               SUM(COALESCE(r.quantity, 0)) AS total_returns_quantity
          FROM sales_union s
          LEFT JOIN returns_union r
            ON s.item_sk = r.item_sk
           AND s.date_sk = r.date_sk
           AND s.channel = r.channel
          JOIN item i ON s.item_sk = i.i_item_sk
          JOIN date_dim d ON s.date_sk = d.d_date_sk
         WHERE (i.i_color IS NOT NULL OR i.i_color = '')
           AND d.d_year BETWEEN 1999 AND 2002
         GROUP BY
               i.i_item_sk,
               i.i_item_id,
               i.i_product_name,
               i.i_category,
               i.i_category_id,
               i.i_class,
               i.i_class_id,
               d.d_year
    ),
    profit_ratio AS (
        SELECT *,
               CASE 
                 WHEN total_sales = 0 THEN NULL
                 ELSE (total_profit / nullif(total_sales, 0)) * 100.0
               END AS profit_margin_pct
        FROM item_sales
    ),
    ranked_items AS (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY profit_margin_pct DESC NULLS LAST) AS rank_within_category,
               RANK() OVER (ORDER BY profit_margin_pct DESC NULLS LAST) AS overall_rank,
               CONCAT(i_product_name, ' (', i_category, ')') AS item_desc,
               IF(total_returns_quantity > total_quantity, TRUE, FALSE) AS returns_exceed_sales,
               COALESCE(NULLIF(CAST(total_sales AS VARCHAR), ''), '0') AS sales_str,
               CASE 
                   WHEN total_returns_amount > total_sales THEN 'ALERT' 
                   ELSE 'OK' 
               END AS return_status,
               CASE WHEN EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i_item_sk AND p.p_discount_active = 'Y') THEN 'YES' ELSE 'NO' END AS active_promo,
               (SELECT MAX(su.sales_amount) FROM sales_union su WHERE su.item_sk = i_item_sk) AS max_daily_sales
        FROM profit_ratio
    ),
    double_aggregates AS (
        SELECT 
            i_category,
            COUNT(*) FILTER (WHERE rank_within_category <= 5) AS top5_count,
            SUM(total_sales) AS category_sales,
            SUM(total_profit) AS category_profit,
            MAX(profit_margin_pct) AS max_margin,
            MIN(profit_margin_pct) AS min_margin,
            AVG(profit_margin_pct) AS avg_margin
        FROM ranked_items
        GROUP BY i_category
    )
SELECT 
    r.i_item_sk,
    r.item_desc,
    r.i_class,
    r.i_class_id,
    r.d_year,
    r.total_sales,
    r.total_profit,
    r.total_returns_amount,
    r.total_returns_quantity,
    r.profit_margin_pct,
    r.rank_within_category,
    r.overall_rank,
    r.returns_exceed_sales,
    r.sales_str,
    r.return_status,
    r.active_promo,
    r.max_daily_sales,
    d.max_margin,
    d.min_margin,
    d.avg_margin,
    CASE 
        WHEN d.max_margin IS NOT NULL AND r.profit_margin_pct = d.max_margin THEN 'CATEGORY_MAX'
        WHEN d.min_margin IS NOT NULL AND r.profit_margin_pct = d.min_margin THEN 'CATEGORY_MIN'
        ELSE NULL
    END AS margin_flag
FROM ranked_items r
LEFT JOIN double_aggregates d
  ON r.i_category = d.i_category
WHERE (r.rank_within_category <= 10 OR r.overall_rank <= 20)
   AND (r.i_item_sk % 2 = 0 OR r.i_item_sk IS NULL)
   AND (COALESCE(r.item_desc, '') <> '')
   AND (r.profit_margin_pct IS NOT NULL OR r.total_sales = 0)
ORDER BY r.profit_margin_pct DESC NULLS LAST, r.i_item_sk
