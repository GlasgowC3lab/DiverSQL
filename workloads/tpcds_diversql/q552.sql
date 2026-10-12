WITH
  -- Base join of all ten tables following a left‑deep chain
  base AS (
    SELECT
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      d.d_year,
      cd.cd_gender,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cc.cc_gmt_offset,
      wp.wp_image_count,
      ws.web_site_id,
      cr.cr_return_amount,
      wr.wr_return_amt,
      -- classification of quantity
      CASE WHEN ss.ss_quantity >= 5 THEN 'High' ELSE 'Low' END AS quantity_category,
      -- rank of net paid within each year
      RANK() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_paid DESC) AS rank_by_year
    FROM store_sales ss
    JOIN date_dim d                 ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd   ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd   ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib             ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr         ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
                                   AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc             ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_page wp                ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws                ON ws.web_open_date_sk = d.d_date_sk
    JOIN web_returns wr            ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 2
      AND cc.cc_gmt_offset = -6.00
      AND wp.wp_image_count BETWEEN 2 AND 5
      AND ib.ib_lower_bound >= 20000
  ),
  -- Union of High and Low quantity categories (distinct)
  high_low_union AS (
    SELECT ss_ticket_number, ss_net_paid, quantity_category, rank_by_year,
           wp_image_count, cr_return_amount, wr_return_amt, ss_quantity
    FROM base
    WHERE quantity_category = 'High'
    UNION DISTINCT
    SELECT ss_ticket_number, ss_net_paid, quantity_category, rank_by_year,
           wp_image_count, cr_return_amount, wr_return_amt, ss_quantity
    FROM base
    WHERE quantity_category = 'Low'
  ),
  -- Intersection of two key sets
  intersect_set AS (
    SELECT ss_ticket_number FROM base WHERE ss_quantity > 3
    INTERSECT
    SELECT ss_ticket_number FROM base WHERE ss_quantity < 10
  ),
  -- Subtract a third key set
  except_set AS (
    SELECT ss_ticket_number FROM intersect_set
    EXCEPT
    SELECT ss_ticket_number FROM base WHERE wp_image_count = 3
  ),
  -- Expand an array derived from quantity and compute a running total
  expanded AS (
    SELECT
      h.*,
      q AS expanded_quantity,
      SUM(q) OVER (PARTITION BY h.ss_ticket_number ORDER BY q
                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_quantity
    FROM high_low_union h
    CROSS JOIN UNNEST(ARRAY[h.ss_quantity, h.ss_quantity + 10]) AS t(q)
  )
SELECT
  e.ss_ticket_number,
  e.ss_net_paid,
  e.quantity_category,
  e.rank_by_year,
  e.wp_image_count,
  e.cr_return_amount,
  e.wr_return_amt,
  e.expanded_quantity,
  e.cum_quantity
FROM expanded e
WHERE e.ss_ticket_number IN (SELECT ss_ticket_number FROM except_set)
ORDER BY e.rank_by_year DESC, e.ss_ticket_number
LIMIT 100
