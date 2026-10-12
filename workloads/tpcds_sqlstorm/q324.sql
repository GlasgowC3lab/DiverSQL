WITH date_filtered AS (
   SELECT d_date_sk,
          d_date,
          d_year,
          d_month_seq,
          d_week_seq,
          d_day_name,
          d_holiday,
          CASE WHEN d_current_day = 'Y' THEN 1 ELSE 0 END AS is_current_day
   FROM date_dim d
   WHERE d_year BETWEEN 1998 AND 2002
),
category_sales AS (
   SELECT
      cs.cs_sold_date_sk AS date_sk,
      i.i_category AS category,
      i.i_category_id AS cat_id,
      sum(cs.cs_ext_sales_price) AS cat_sales,
      sum(cs.cs_quantity) AS cat_qty,
      avg(cs.cs_ext_discount_amt) AS cat_avg_discount,
      max(cs.cs_net_profit) AS cat_max_profit,
      min(cs.cs_net_profit) AS cat_min_profit,
      count(DISTINCT cs.cs_item_sk) AS distinct_items,
      array_agg(DISTINCT i.i_brand) FILTER (WHERE i.i_brand IS NOT NULL) AS brands
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE i.i_brand IS NOT NULL
   GROUP BY cs.cs_sold_date_sk, i.i_category, i.i_category_id
),
store_category_sales AS (
   SELECT
      ss.ss_sold_date_sk AS date_sk,
      i.i_category AS category,
      i.i_category_id AS cat_id,
      sum(ss.ss_ext_sales_price) AS cat_sales,
      sum(ss.ss_quantity) AS cat_qty,
      avg(ss.ss_ext_discount_amt) AS cat_avg_discount,
      max(ss.ss_net_profit) AS cat_max_profit,
      min(ss.ss_net_profit) AS cat_min_profit,
      count(DISTINCT ss.ss_item_sk) AS distinct_items,
      array_agg(DISTINCT i.i_brand) FILTER (WHERE i.i_brand IS NOT NULL) AS brands
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY ss.ss_sold_date_sk, i.i_category, i.i_category_id
),
web_category_sales AS (
   SELECT
      ws.ws_sold_date_sk AS date_sk,
      i.i_category AS category,
      i.i_category_id AS cat_id,
      sum(ws.ws_ext_sales_price) AS cat_sales,
      sum(ws.ws_quantity) AS cat_qty,
      avg(ws.ws_ext_discount_amt) AS cat_avg_discount,
      max(ws.ws_net_profit) AS cat_max_profit,
      min(ws.ws_net_profit) AS cat_min_profit,
      count(DISTINCT ws.ws_item_sk) AS distinct_items,
      array_agg(DISTINCT i.i_brand) FILTER (WHERE i.i_brand IS NOT NULL) AS brands
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY ws.ws_sold_date_sk, i.i_category, i.i_category_id
),
combined_sales AS (
   SELECT
      date_sk,
      category,
      cat_id,
      cat_sales,
      cat_qty,
      cat_avg_discount,
      cat_max_profit,
      cat_min_profit,
      distinct_items,
      brands,
      'catalog' AS channel
   FROM category_sales
   UNION ALL
   SELECT
      date_sk,
      category,
      cat_id,
      cat_sales,
      cat_qty,
      cat_avg_discount,
      cat_max_profit,
      cat_min_profit,
      distinct_items,
      brands,
      'store' AS channel
   FROM store_category_sales
   UNION ALL
   SELECT
      date_sk,
      category,
      cat_id,
      cat_sales,
      cat_qty,
      cat_avg_discount,
      cat_max_profit,
      cat_min_profit,
      distinct_items,
      brands,
      'web' AS channel
   FROM web_category_sales
),
ranking AS (
   SELECT
      date_sk,
      category,
      cat_id,
      channel,
      cat_sales,
      cat_qty,
      cat_avg_discount,
      cat_max_profit,
      cat_min_profit,
      distinct_items,
      brands,
      sum(cat_sales) OVER (PARTITION BY category ORDER BY date_sk ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS sales_7d_window,
      rank() OVER (PARTITION BY date_sk ORDER BY cat_sales DESC) AS sales_rank,
      row_number() OVER (ORDER BY date_sk, cat_sales DESC) AS global_rownum,
      CASE
        WHEN nullif(cat_qty,0) IS NULL THEN NULL
        ELSE cat_max_profit / nullif(cat_qty,0)
      END AS profit_per_item,
      concat(coalesce(category, 'UNKNOWN'), '-', CAST(date_sk AS varchar), '-', channel) AS composite_key
   FROM combined_sales
   WHERE cat_sales > 0
),
prev_day_data AS (
   SELECT
      r.date_sk,
      r.category,
      r.channel,
      r.cat_sales,
      (SELECT sum(cs.cat_sales)
       FROM combined_sales cs
       WHERE cs.channel = r.channel
         AND cs.category = r.category
         AND cs.date_sk = r.date_sk - 1
      ) AS prev_day_cat_sales
   FROM ranking r
),
promo_link AS (
   SELECT
      p.p_promo_sk,
      p.p_item_sk,
      p.p_discount_active,
      i.i_category,
      i.i_category_id
   FROM promotion p
   LEFT JOIN item i ON p.p_item_sk = i.i_item_sk
   WHERE p.p_discount_active = 'Y'
),
final_set AS (
   SELECT
      r.date_sk,
      d.d_date,
      r.category,
      r.cat_id,
      r.channel,
      r.cat_sales,
      r.cat_qty,
      r.cat_avg_discount,
      r.sales_7d_window,
      r.sales_rank,
      r.global_rownum,
      r.profit_per_item,
      r.composite_key,
      pl.p_promo_sk,
      pl.p_discount_active,
      CASE
        WHEN pd.prev_day_cat_sales IS NULL THEN 'NO_PREV'
        WHEN pd.prev_day_cat_sales = 0 THEN 'ZERO_PREV'
        ELSE 'HAS_PREV'
      END AS prev_day_status,
      IF(pd.prev_day_cat_sales IS NULL, 0, 1) * (r.sales_rank % 2) AS rank_parity_flag,
      coalesce(p.p_promo_id, concat('NO_PROMO_', r.composite_key)) AS promo_identifier,
      (r.cat_sales * coalesce(r.cat_avg_discount, 0) * nullif(r.distinct_items,0)) / nullif(r.sales_rank,0) AS weird_score
   FROM ranking r
   LEFT JOIN prev_day_data pd ON r.date_sk = pd.date_sk AND r.category = pd.category AND r.channel = pd.channel
   LEFT JOIN date_dim d ON r.date_sk = d.d_date_sk
   LEFT JOIN promo_link pl ON r.category = pl.i_category AND r.channel = 'catalog'
   LEFT JOIN promotion p ON pl.p_promo_sk = p.p_promo_sk
   WHERE r.sales_rank <= 10
      OR (r.category LIKE '%Tools' AND r.channel = 'store')
      OR (r.composite_key IS NOT NULL AND r.composite_key != '')
)
SELECT *
FROM final_set
WHERE (weird_score IS NOT NULL AND weird_score > 0)
   OR (prev_day_status = 'NO_PREV' AND profit_per_item IS NOT NULL)
ORDER BY date_sk DESC, sales_rank ASC
LIMIT 100
