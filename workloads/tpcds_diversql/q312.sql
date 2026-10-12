WITH
  -- Pre‑aggregate store returns with time and demographic filters
  store_return_agg AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_returned_date_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_quantity > 1
      AND sr.sr_return_amt > 0
      AND td.t_hour BETWEEN 9 AND 17
      AND cd.cd_gender = 'M'
      AND cd.cd_credit_rating = 'Excellent'
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
  ),

  -- Pre‑aggregate web sales with time and demographic filters
  web_sales_agg AS (
    SELECT
      ws.ws_warehouse_sk,
      ws.ws_sold_date_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_quantity > 0
      AND ws.ws_sales_price > 15
      AND td.t_hour BETWEEN 8 AND 20
      AND cd.cd_marital_status = 'M'
      AND cd.cd_education_status = 'College'
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk
  ),

  -- Intersect store keys that appear in returns with all stores
  intersect_stores AS (
    SELECT sr.sr_store_sk FROM store_return_agg sr
    INTERSECT
    SELECT s.s_store_sk FROM store s
  ),

  -- Store information joined to its closed date and an array of location parts
  store_dates AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      d.d_date_sk AS closed_date_sk,
      d.d_year   AS closed_year,
      ARRAY[ s.s_city, s.s_state ] AS loc_parts
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND s.s_state = 'CA'
      AND s.s_suite_number = 'Suite 140'
  ),

  -- Web‑sales order information joined to its sold date
  sales_dates AS (
    SELECT
      ws.ws_warehouse_sk,
      ws.ws_order_number,
      d.d_date_sk AS sold_date_sk,
      d.d_year   AS sold_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_month_seq = 120
      AND ws.ws_sales_price > 25
      AND ws.ws_promo_sk IS NOT NULL
  ),

  -- Full outer join of store‑date rows with web‑sales‑date rows on the date key
  full_joined AS (
    SELECT
      sd.s_store_sk,
      sd.s_store_name,
      sd.closed_date_sk,
      sd.closed_year,
      sd.loc_parts,
      sd2.ws_warehouse_sk,
      sd2.ws_order_number,
      sd2.sold_date_sk,
      sd2.sold_year
    FROM store_dates sd
    FULL OUTER JOIN sales_dates sd2
      ON sd.closed_date_sk = sd2.sold_date_sk
  ),

  -- Expand the location array so each part appears on its own row
  expanded AS (
    SELECT
      fj.*,
      loc_part
    FROM full_joined fj
    LEFT JOIN UNNEST(fj.loc_parts) AS t(loc_part) ON TRUE
  ),

  -- Combine everything, add a global row number, and keep only stores from the intersect set
  final AS (
    SELECT
      e.s_store_sk,
      e.s_store_name,
      e.ws_warehouse_sk,
      e.ws_order_number,
      e.closed_year,
      e.sold_year,
      sr_agg.total_return_amt,
      ws_agg.total_sales,
      e.loc_part,
      ROW_NUMBER() OVER (ORDER BY sr_agg.total_return_amt DESC NULLS LAST) AS rn
    FROM expanded e
    LEFT JOIN store_return_agg sr_agg
      ON e.s_store_sk = sr_agg.sr_store_sk
     AND e.closed_date_sk = sr_agg.sr_returned_date_sk
    LEFT JOIN web_sales_agg ws_agg
      ON e.ws_warehouse_sk = ws_agg.ws_warehouse_sk
     AND e.sold_date_sk = ws_agg.ws_sold_date_sk
    WHERE e.loc_part IS NOT NULL
      AND e.closed_year = 2002
      AND (e.sold_year = 2002 OR e.sold_year IS NULL)
  )
SELECT
  f.s_store_sk,
  f.s_store_name,
  f.ws_warehouse_sk,
  f.ws_order_number,
  f.closed_year,
  f.sold_year,
  f.total_return_amt,
  f.total_sales,
  f.loc_part,
  f.rn
FROM final f
WHERE f.s_store_sk IN (SELECT sr_store_sk FROM intersect_stores)
ORDER BY f.rn
LIMIT 100
