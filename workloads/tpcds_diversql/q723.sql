WITH
  -- Base chain joining all 13 tables (left‑deep path)
  base AS (
    SELECT
      d.d_date,
      i.i_item_sk,
      i.i_item_id,
      i.i_item_desc,
      cs.cs_ext_sales_price            AS catalog_sales,
      ss.ss_ext_sales_price            AS store_sales,
      ws.ws_ext_sales_price            AS web_sales,
      sr.sr_return_amt                 AS return_amt,
      w.w_warehouse_name,
      sm.sm_type                        AS ship_type,
      c.c_customer_sk,
      ca.ca_state,
      cd.cd_gender,
      cs.cs_quantity,
      ss.ss_quantity,
      ws.ws_quantity,
      sr.sr_return_quantity
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_sales cs          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.inventory inv             ON inv.inv_warehouse_sk = w.w_warehouse_sk
                                           AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.item i                    ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss           ON ss.ss_item_sk = i.i_item_sk
                                           AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s                  ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.store_returns sr         ON sr.sr_ticket_number = ss.ss_ticket_number
                                           AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c               ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.web_sales ws        ON ws.ws_sold_date_sk = d.d_date_sk
                                           AND ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'barcallyable'
      AND ca.ca_state IN ('CA', 'TX')
      AND cd.cd_gender = 'M'
      AND w.w_warehouse_id LIKE 'AAAAAAA%'
  ),

  -- UNION of two sales perspectives (catalog+store vs web only)
  sales_union AS (
    SELECT d_date, i_item_id, i_item_desc,
           catalog_sales + store_sales + COALESCE(web_sales, 0) AS total_sales,
           'catalog_store' AS src
    FROM base
    UNION DISTINCT
    SELECT d_date, i_item_id, i_item_desc,
           web_sales AS total_sales,
           'web' AS src
    FROM base
    WHERE web_sales IS NOT NULL
  ),

  -- INTERSECT to keep only items sold both in catalog/store and web channels
  common_items AS (
    SELECT i_item_id FROM base WHERE catalog_sales > 0
    INTERSECT
    SELECT i_item_id FROM base WHERE web_sales > 0
  ),

  -- FULL OUTER JOIN between returns and web sales to keep unmatched rows from both sides
  returns_web_full AS (
    SELECT
      sr.sr_returned_date_sk          AS return_date_sk,
      ws.ws_sold_date_sk              AS web_date_sk,
      sr.sr_item_sk                    AS item_sk,
      sr.sr_return_amt                 AS return_amt,
      ws.ws_ext_sales_price            AS web_sales_amt
    FROM tpcds.store_returns sr
    FULL OUTER JOIN tpcds.web_sales ws
      ON sr.sr_item_sk = ws.ws_item_sk
     AND sr.sr_returned_date_sk = ws.ws_sold_date_sk
  ),

  -- LATERAL sub‑query: 7‑day rolling sum of catalog sales per item
  rolling_sales AS (
    SELECT
      b.d_date,
      b.i_item_id,
      b.catalog_sales,
      rs.week_sales
    FROM base b
    CROSS JOIN LATERAL (
      SELECT SUM(cs2.cs_ext_sales_price) AS week_sales
      FROM tpcds.catalog_sales cs2
      JOIN tpcds.date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE cs2.cs_item_sk = b.i_item_sk
        AND d2.d_date BETWEEN b.d_date - INTERVAL '6' DAY AND b.d_date
    ) rs
  ),

  -- Final aggregation with window functions and CASE logic
  final AS (
    SELECT
      su.d_date,
      su.i_item_id,
      i.i_item_desc,
      su.total_sales,
      RANK() OVER (PARTITION BY su.d_date ORDER BY su.total_sales DESC)          AS sales_rank,
      AVG(su.total_sales) OVER (PARTITION BY su.d_date ORDER BY su.total_sales
                               ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)   AS moving_avg_sales,
      CASE
        WHEN su.total_sales > 10000 THEN 'High'
        WHEN su.total_sales > 5000  THEN 'Medium'
        ELSE 'Low'
      END                                                                        AS sales_category,
      COALESCE(rwf.return_amt, 0)                                                AS return_amount,
      rs.week_sales
    FROM sales_union su
    JOIN tpcds.item i ON i.i_item_id = su.i_item_id
    LEFT JOIN returns_web_full rwf ON rwf.item_sk = i.i_item_sk
    LEFT JOIN rolling_sales rs ON rs.i_item_id = su.i_item_id AND rs.d_date = su.d_date
    JOIN common_items ci ON ci.i_item_id = su.i_item_id
  )
SELECT *
FROM final
ORDER BY d_date DESC, sales_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
